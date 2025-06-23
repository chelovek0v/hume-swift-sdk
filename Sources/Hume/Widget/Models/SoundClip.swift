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
    public let header: WAVHeader?
    
    public static func from(_ audioOutput: AudioOutput) -> SoundClip? {
        guard let audioData = audioOutput.asBase64EncodedData else {
            return nil
        }
        
        return SoundClip(id: audioOutput.id,
                    index: audioOutput.index,
                    audioData: audioData,
                         header: parseWAVHeader(from: audioData))
    }
}

public struct WAVHeader {
    let chunkID: String
    let format: String
    let subchunk1ID: String
    let audioFormat: UInt16
    let numChannels: UInt16
    let sampleRate: UInt32
    let byteRate: UInt32
    let blockAlign: UInt16
    let bitsPerSample: UInt16
}

fileprivate extension SoundClip {
    static func parseWAVHeader(from data: Data) -> WAVHeader? {
        guard data.count >= 44 else { return nil }
        
        func readString(_ offset: Int, _ length: Int) -> String {
            let subdata = data.subdata(in: offset..<offset+length)
            return String(decoding: subdata, as: UTF8.self)
        }
        
        func readUInt16(_ offset: Int) -> UInt16 {
            return data.subdata(in: offset..<offset+2).withUnsafeBytes { $0.load(as: UInt16.self) }
        }
        
        func readUInt32(_ offset: Int) -> UInt32 {
            return data.subdata(in: offset..<offset+4).withUnsafeBytes { $0.load(as: UInt32.self) }
        }
        
        return WAVHeader(
            chunkID: readString(0, 4),
            format: readString(8, 4),
            subchunk1ID: readString(12, 4),
            audioFormat: readUInt16(20),
            numChannels: readUInt16(22),
            sampleRate: readUInt32(24),
            byteRate: readUInt32(28),
            blockAlign: readUInt16(32),
            bitsPerSample: readUInt16(34)
        )
    }
}
