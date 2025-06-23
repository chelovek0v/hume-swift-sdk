//
//  Constants.swift
//  Hume
//
//  Created by Chris on 6/11/25.
//

import AVFoundation

enum Constants {
    static let SampleRate: Double = 48000
    static let InputChannels = 1
    static var SampleSize: Int = { Int(Self.SampleRate * Self.InputBufferDuration) }()
    static let InputBufferDuration = 0.02
        
    static let InputNodeBus = 0
    
    static let DefaultAudioFormat = AudioFormat.PCM_16BIT
    static let MinimumBufferSize = 128
    static let MaximumBufferSize = 4096
}
