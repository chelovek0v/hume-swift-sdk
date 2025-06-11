//
//  SoundClip.swift
//  HumeAI2
//
//  Created by Chris on 12/16/24.
//

import Foundation

public struct SoundClip {
    public let id: String
    public let index: Int
    public let audioData: Data
    
    public static func from(_ audioOutput: AudioOutput) -> SoundClip? {
        guard let audioData = audioOutput.asBase64EncodedData else {
            return nil
        }
        return SoundClip(id: audioOutput.id,
                    index: audioOutput.index,
                    audioData: audioData)
    }
}
