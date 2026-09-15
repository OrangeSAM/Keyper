import AVFoundation
import Foundation

/// Audio playback engine using AVAudioEngine with uniform format normalization
/// Replaces the deprecated OpenAL used in original Tickeys
class AudioEngine {
    private let engine = AVAudioEngine()
    private var players: [AudioPlayer] = []
    private var buffers: [AVAudioPCMBuffer] = []
    private var currentPlayerIndex = 0
    private let playerCount = 2  // Exactly matching original Tickeys SimpleAudioPlayer::new(2)
    private let lock = NSLock()

    /// Universal standard audio format used across all internal nodes and buffers
    private let standardFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

    var volume: Float = 0.5 {
        didSet {
            lock.lock()
            defer { lock.unlock() }
            for p in players {
                p.node.volume = volume
            }
        }
    }

    var pitch: Float = 1.0 {
        didSet {
            lock.lock()
            defer { lock.unlock() }
            let rate = max(0.25, min(4.0, pitch))
            for p in players {
                p.varispeed.rate = rate
            }
        }
    }

    private struct AudioPlayer {
        let node: AVAudioPlayerNode
        let varispeed: AVAudioUnitVarispeed
    }

    init() {
        setupEngine()
    }

    private func setupEngine() {
        for _ in 0..<playerCount {
            let node = AVAudioPlayerNode()
            let varispeed = AVAudioUnitVarispeed()
            varispeed.rate = pitch

            engine.attach(node)
            engine.attach(varispeed)

            // Connect using the exact standardFormat to guarantee compatibility with all scheduled buffers
            engine.connect(node, to: varispeed, format: standardFormat)
            engine.connect(varispeed, to: engine.mainMixerNode, format: standardFormat)

            players.append(AudioPlayer(node: node, varispeed: varispeed))
        }

        do {
            try engine.start()
            for p in players {
                p.node.play()
                p.node.volume = volume
            }
            print("[AudioEngine] Engine started with \(playerCount) players on format \(standardFormat)")
        } catch {
            print("[AudioEngine] Failed to start engine: \(error)")
        }
    }

    /// Load audio files for a scheme and convert them to standardFormat PCM buffers
    func loadSchemeAudio(scheme: AudioScheme, schemeManager: SchemeManager) {
        lock.lock()
        defer { lock.unlock() }

        buffers.removeAll()

        for fileName in scheme.files {
            guard let url = schemeManager.audioFileURL(scheme: scheme, fileName: fileName) else {
                print("[AudioEngine] Audio file not found: \(scheme.name)/\(fileName)")
                continue
            }

            if let buffer = loadAndNormalizeAudioBuffer(from: url) {
                buffers.append(buffer)
            } else {
                print("[AudioEngine] Failed to load/convert buffer for \(fileName)")
            }
        }

        print("[AudioEngine] Successfully loaded and normalized \(buffers.count)/\(scheme.files.count) audio files for scheme '\(scheme.displayName)'")
    }

    /// Convert any audio file into standardFormat (44.1kHz stereo Float32)
    private func loadAndNormalizeAudioBuffer(from url: URL) -> AVAudioPCMBuffer? {
        do {
            let file = try AVAudioFile(forReading: url)
            let fileFormat = file.processingFormat
            let frameCount = AVAudioFrameCount(file.length)

            guard frameCount > 0 else { return nil }

            guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: fileFormat, frameCapacity: frameCount) else {
                return nil
            }
            try file.read(into: sourceBuffer)

            // If already matches standard format, return directly
            if fileFormat == standardFormat {
                return sourceBuffer
            }

            // Convert to standardFormat using AVAudioConverter
            guard let converter = AVAudioConverter(from: fileFormat, to: standardFormat) else {
                print("[AudioEngine] Could not create converter for \(url.lastPathComponent)")
                return nil
            }

            let sampleRatio = standardFormat.sampleRate / fileFormat.sampleRate
            let outputCapacity = AVAudioFrameCount(Double(sourceBuffer.frameLength) * sampleRatio + 256)
            guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: standardFormat, frameCapacity: outputCapacity) else {
                return nil
            }

            var consumed = false
            var error: NSError?
            let status = converter.convert(to: outputBuffer, error: &error) { inNumPackets, outStatus in
                if consumed {
                    outStatus.pointee = .endOfStream
                    return nil
                }
                consumed = true
                outStatus.pointee = .haveData
                return sourceBuffer
            }

            if status == .error || error != nil {
                print("[AudioEngine] Conversion failed for \(url.lastPathComponent): \(String(describing: error))")
                return nil
            }

            return outputBuffer
        } catch {
            print("[AudioEngine] Error reading audio file \(url.lastPathComponent): \(error)")
            return nil
        }
    }

    /// Play the audio buffer at the given index
    func play(bufferIndex: Int) {
        lock.lock()
        defer { lock.unlock() }

        guard bufferIndex >= 0, bufferIndex < buffers.count else { return }

        // Ensure engine is running
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("[AudioEngine] Failed to restart audio engine: \(error)")
                return
            }
        }

        let buffer = buffers[bufferIndex]
        let player = players[currentPlayerIndex % playerCount]

        player.node.volume = volume
        player.node.stop()
        player.node.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.node.play()

        currentPlayerIndex = (currentPlayerIndex + 1) % playerCount
    }

    /// Stop all audio
    func stopAll() {
        lock.lock()
        defer { lock.unlock() }
        for p in players {
            p.node.stop()
        }
    }

    /// Restart the engine (e.g., after system sleep)
    func restart() {
        lock.lock()
        defer { lock.unlock() }
        if !engine.isRunning {
            do {
                try engine.start()
                for p in players {
                    p.node.play()
                }
                print("[AudioEngine] Engine restarted successfully")
            } catch {
                print("[AudioEngine] Failed to restart: \(error)")
            }
        }
    }
}
