//
//  VoiceProvider.swift
//
//
//  Created by Daniel Rees on 6/4/24.
//

import Foundation


public class VoiceProvider {
    
    private let humeClient: HumeClient
    private var socket: StreamSocket?
    private let soundPlayer: SoundPlayer
    private let microphone: Microphone
    
    public var onMessage: (SubscribeEvent) -> Void = { _ in }
    
    
    public init(apiKey: String, clientSecret: String) {
        self.humeClient = HumeClient(
            apiKey: apiKey,
            clientSecret: clientSecret
        )
        
        self.soundPlayer = SoundPlayer(
            onError: { error in
                print("error: \(error)")
            }, onPlayAudio: { id in
                print("Playing message id: \(id)")
            })

        self.microphone = Microphone()
        

        self.microphone.onAudioCaptured = { data in
            Task {
                do {
                    let base64AudioString = data.base64EncodedString()
                    let audioInput = AudioInput(data: base64AudioString)
                    try await self.socket?.sendAudioInput(message: audioInput)
                } catch {
                    print("Error sending message", error)
                }
            }
            
        }
    }
    
    
    public func connect() async throws {
        let socket = try await self.humeClient.empatheticVoice.chat
            .connect(
                onOpen: { response in
                    print("Socket Opened")
                },
                onClose: { closeCode, reason in
                    print("Socket Closed: \(closeCode). Reason: \(String(describing: reason))")
                },
                onError: { error, response in
                    print("Socket Errored: \(error). Response: \(String(describing: response))")
                }
            )
        
        self.socket = socket
        
        try microphone.start()
        
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
