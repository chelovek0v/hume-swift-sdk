//
//  AudioSessionConfiguration.swift
//  HumeAI2
//
//  Created by Chris on 4/4/25.
//

import Foundation
import AVFoundation

extension AudioSession {
    enum Configuration {
        case voiceChat
        case soundPreview
        
        var category: AVAudioSession.Category {
            switch self {
            case .voiceChat:
                return .playAndRecord
            case .soundPreview:
                return .playback
            }
        }
        
        var options: AVAudioSession.CategoryOptions {
            let opts: AVAudioSession.CategoryOptions = [
                .allowBluetooth,
                .allowBluetoothA2DP,
                .allowAirPlay,
                .defaultToSpeaker,
                .overrideMutedMicrophoneInterruption
            ]
        
            return opts
        }
        
        var mode: AVAudioSession.Mode {
            switch self {
            case .voiceChat: .videoChat
            case .soundPreview: .moviePlayback
            }
        }
    }
}
