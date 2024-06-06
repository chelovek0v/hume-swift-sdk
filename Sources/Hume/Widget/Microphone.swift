//
//  Microphone.swift
//
//
//  Created by Daniel Rees on 5/31/24.
//

import AVFoundation

public class Microphone: NSObject {
    
    // -- Callbacks
    public var onAudioCaptured: (Data) -> Void = { _ in fatalError("Provide microphone.onAudioCaptured = { } ")}
    public var onStartRecording: (() -> Void)? = nil
    public var onStopRecording: (() -> Void)? = nil
    public var onError: (_ message: String) -> Void = { _ in }
    
    
    // -- Recording Variables
    // AVAudioEngine used to record
    var engine = AVAudioEngine()
    
    // Set this as per your liking (512, 1024, 2048)
    let estimatedBufferSize: AVAudioFrameCount = 1024
    
    // Will be configured to write the buffer to a file
    var file: AVAudioFile?
    
    // Chunk duration in seconds, adjust as needed
    let chunkDuration: Float64 = 1
    
    // Will be used to uniquely name the different chunks
    var currentChunkCount = 0
    
    // Keeps track of how many frames in current chunk
    // Used to check how much time has elapsed
    var framesInCurrentChunk: AVAudioFrameCount = 0

    
    public func start() throws {
        print("start recording")
        
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Prepare how the AVAudioEngine should process input
        engine.inputNode.installTap(onBus: 0,
                                    bufferSize: 1024,
                                    format: engine.inputNode.inputFormat(forBus: 0))
        { [weak self] (buffer, time) -> Void in
            
            // Write the buffer to your file
            self?.writeBufferToFile(buffer: buffer)
        }
        
        // Start recording
        try! engine.start()
    }
    
    
    public func stop() {
        // Clean up and reset
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        
        if let url =  file?.url {
            let audioData = try! Data(contentsOf: url)
            onAudioCaptured(audioData)
            
            destroyOutputFile(at: url)
        }
        
        file = nil
        framesInCurrentChunk = 0
    }
    
    public func mute() {
        engine.pause()
    }
    
    public func unmute() throws {
        try engine.start()
    }
    
    public var isMuted: Bool { engine.isRunning == false }
    
    
    // MARK: - Private Helpers -
    private func writeBufferToFile(buffer: AVAudioPCMBuffer) {
        let samplesPerSecond = buffer.format.sampleRate
        
        // Check if we have an open file writer
        if file == nil {
            // Configure an AVAudioFile to write the audio buffer to file
            prepareOutputFile()
        }
        
        do {
            try file?.write(from: buffer)
            framesInCurrentChunk += buffer.frameLength
        } catch {
            // error appending the chunk to file
            print(error)
        }
        
        // Check if the current chunk has reached it's duration
        if framesInCurrentChunk > AVAudioFrameCount(chunkDuration * samplesPerSecond){
            // Here is where you have a valid chunk that has been saved in
            // the duration you want, put the last saved aac file in a queue to be
            // uploaded to your server here
            if let url = file?.url {
                let audioData = try! Data(contentsOf: url)
                onAudioCaptured(audioData)
                
                destroyOutputFile(at: url)
            }
            
            // De-initialize the current file writer so we can start a new one
            file = nil
        }
    }
    
    private func destroyOutputFile(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            print("Deleted File \(url.lastPathComponent)")
        } catch let error as NSError {
            print("Error: \(error.domain)")
        }
    }
    
    private func prepareOutputFile() {
        // Increment the current chunk count to create a new file
        currentChunkCount += 1
        
        // Set the path of where the file will be stored in the document directory
        let documentsURL = FileManager.default.urls(for: .documentDirectory,
                                                    in: .userDomainMask)[0]
        
        let outputURL = documentsURL.appendingPathComponent("recording_\(currentChunkCount).aac")
        
        print("Recording audio to path: \(outputURL)")
        
        do {
            // Configure the AVAudioFile with the output path and output format
            file = try AVAudioFile(forWriting: outputURL,
                                   settings: [AVFormatIDKey: kAudioFormatMPEG4AAC])
        } catch {
            // Handle errors in configuring the the AVAudioFile
            print(error)
        }
        
        // Reset the frames saved in the current chunk
        framesInCurrentChunk = 0
    }
}
