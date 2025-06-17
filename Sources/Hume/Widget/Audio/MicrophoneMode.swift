//
//  MicrophoneMode.swift
//  HumeAI2
//
//  Created by Chris on 1/28/25.
//

import AVFoundation

public struct MicrophoneMode {
    let preferredMode: AVCaptureDevice.MicrophoneMode
    let activeMode: AVCaptureDevice.MicrophoneMode
}

extension AVCaptureDevice.MicrophoneMode {
    public var title: String {
        switch self {
        case .standard:
            return "Standard"
        case .wideSpectrum:
            return "Wide Spectrum"
        case .voiceIsolation:
            return "Voice Isolation"
        @unknown default:
            return "Unknown"
        }
    }
}
