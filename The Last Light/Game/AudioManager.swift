import Foundation
import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    
    private var soundPlayers: [String: AVAudioPlayer] = [:]
    private var ambientPlayer: AVAudioPlayer?
    private var isSetup = false
    
    private init() {}
    
    func setup() {
        guard !isSetup else { return }
        isSetup = true
        
        #if os(iOS) || os(tvOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }
        #endif
    }
    
    func playEffect(_ name: String) {
        guard GameState.shared.soundEnabled else { return }
        
        let duration: Double
        let frequency: Double
        
        switch name {
        case "collect":
            duration = 0.3
            frequency = 880
        case "collectBlue":
            duration = 0.4
            frequency = 1100
        case "collectGolden":
            duration = 0.5
            frequency = 1320
        case "collectAncient":
            duration = 0.8
            frequency = 1760
        case "combo2":
            duration = 0.35
            frequency = 990
        case "combo3":
            duration = 0.4
            frequency = 1174
        case "combo5":
            duration = 0.6
            frequency = 1568
        case "volatile":
            duration = 0.7
            frequency = 1480
        case "volatileExpire":
            duration = 0.4
            frequency = 330
        case "stalker":
            duration = 0.8
            frequency = 165
        case "slingshot":
            duration = 0.5
            frequency = 740
        case "storm":
            duration = 1.0
            frequency = 520
        case "constellation":
            duration = 1.2
            frequency = 1318
        case "damage":
            duration = 0.3
            frequency = 220
        case "upgrade":
            duration = 0.5
            frequency = 660
        case "warp":
            duration = 1.0
            frequency = 440
        case "lore":
            duration = 0.6
            frequency = 990
        case "signal":
            duration = 1.2
            frequency = 550
        case "menu":
            duration = 0.2
            frequency = 770
        default:
            duration = 0.3
            frequency = 440
        }
        
        // Generate a simple tone buffer and play it
        guard let data = generateToneData(frequency: frequency, duration: duration) else { return }
        
        do {
            let player = try AVAudioPlayer(data: data)
            player.prepareToPlay()
            player.play()
        } catch {
            print("Failed to play sound effect: \(error)")
        }
    }
    
    func startAmbientMusic() {
        guard GameState.shared.musicEnabled else { return }
        
        stopAmbientMusic()
        
        // Generate ambient drone data
        guard let data = generateAmbientData() else { return }
        
        do {
            let player = try AVAudioPlayer(data: data)
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
            ambientPlayer = player
        } catch {
            print("Failed to start ambient music: \(error)")
        }
    }
    
    func stopAmbientMusic() {
        ambientPlayer?.stop()
        ambientPlayer = nil
    }
    
    private func generateToneData(frequency: Double, duration: Double) -> Data? {
        let sampleRate = 44100
        let frameCount = Int(Double(sampleRate) * duration)
        var samples: [Float] = []
        
        for frame in 0..<frameCount {
            let time = Double(frame) / Double(sampleRate)
            let envelope = exp(-3.0 * time / duration)
            let sample = sin(2.0 * Double.pi * frequency * time) * envelope * 0.3
            samples.append(Float(sample))
        }
        
        return convertFloatArrayToData(samples: samples, sampleRate: sampleRate)
    }
    
    private func generateAmbientData() -> Data? {
        let sampleRate = 44100
        let duration = 10.0
        let frameCount = Int(Double(sampleRate) * duration)
        var samples: [Float] = []
        
        for frame in 0..<frameCount {
            let time = Double(frame) / Double(sampleRate)
            
            let sample1 = sin(2.0 * Double.pi * 110.0 * time) * 0.1
            let sample2 = sin(2.0 * Double.pi * 165.0 * time) * 0.08
            let sample3 = sin(2.0 * Double.pi * 220.0 * time) * 0.05
            let sample4 = sin(2.0 * Double.pi * 275.0 * time) * 0.03
            
            let modulation = 0.7 + 0.3 * sin(2.0 * Double.pi * 0.1 * time)
            
            let sample = (sample1 + sample2 + sample3 + sample4) * modulation
            samples.append(Float(sample))
        }
        
        return convertFloatArrayToData(samples: samples, sampleRate: sampleRate)
    }
    
    private func convertFloatArrayToData(samples: [Float], sampleRate: Int) -> Data? {
        var data = Data()
        
        // WAV header
        let byteRate = sampleRate * 2
        let dataSize = samples.count * 2
        
        // RIFF chunk
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        data.append(contentsOf: withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian, Array.init))
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        
        // fmt chunk
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init)) // PCM
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init)) // mono
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: UInt32(byteRate).littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian, Array.init)) // block align
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian, Array.init)) // bits per sample
        
        // data chunk
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian, Array.init))
        
        // Convert float samples to 16-bit PCM
        for sample in samples {
            let intSample = Int16(max(-1.0, min(1.0, sample)) * Float(Int16.max))
            data.append(contentsOf: withUnsafeBytes(of: intSample.littleEndian, Array.init))
        }
        
        return data
    }
}
