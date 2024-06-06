//
//  SoundPlayer.swift
//

import Foundation
import AVFoundation

private struct Clip {
    let id: String
    let data: Data
}


public class SoundPlayer: NSObject, AVAudioPlayerDelegate {
    
    private let onError: (String) -> Void
    private let onPlayAudio: (String) -> Void
    
    private var audioPlayer: AVAudioPlayer?
    private var clipQueue: [Clip] = []
    private var isProcessing: Bool = false
    
    public init(onError: @escaping (String) -> Void,
                onPlayAudio: @escaping (String) -> Void) {
        self.onError = onError
        self.onPlayAudio = onPlayAudio
    }
    
    
    /// Returns `true` if the player is actively playing audio
    public var isPlaying: Bool {
        audioPlayer?.isPlaying == true
    }
    
    /// Adds a `message` to the queue to be played immediately once any previous
    /// messages on the queue have completed playing
    public func addToQueue(message: AudioOutput) {
        guard let audioData = message.base64ToData else {
            onError("Failed to add clip to queue. Could not decode base64 audio.")
            return
        }
        
        let clip = Clip(id: message.id, data: audioData)
        self.clipQueue.append(clip)
        
        
        if self.clipQueue.count == 1 {
            self.playNextClip()
        }
    }
    
    private func playNextClip() {
        if self.clipQueue.isEmpty || self.isProcessing { return }
        let nextClip = self.clipQueue.removeFirst()
        
        self.isProcessing = true
        
        do {
            self.audioPlayer = try AVAudioPlayer(data: nextClip.data)
            self.audioPlayer?.delegate = self
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.play()
            
            onPlayAudio(nextClip.id)
        } catch let error {
            onError("Error playing audio clip. \(error.localizedDescription)")
        }
    }
    
    ///
    public func clearQueue() {
        self.audioPlayer?.stop()
        self.audioPlayer = nil
        
        self.clipQueue.removeAll()
        isProcessing = false
    }
    
    public func stopAll() {
        isProcessing = false
        
        self.audioPlayer?.stop()
        self.audioPlayer = nil
        
        // TODO: Add frequency analyzer and stop it here as well
        
        self.clipQueue.removeAll()
    }
    
    
    // MARK: - AVAudioPlayerDelegate -
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.audioPlayer = nil
        self.isProcessing = false
        playNextClip()
    }
}

