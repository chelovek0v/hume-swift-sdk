//
//  AudioHub.swift
//  HumeAI2
//
//  Created by Chris on 12/17/24.
//

import AVFAudio
import AVFoundation
import Combine

public enum AudioHubError: Error {
  case audioSessionConfigError
  case soundPlayerDecodingError
  case soundPlayerInitializationError
  case headerMissing
  case notRunning
  case outputFormatError
}

public protocol AudioHub {
  var outputMeterListener: ((Float) -> Void)? { get set }
  var isOutputMeteringEnabled: Bool { get set }

  /// Gets the current `MicrophoneMode`. The value of `preferredMode` can be used to determine if `.voiceIsolation` is active.
  /// To update the microphone mode, `AVCaptureDevice.showSystemUserInterface(.microphoneModes)` will present the system UI to the user to update. (This requires importing `AVFoundation`).
  var microphoneMode: MicrophoneMode { get }
  var microphoneDataChunkHandler: MicrophoneDataChunkBlock? { get set }

  var state: AnyPublisher<AudioHubState, Never> { get }
  var stateSubject: CurrentValueSubject<AudioHubState, Never> { get }

  func configure(with config: AudioHubConfiguration) async throws

  func enqueue(soundClip: SoundClip) async throws

  func start() async throws
  func stop() async throws

  func handleInterruption()
  func muteMic(_ mute: Bool)
}

public protocol AudioHubDelegate {
  func audioHub(_ audioHub: AudioHub, did soundClip: SoundClip)
}

public class AudioHubImpl: AudioHub {
  // MARK: Audio gear
  internal let audioEngine = AVAudioEngine()
  private let audioSession = AudioSession.shared
  private var soundPlayer: SoundPlayer?
  private var microphone: Microphone!
  private var inputNode: AVAudioInputNode!
  internal var mainMixer: AVAudioMixerNode!
  private var outputNode: AVAudioOutputNode!

  public var microphoneMode: MicrophoneMode {
    return MicrophoneMode(
      preferredMode: AVCaptureDevice.preferredMicrophoneMode,
      activeMode: AVCaptureDevice.activeMicrophoneMode)
  }

  public var isOutputMeteringEnabled: Bool = false {
    didSet {
      if let soundPlayer {
        soundPlayer.meteringNode.isMetering = isOutputMeteringEnabled
      }
    }
  }
  public var outputMeterListener: ((Float) -> Void)? {
    didSet {
      if let soundPlayer {
        soundPlayer.meteringNode.meterListener = outputMeterListener
      }
      if outputMeterListener == nil && isOutputMeteringEnabled {
        // disable metering to save resources if there's no listener
        isOutputMeteringEnabled = false
      }
    }
  }

  // MARK: State
  @MainActor
  public var state: AnyPublisher<AudioHubState, Never> {
    stateSubject.eraseToAnyPublisher()
  }

  @MainActor
  public var stateSubject = CurrentValueSubject<AudioHubState, Never>(.unconfigured)

  // MARK: Queues
  private let microphoneQueue = DispatchQueue(label: "\(Constants.Namespace).microphone.queue")

  private let configLock = NSLock()

  // MARK: Handlers
  public var microphoneDataChunkHandler: MicrophoneDataChunkBlock?

  private var activeConfig: AudioHubConfiguration?

  /// - parameters:
  /// - microphoneHandler: Callback when microphone data is received. This block is executed on a serial queue to guarantee the sequence of samples
  ///
  /// - throws: `AudioSessionError`, `MicrophoneError`
  public init() {
    Logger.info("initializing AudioHub")
    audioSession.delegate = self
  }

