import AVFoundation

public class Microphone: NSObject {
    private var audioEngine: AVAudioEngine!
    private var audioConverter: AVAudioConverter!
    private var inputNode: AVAudioInputNode!
    private var desiredFormat: AVAudioFormat!
    
    public var onChunk: (Data, Int) -> Void = { _, _ in }
    public var onError: (String) -> Void = { _ in }
    public var isMuted: Bool = false
    
    private var chunkId: Int = 0

    public init(sampleRate: Double, samplingSize: Int) {
        super.init()
        configureInput(sampleRate: sampleRate, samplingSize: samplingSize)
    }

    private func configureInput(sampleRate: Double, samplingSize: Int) {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode

        do {
            /// This outputs a lot of warnings to the console but still cancels the echo. I'd love to figure out why but haven't been unsuccessful so far
            try inputNode.setVoiceProcessingEnabled(true)
        } catch {
            onError("Error enabling voice processing: \(error.localizedDescription)")
            return
        }

        let nativeFormat = inputNode.outputFormat(forBus: 0)
        
        /// We are locking format to mono PCM Int16 at the chosen sample rate. This could be changed to allow more flexibility
        desiredFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: sampleRate, channels: 1, interleaved: false)
        
        audioConverter = AVAudioConverter(from: nativeFormat, to: desiredFormat)

        guard audioConverter != nil else {
            onError("Conversion to desired format is not possible! Please ensure your stream settings and device capabilities are aligned.")
            return
        }

        let sampleRateCoefficient = nativeFormat.sampleRate / desiredFormat.sampleRate
        let convertedBufferSize = UInt32(Double(samplingSize) * sampleRateCoefficient)


        /// Some apple docs say tapping a node isn't suitable for real-time processing but I haven't run into any issues (so far)
        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(samplingSize), format: nativeFormat) { [weak self] (buffer, when) in
        
            buffer.frameLength = AVAudioFrameCount(samplingSize)
            
            guard let self = self else { return }
            
            
            /// Since sampling size is given in terms of desired format, our converted buffer should be of that size
            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: self.desiredFormat, frameCapacity: AVAudioFrameCount(samplingSize))!
            
            let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            var error: NSError? = nil
            let status = self.audioConverter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
            if status != .haveData || error != nil {
                self.onError("Conversion error: \(String(describing: error?.localizedDescription))")
                return
            }
            
            if !self.isMuted {
                let audioDataPointer = convertedBuffer.int16ChannelData!.pointee /// Hard-coded to int16 data. Again, not a hard requirement but would need to change this to get usable data
                let audioDataSize = Int(convertedBuffer.frameLength * self.desiredFormat.streamDescription.pointee.mBytesPerFrame)
                let audioData = Data(bytesNoCopy: audioDataPointer, count: audioDataSize, deallocator: .none)

                self.onChunk(audioData, self.chunkId)
            }
            
            self.chunkId += 1
        }

        do {
            try audioEngine.prepare()
        } catch {
            onError("AVAudioEngine start error: \(error.localizedDescription)")
        }
    }

    public func start() {
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                onError("AVAudioEngine start error: \(error.localizedDescription)")
            }
        }
    }

    public func stop() {
        if audioEngine.isRunning {
            inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
    }

    public func mute() {
        isMuted = true
    }

    public func unmute() {
        isMuted = false
    }
}
