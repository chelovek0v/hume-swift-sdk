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
        
        var category: AVAudioSession.Category {
            switch self {
            case .voiceChat:
                return .playAndRecord
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
            }
        }
    }
}
