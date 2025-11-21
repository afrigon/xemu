import AVFoundation
import XemuFoundation

class AudioService {
    let engine = AVAudioEngine()
    let frameCapacity: AVAudioFrameCount
    let format: AVAudioFormat
    
    var sampleQueue: [f32] = [] // TODO: modify this to handle multiple channels

    init?(sampleRate: Double = 44100, channels: AVAudioChannelCount = 1) {
        let samplesPerSecond = Int(Double(sampleRate) / 60)
        var frameCapacity: AVAudioFrameCount = 1
        
        while frameCapacity < samplesPerSecond {
            frameCapacity *= 2
        }
        
        self.frameCapacity = frameCapacity
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: channels) else {
            return nil
        }
        
        self.format = format
        
        let sourceNode = AVAudioSourceNode(format: format, renderBlock: renderAudio)
        
        engine.mainMixerNode.outputVolume = 0
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        engine.prepare()
    }
    
    deinit {
        stop()
    }

    func start() {
        try? engine.start()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.engine.mainMixerNode.outputVolume = 1
        }
    }
    
    @objc func stop() {
        engine.mainMixerNode.outputVolume = 0
        
        sampleQueue.removeAll(keepingCapacity: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.engine.stop()
        }
    }
    
    func renderAudio(
        isSilenced: UnsafeMutablePointer<ObjCBool>,
        timestamp: UnsafePointer<AudioTimeStamp>,
        frameCount: UInt32,
        outputData: UnsafeMutablePointer<AudioBufferList>
    ) -> OSStatus {
        guard !sampleQueue.isEmpty else {
            isSilenced.pointee = true
            return 0
        }
        
        isSilenced.pointee = false

        let count = min(Int(frameCount), sampleQueue.count)
        let output = UnsafeMutableAudioBufferListPointer(outputData)
        let channel = UnsafeMutableBufferPointer<Float>(output[0])
        
        for i in 0..<count {
            channel[i] = sampleQueue[i]
        }
        
        // this is a hack to prevent the audio doing from clicks and pops when not enough samples are available.
        // TODO: make sure enough samples are sent to keep up with playback
        for i in count..<Int(frameCount) {
            channel[i] = channel[count - 1]
        }

        sampleQueue.removeFirst(count)
        
        return 0
    }

    func schedule(_ buffer: [f32]) {
        if !engine.isRunning {
            start()
        }
        
        sampleQueue.append(contentsOf: buffer)
    }
        
    func schedule(left: [f32], right: [f32]) {
        // TODO: implement this
    }
}