  public func configure(with config: AudioHubConfiguration) async throws {
    Logger.info("configuring audio hub ")
    guard await stateSubject.value == .unconfigured || activeConfig != config else {
      Logger.warn("audio hub already configured for \(config)")
      return
    }
    activeConfig = config
    await stateSubject.send(.configuring)
    Logger.info("AudioHub state: configuring")

    do {
      try audioSession.configure(with: config)
      try audioSession.start()

      Logger.debug("Creating audio nodes")
      mainMixer = audioEngine.mainMixerNode
      outputNode = audioEngine.outputNode

      if config.requiresMicrophone {
        Logger.debug("Initializing microphone")
        inputNode = audioEngine.inputNode
        self.microphone = try Microphone(
          audioEngine: audioEngine,
          sampleRate: Constants.SampleRate,
          sampleSize: Constants.SampleSize,
          audioFormat: Constants.DefaultAudioFormat)

        self.microphone.onChunk = handleMicrophoneDataChunk
        connectAudioEngineInputs()
      }
    } catch {
      await stateSubject.send(.unconfigured)
      Logger.info("AudioHub state: unconfigured")
      throw error
    }

      await stateSubject.send(.stopped)
    Logger.info("AudioHub state: stopped")
  }

  public func enqueue(soundClip: SoundClip) async throws {
    guard await stateSubject.value == .running else {
      Logger.warn("skipping enqueue because audio hub is not running")
      throw AudioHubError.notRunning
    }

    Logger.info(
      "Adding message to SoundPlayer: \(soundClip.id) (\(String(describing: soundClip.index))")
    if let header = soundClip.header {
      if (soundPlayer != nil
        && UInt32(soundPlayer?.inputFormat.sampleRate ?? 0) != header.sampleRate)
        || soundPlayer == nil
      {
        initializeSoundPlayer(with: header)
      }
    } else if soundPlayer == nil {
      Logger.warn("SoundClip missing header, no soundplayer")
    }

    guard let soundPlayer else {
      throw AudioHubError.soundPlayerInitializationError
    }
    soundPlayer.enqueueAudio(soundClip: soundClip)
  }

  public func handleInterruption() {
    guard let soundPlayer else {
      Logger.warn("no sound player to clear queue")
      return
    }
    soundPlayer.clearQueue()
  }

  public func start() async throws {
    let currentState = await stateSubject.value
    guard [.stopped, .stopping].contains(currentState) else {
      Logger.warn("attempted to start audio hub from a \(currentState) state")
      return
    }
    await stateSubject.send(.starting)
    Logger.info("AudioHub state: starting")
    Logger.info("Starting AudioHub")
    do {
      try audioSession.start()
      Logger.info("Starting audio engine")
      try audioEngine.start()
      await stateSubject.send(.running)
      Logger.info("AudioHub state: running")
    } catch {
      Logger.error("Failed to start audio engine: \(error)")
      await stateSubject.send(.stopped)
      Logger.info("AudioHub state: stopped")
      throw error
    }
  }

  public func stop() async throws {
    Logger.info("Stopping AudioHub")
    let state = await stateSubject.value
      
      switch state {
          case .starting:
              Logger.warn("audio hub was starting, waiting to finish")
              try await stateSubject.waitFor(.running)
          case .stopped, .stopping, .unconfigured, .configuring:
              Logger.warn("attempted to stop audio hub from \(state) state")
              return
          case .running:
              break
      }
      
    await stateSubject.send(.stopping)
    Logger.info("AudioHub state: stopping")

    microphoneDataChunkHandler = nil
    soundPlayer?.clearQueue()
    soundPlayer = nil

    if audioEngine.isRunning {
      Logger.debug("Stopping audio engine")
      audioEngine.stop()
    }
      
      try? audioSession.stop()
      disconnectAudioGraph()
      
      microphone = nil
      inputNode = nil
      
      // Reset configuration
      activeConfig = nil

    await stateSubject.send(.stopped)
    Logger.info("AudioHub state: stopped")
  }

  public func muteMic(_ mute: Bool) {
    if mute {
      microphone.mute()
    } else {
      microphone.unmute()
    }
  }

