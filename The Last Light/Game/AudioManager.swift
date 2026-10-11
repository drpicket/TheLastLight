import Foundation
import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    
    /// Pre-rendered tone data per sound name. Generating a WAV is O(samples);
    /// at combo x5 that work was repeated several times a second.
    private var soundData: [String: Data] = [:]
    private var players: [String: [AVAudioPlayer]] = [:]
    /// Each cached voice is single-use; retire finished ones before allocating more.
    private let maxVoicesPerSound = 4
    private var ambientPlayer: AVAudioPlayer?
    private var ambientData: Data?
    private var isSetup = false
    
    private init() {}
    
    func setup() {
        guard !isSetup else { return }
        isSetup = true
        prewarmSounds()
        
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
    
    /// Render every known effect once, off the hot path.
    private func prewarmSounds() {
        for name in Self.effectNames {
            let spec = Self.spec(for: name)
            if let data = generateToneData(frequency: spec.frequency, duration: spec.duration) {
                soundData[name] = data
            }
        }
    }
    
    private static let effectNames = [
        "collect", "collectBlue", "collectGolden", "collectAncient",
        "combo2", "combo3", "combo5", "volatile", "volatileExpire",
        "stalker", "slingshot", "storm", "constellation", "damage",
        "upgrade", "warp", "lore", "signal", "menu"
    ]
    
    /// Duration and frequency for a named effect. Unknown names fall back to a
    /// short neutral blip.
    private static func spec(for name: String) -> (duration: Double, frequency: Double) {
        switch name {
        case "collect": return (0.3, 880)
        case "collectBlue": return (0.4, 1100)
        case "collectGolden": return (0.5, 1320)
        case "collectAncient": return (0.8, 1760)
        case "combo2": return (0.35, 990)
        case "combo3": return (0.4, 1174)
        case "combo5": return (0.6, 1568)
        case "volatile": return (0.7, 1480)
        case "volatileExpire": return (0.4, 330)
        case "stalker": return (0.8, 165)
        case "slingshot": return (0.5, 740)
        case "storm": return (1.0, 520)
        case "constellation": return (1.2, 1318)
        case "damage": return (0.3, 220)
        case "upgrade": return (0.5, 660)
        case "warp": return (1.0, 440)
        case "lore": return (0.6, 990)
        case "signal": return (1.2, 550)
        case "menu": return (0.2, 770)
        default: return (0.3, 440)
        }
    }
    
    func playEffect(_ name: String) {
        guard GameState.shared.soundEnabled else { return }
        if soundData[name] == nil {
            // Unknown effect: render once, then remember it.
            let spec = Self.spec(for: name)
            soundData[name] = generateToneData(frequency: spec.frequency, duration: spec.duration)
        }
        guard let data = soundData[name] else { return }
        
        // Reclaim finished voices so repeated plays don't grow unbounded.
        var voices = players[name] ?? []
        voices.removeAll { !$0.isPlaying }
        if voices.count >= maxVoicesPerSound {
            voices.removeFirst()
        }
        do {
            let player = try AVAudioPlayer(data: data)
            player.prepareToPlay()
            player.play()
            voices.append(player)
            players[name] = voices
        } catch {
            print("Failed to play sound effect: \(error)")
        }
    }
    
    func startAmbientMusic() {
        guard GameState.shared.musicEnabled else { return }
        
        stopAmbientMusic()
        
        // Rendered once and reused; the scene resumes often (pause, menus).
        if ambientData == nil {
            ambientData = generateAmbientData()
        }
        guard let data = ambientData else { return }
        
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
