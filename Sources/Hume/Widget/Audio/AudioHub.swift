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
    case outputFormatError
}

public protocol AudioHub {
    var outputMeterListener: ((Float) -> Void)? { get set }
    var isOutputMeteringEnabled: Bool { get set }
    
    var microphoneMode: MicrophoneMode { get }
    var microphoneDataChunkHandler: MicrophoneDataChunkBlock? { get set }
    
    var state: AnyPublisher<AudioHubState, Never> { get }
    var stateSubject: CurrentValueSubject<AudioHubState, Never> { get }

    func configure(eviVersion: EviVersion) async throws
    func setEviVersion(_ eviVersion: EviVersion) async
    
    func enqueue(soundClip: SoundClip)
    
    func start() async throws
    func stop() async throws

    func handleInterruption()
    func muteMic(_ mute: Bool)
}

public enum AudioHubState {
    case unconfigured
    case configuring
    case stopped
    case starting
    case running
    case stopping
}

public protocol AudioHubDelegate {
    func audioHub(_ audioHub: AudioHub, did soundClip: SoundClip)
}

fileprivate class EviSoundPlayer {
    var soundPlayer: SoundPlayer {
        switch eviVersion {
        case .v2: _v2Player
        case .v3: _v3Player
        case .none:
            fatalError("Unsupported EviVersion")
        }
    }
    
    var eviVersion: EviVersion!
    
    private let _v2Player: SoundPlayer
    private let _v3Player: SoundPlayer
    
    init(outputFormat: AVAudioFormat) {
        Logger.info("Initializing EviSoundPlayer")
        self._v2Player = SoundPlayer(inputFormat: Constants.DefaultAudioOutputFormatEvi2, outputFormat: outputFormat)
        self._v3Player = SoundPlayer(inputFormat: Constants.DefaultAudioOutputFormatEvi3, outputFormat: outputFormat)
    }
}

public class AudioHubImpl: AudioHub {
    // MARK: Audio gear
    private let audioEngine = AVAudioEngine()
    private let audioSession = AudioSession.shared
    private var eviSoundPlayer: EviSoundPlayer! {
        didSet {
            if let eviSoundPlayer {
                eviSoundPlayer.eviVersion = eviVersion
            }
        }
    }
    private var microphone: Microphone!
    private var inputNode: AVAudioInputNode!
    private var mainMixer: AVAudioMixerNode!
    private var outputNode: AVAudioOutputNode!
    private var eviVersion: EviVersion! {
        didSet {
            if let eviSoundPlayer {
                eviSoundPlayer.eviVersion = eviVersion
            }
        }
    }
    
    public var microphoneMode: MicrophoneMode {
        return MicrophoneMode(
            preferredMode: AVCaptureDevice.preferredMicrophoneMode,
            activeMode: AVCaptureDevice.activeMicrophoneMode)
    }