  // MARK: - Helpers
  private func initializeSoundPlayer(with header: WAVHeader) {
    Logger.info("Initializing sound player with header: \(header)")
    guard configLock.try() else {
      Logger.debug("initialization already in progress, skipping")
      return
    }
    defer { configLock.unlock() }

    guard
      let inputFormat = AVAudioFormat(
        commonFormat: Constants.DefaultAudioFormat.commonFormat,
        sampleRate: Double(header.sampleRate),
        channels: AVAudioChannelCount(header.numChannels),
        interleaved: header.numChannels > 1)
    else {
      Logger.error("Failed to create input format for sound player")
      return
    }
    soundPlayer = SoundPlayer(
      inputFormat: inputFormat, outputFormat: outputNode.outputFormat(forBus: 0))
    soundPlayer?.meteringNode.isMetering = isOutputMeteringEnabled
    soundPlayer?.meteringNode.meterListener = outputMeterListener

    guard soundPlayer != nil else {
      Logger.error("Sound player is not initialized")
      return
    }
    connectAudioEngineOutputs(outputFormat: outputNode.outputFormat(forBus: 0))
  }

  // MARK: - Connections
  private func disconnectAudioGraph() {
    Logger.info("Disconnecting audio graph")
    if let inputNode {
      audioEngine.disconnectNodeOutput(inputNode)
    } else {
      Logger.warn("missing input node while disconnecting audio graph")
    }

    if let soundPlayer {
      audioEngine.disconnectNodeOutput(soundPlayer.audioNode)
    } else {
      Logger.warn("missing output node while disconnecting audio graph")
    }
  }

  private func connectAudioEngineInputs() {
    Logger.debug("Connecting input chain")
    audioEngine.attach(microphone.sinkNode)
    audioEngine.connect(inputNode, to: microphone.sinkNode, format: nil)
  }

  private func connectAudioEngineOutputs(outputFormat: AVAudioFormat?) {
    guard let soundPlayer else {
      Logger.error("Sound player is not initialized")
      return
    }
    audioEngine.attach(soundPlayer.audioNode)
    let formatToUse: AVAudioFormat? = {
      guard let fmt = outputFormat, fmt.channelCount > 0 else {
        return nil
      }
      return fmt
    }()
    audioEngine.connect(soundPlayer.audioNode, to: mainMixer, format: formatToUse)
  }

  // MARK: - Handlers

  private func handleMicrophoneDataChunk(data: Data, averagePower: Float) {
    self.microphoneQueue.async { [weak self] in
      Task {
        // TODO: make averagePower configurable, currently omitting this data
        guard let self else {
          assertionFailure("lost AudioHub self")
          return
        }
        if self.microphoneDataChunkHandler == nil {
          Logger.warn("no mic data chunk handler set ")
        }
        await self.microphoneDataChunkHandler?(data, averagePower)
      }
    }
  }
}

// MARK: - Audio Session Delegate

extension AudioHubImpl: AudioSessionDelegate {
  func audioEngineDidChangeConfiguration() {
    Logger.info("AudioHubImpl responding to audio engine configuration change")
    microphoneQueue.async { [weak self] in
      Task {
        guard let self else {
          assertionFailure("AudioHub is missing self")
          return
        }
        try? await self.reconfigure()
      }
    }
  }

  private func reconfigure() async throws {
    guard await stateSubject.value != .configuring, soundPlayer != nil else {
      Logger.warn("attempted to reconfigure while audio hub is configuring")
      return
    }

    Logger.debug("Reconfiguring audio hub")
    audioEngine.stop()

    disconnectAudioGraph()
    if activeConfig?.requiresMicrophone == true {
      connectAudioEngineInputs()
    }
    connectAudioEngineOutputs(outputFormat: outputNode.outputFormat(forBus: 0))

    if await stateSubject.value == .running {
      // only start back up if we're running
      try? audioEngine.start()
    }
  }
}
