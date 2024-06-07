import Foundation
import AVFoundation

public class VoiceProvider {
    
    
    private let humeClient: HumeClient
    private var socket: StreamSocket?
    private let soundPlayer: SoundPlayer
    private let microphone: Microphone
    private let serialQueue = DispatchSerialQueue(label: "com.hume.microphoneQueue")
    private var audioFileURL: URL?
    private var audioFile: AVAudioFile?
    
    public var onMessage: (SubscribeEvent) -> Void = { _ in }
    
    /// Controls if we override the AVAudioSession output port during playback or not
    public var outputToSpeakers: Bool = true
    
    
    public init(apiKey: String, clientSecret: String) {
        self.humeClient = HumeClient(
            apiKey: apiKey,
            clientSecret: clientSecret
        )
        
        self.soundPlayer = SoundPlayer(
           onError: { error in
               print("error: \(error)")
           })
        
        /// Need session settings with audio configuration to send headerless PCM over the socket. Session settings message must be received before any audio is sent.
        let audioConfiguration = AudioConfiguration(channels: 1, encoding: Encoding.linear16, sampleRate: 44100)
        let sessionSettings = SessionSettings(customSessionId: nil, audio: audioConfiguration, languageModelApiKey: nil, systemPrompt: nil, tools: nil)
        
        self.microphone = Microphone(sampleRate: 44100, samplingSize: 1024)
        
        
        self.microphone.onChunk = { [weak self] data, chunkId in
            guard let self = self else { return }
            self.serialQueue.async {
                Task {
                    do {
                        if (chunkId == 0) {
                            try await self.socket?.sendSessionSettings(message: sessionSettings)
                        }
                        
                        try await self.socket?.sendData(message: data)
                    } catch {
                       print("socket error")
                    }
                }
            }
        }
        
        self.microphone.onError = { error in print("mic error: \(error)") }
        
        self.soundPlayer.onPlayAudio = { [weak self] id in
            guard let self = self else { return }
            print("Playing message id: \(id)")
            if (self.outputToSpeakers) {
                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.overrideOutputAudioPort(.none)
                    try audioSession.overrideOutputAudioPort(.speaker)
                    
                } catch {
                    print("Failed audio session port override!")
                }
            }
        }
        
        configureAudioSession()
    }
    
    
    func configureAudioSession() {
        print("Audio session configuration...")

        let audioSession = AVAudioSession.sharedInstance()
        let categories = audioSession.availableCategories

        let category: AVAudioSession.Category
        if categories.contains(.playAndRecord) {
            category = .playAndRecord
        } else {
            print("Error: Incompatible audio session. Play-and-Record is not supported")
            return
        }

        var options: AVAudioSession.CategoryOptions = [
            .allowBluetooth,
            .allowBluetoothA2DP,
            .defaultToSpeaker,
            .overrideMutedMicrophoneInterruption
        ]

        do {
            try audioSession.setCategory(category, options: options)
        } catch {
            print("Error setting category: \(error.localizedDescription)")
            return
        }

        do {
            try audioSession.setActive(true)
        } catch {
            print("Error setting audio session active: \(error.localizedDescription)")
        }
    }

    public func connect() async throws {
        let socket = try await self.humeClient.empatheticVoice.chat
            .connect(
                onOpen: { response in
                    print("Socket Opened")
                    self.microphone.start()
                },
                onClose: { closeCode, reason in
                    print("Socket Closed: \(closeCode). Reason: \(String(describing: reason))")
                },
                onError: { error, response in
                    print("Socket Errored: \(error). Response: \(String(describing: response))")
                }
            )
        
        self.socket = socket
        
        do {
            // Consuming IncomingMessages
            print("waiting for incoming messages")
            for try await event in socket.receive() {
                switch event {
                case .audioOutput(let audioOutput):
                    soundPlayer.addToQueue(message: audioOutput)
                case .userInterruption:
                    soundPlayer.clearQueue()
                default:
                    DispatchQueue.main.async {
                        self.onMessage(event)
                    }
                    
                }
            }
        } catch {
            print("Error receiving messages:", error)
        }
    }
    
    public func disconnect() {
        socket?.close()
        microphone.stop()
        soundPlayer.stopAll()
    }
    
    public func sendUserInput(message: String) async {
        do {
            try await socket?.sendTextInput(text: message)
        } catch {
            print("Error sending message", error)
        }
    }
    
    public func sendAssistantInput(message: String) async {
        do {
            try await socket?.sendAssistantInput(message: AssistantInput(text: message))
        } catch {
            print("Error sending message", error)
        }
    }
    
    public func sendSessionSettings(message: SessionSettings) async {
        do {
            try await socket?.sendSessionSettings(message: message)
        } catch {
            print("Error sending message", error)
        }
    }
    
    public func sendPauseAssistantMessage(message: PauseAssistantMessage) async {
        do {
            try await socket?.pauseAssistant(message: message)
        } catch {
            print("Error sending message", error)
        }
    }
    
    public func sendResumeAssistantMessage(message: ResumeAssistantMessage) async {
        do {
            try await socket?.resumeAssistant(message: message)
        } catch {
            print("Error sending message", error)
        }
    }
}