    // MARK: Metering
    // FIXME: hacky solution to a crash when trying to set this when granting mic permissions. hacked because we're releasing beta, lets clean up the state management for this and incoroporate mic permsission handling in the SDK before public release of SDK.
    private var _pendingOutputMeterEnabled: Bool?
    public var isOutputMeteringEnabled: Bool = false {
        didSet {
            if eviSoundPlayer != nil {
                eviSoundPlayer.soundPlayer.meteringNode.isMetering = isOutputMeteringEnabled
                _pendingOutputMeterEnabled = nil
            } else {
                _pendingOutputMeterEnabled = isOutputMeteringEnabled
            }
        }
    }
    public var outputMeterListener: ((Float) -> Void)? {
        didSet {
            eviSoundPlayer.soundPlayer.meteringNode.meterListener = outputMeterListener
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
    private let microphoneQueue = DispatchQueue(label: "com.humeai-sdk.microphone.queue")
    
    // MARK: Handlers
    public var microphoneDataChunkHandler: MicrophoneDataChunkBlock?
    
    /// - parameters:
    /// - microphoneHandler: Callback when microphone data is received. This block is executed on a serial queue to guarantee the sequence of samples
    ///
    /// - throws: `AudioSessionError`, `MicrophoneError`
    init() {
        Logger.info("initializing AudioHub")
        audioSession.delegate = self
    }
    
    public func setEviVersion(_ eviVersion: EviVersion) async {
        Logger.info("Updating evi version for soundplayer")
        guard self.eviVersion != eviVersion else {
            Logger.debug("evi version already set: \(eviVersion.rawValue)")
            return
        }
        
        let state = await stateSubject.value
        Logger.info("swapping the soundplayer version")
        let alreadyConfigured = state != .unconfigured || state != .configuring
        
        if alreadyConfigured {
            disconnectAudioGraph()
        }
        
        // passes through to set evi version on sound player
        self.eviVersion = eviVersion
        
        if alreadyConfigured {
            configureAudioGraph()
        }
    }
    
    public func configure(eviVersion: EviVersion) async throws {
        Logger.info("configuring audio hub ")
        guard case .unconfigured = await stateSubject.value else {
            Logger.warn("audio hub already configured")
            return
        }
        await stateSubject.send(.configuring)
        
        do {
            try audioSession.configure()
            try audioSession.start(for: .voiceChat)
            
            Logger.debug("Creating audio nodes")
            inputNode = audioEngine.inputNode
            mainMixer = audioEngine.mainMixerNode
            outputNode = audioEngine.outputNode
            
            Logger.debug("Initializing microphone")
            self.microphone = try Microphone(audioEngine: audioEngine,
                                             sampleRate: Constants.SampleRate,
                                             sampleSize: Constants.SampleSize,
                                             audioFormat: Constants.DefaultAudioFormat)
            
            
            let outputFormat = outputNode.outputFormat(forBus: 0)
            Logger.debug("Initializing soundplayer with outputFormat: \(outputFormat)")
            self.eviVersion = eviVersion
            self.eviSoundPlayer = EviSoundPlayer(outputFormat: outputFormat)
            if let _pendingOutputMeterEnabled {
                isOutputMeteringEnabled = _pendingOutputMeterEnabled
            }
            
            self.microphone.onChunk = handleMicrophoneDataChunk
            
            configureAudioGraph()
        } catch {
            await stateSubject.send(.unconfigured)
            throw error
        }
        
        await stateSubject.send(.stopped)
    }

    public func enqueue(soundClip: SoundClip) {
        Logger.info("Adding message to SoundPlayer: \(soundClip.id) (\(soundClip.index)")
        eviSoundPlayer.soundPlayer.enqueueAudio(soundClip: soundClip)
    }
    
    public func handleInterruption() {
        eviSoundPlayer.soundPlayer.clearQueue()
    }
    
    public func start() async throws {
        guard [.stopped, .stopping].contains(await stateSubject.value) else {
            assertionFailure("expected audio hub to be stopped before starting")
            return
        }
        await stateSubject.send(.starting)
        Logger.info("Starting AudioHub")
        try audioSession.start(for: .voiceChat)
        try audioEngine.start()
        await stateSubject.send(.running)
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

        microphoneDataChunkHandler = nil
        eviSoundPlayer.soundPlayer.clearQueue()
        if audioEngine.isRunning {
            Logger.debug("Stopping audio engine")
            audioEngine.stop()
        }
        try audioSession.stop(configuration: .voiceChat)
        await stateSubject.send(.stopped)
    }
    
    public func muteMic(_ mute: Bool) {
        if mute {
            microphone.mute()
        } else {
            microphone.unmute()
        }
    }
    
    // MARK: - Connections
    private func configureAudioGraph() {
        Logger.info("Connecting audio graph together")
        let inputFormat = microphone.inputFormat
        let outputFormat = outputNode.outputFormat(forBus: 0)
        
        // attach
        audioEngine.attach(microphone.sinkNode)
        audioEngine.attach(eviSoundPlayer.soundPlayer.audioNode)
        
        connectAudioGraph(inputFormat, outputFormat)

        Logger.info(audioEngine.prettyPrinted)
    }
    
    private func disconnectAudioGraph() {
        Logger.info("Disconnecting audio graph")
        if let inputNode {
            audioEngine.disconnectNodeOutput(inputNode)
        } else {
            Logger.warn("missing input node while disconnecting audio graph")
        }
        
        if let soundPlayer = eviSoundPlayer {
            audioEngine.disconnectNodeOutput(soundPlayer.soundPlayer.audioNode)
        } else {
            Logger.warn("missing evi sound player while disconnecting audio graph")
        }
    }
    
    private func connectAudioGraph(_ inputFormat: AVAudioFormat?, _ outputFormat: AVAudioFormat?) {
        let actualOutputFormat = outputFormat

        let inputChain: [(AVAudioNode, AVAudioNode)] = [
            (inputNode, microphone.sinkNode)]
        
        let outputChain: [(AVAudioNode, AVAudioNode)] = [
            (eviSoundPlayer.soundPlayer.audioNode, mainMixer)]
        
        Logger.debug("Connecting input chain")
        inputChain.forEach {
            audioEngine.connect($0.0, to: $0.1, format: nil)
        }
        
        Logger.debug("Connecting output chain")
        outputChain.forEach {
            audioEngine.connect($0.0, to: $0.1, format: actualOutputFormat)
        }
    }
    
    // MARK: - Handlers
    
    private func handleMicrophoneDataChunk(data: Data, averagePower: Float)  {
        self.microphoneQueue.async { [weak self] in
            Task {
                // TODO: make averagePower configurable, currently omitting this data
                guard let self else { assertionFailure("lost AudioHub self"); return }
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
                guard let self else { assertionFailure("AudioHub is missing self"); return }
                Logger.info("Reconfiguring audio gear")
                try? await self.reconfigure()
            }
        }
    }
    
    private func reconfigure() async throws {
        guard await stateSubject.value != .configuring else {
            Logger.warn("attempted to reconfigure while audio hub is configuring")
            return
        }
        
        Logger.debug("Reconfiguring audio hub")
        audioEngine.stop()
        
        disconnectAudioGraph()
        connectAudioGraph(microphone.inputFormat, outputNode.outputFormat(forBus: 0))
        
        if await stateSubject.value == .running {
            // only start back up if we're running
            try? audioEngine.start()
        }
    }
}
