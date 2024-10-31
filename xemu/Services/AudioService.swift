import AVFoundation
import XemuFoundation

class AudioService {
    let engine = AVAudioEngine()
    let player: AVAudioPlayerNode = AVAudioPlayerNode()
    let format: AVAudioFormat? = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)

    let buffer: AVAudioPCMBuffer

    init?() {
        guard let format,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            return nil
        }

        self.buffer = buffer

        engine.attach(player)

        engine.connect(
            player,
            to: engine.mainMixerNode,
            format: format
        )
    }

    func start() {
        try? engine.start()
        player.play()
    }

    func stop() {
        engine.stop()
        player.stop()
    }

    func schedule(_ buffer: [Float]) {
        buffer.withUnsafeBufferPointer { buffer in
            guard let pointer = buffer.baseAddress else {
                return
            }

            self.buffer.floatChannelData?[0].update(from: pointer, count: buffer.count)
        }

        self.buffer.frameLength = UInt32(buffer.count)
        player.scheduleBuffer(self.buffer)
    }
}
