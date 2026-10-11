import Foundation

enum UpgradeType: String, Codable, CaseIterable, Identifiable, Hashable {
    case engine = "engine"
    case collector = "collector"
    case energy = "energy"
    case shield = "shield"
    case maneuverability = "maneuverability"
    case scanner = "scanner"
    case warp = "warp"
    case pulseScanner = "pulse_scanner"
    case gravityDrive = "gravity_drive"
    case signalDecoder = "signal_decoder"
    case starHarvester = "star_harvester"
    case phaseDrive = "phase_drive"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .engine: return "Engine"
        case .collector: return "Star Collector"
        case .energy: return "Energy Capacity"
        case .shield: return "Shield"
        case .maneuverability: return "Maneuverability"
        case .scanner: return "Scanner"
        case .warp: return "Warp Drive"
        case .pulseScanner: return "Pulse Scanner"
        case .gravityDrive: return "Gravity Drive"
        case .signalDecoder: return "Signal Decoder"
        case .starHarvester: return "Star Harvester"
        case .phaseDrive: return "Phase Drive"
        }
    }
    
    var description: String {
        switch self {
        case .engine: return "Increases ship speed and acceleration"
        case .collector: return "Increases star collection radius"
        case .energy: return "Increases maximum energy capacity"
        case .shield: return "Increases shield strength"
        case .maneuverability: return "Improves turning responsiveness"
        case .scanner: return "Detects lore and special stars from further away"
        case .warp: return "Allows faster travel between regions"
        case .pulseScanner: return "Reveals hidden POIs and objects"
        case .gravityDrive: return "Allows navigation through gravitational anomalies"
        case .signalDecoder: return "Decodes corrupted transmissions and reveals hidden messages"
        case .starHarvester: return "Enables collection of unstable stars"
        case .phaseDrive: return "Allows temporary movement through certain obstacles"
        }
    }
    
    var maxLevel: Int {
        switch self {
        case .engine: return 5
        case .collector: return 5
        case .energy: return 5
        case .shield: return 5
        case .maneuverability: return 5
        case .scanner: return 5
        case .warp: return 3
        case .pulseScanner: return 3
        case .gravityDrive: return 3
        case .signalDecoder: return 3
        case .starHarvester: return 3
        case .phaseDrive: return 3
        }
    }
    
    func cost(forLevel level: Int) -> Int {
        let baseCost: Int
        switch self {
        case .engine: baseCost = 20
        case .collector: baseCost = 15
        case .energy: baseCost = 25
        case .shield: baseCost = 30
        case .maneuverability: baseCost = 20
        case .scanner: baseCost = 35
        case .warp: baseCost = 100
        case .pulseScanner: baseCost = 50
        case .gravityDrive: baseCost = 75
        case .signalDecoder: baseCost = 60
        case .starHarvester: baseCost = 80
        case .phaseDrive: baseCost = 120
        }
        return baseCost * level
    }
    
    var icon: String {
        switch self {
        case .engine: return "flame"
        case .collector: return "circle.dashed"
        case .energy: return "battery.100"
        case .shield: return "shield"
        case .maneuverability: return "arrow.triangle.2.circlepath"
        case .scanner: return "radar"
        case .warp: return "sparkles"
        case .pulseScanner: return "sensor.tag.radiowaves.forward.fill"
        case .gravityDrive: return "arrow.triangle.down"
        case .signalDecoder: return "waveform.badge.magnifyingglass"
        case .starHarvester: return "star.circle.fill"
        case .phaseDrive: return "circle.dashed"
        }
    }
    
    func effectDescription(forLevel level: Int) -> String {
        switch self {
        case .engine:
            return "Speed: \(200 + level * 40)"
        case .collector:
            return "Radius: \(50 + level * 15)"
        case .energy:
            return "Capacity: \(100 + level * 25)"
        case .shield:
            return "Strength: \(100 + level * 25)"
        case .maneuverability:
            return "Turn Rate: \(String(format: "%.1f", 3.0 + Double(level) * 0.5))"
        case .scanner:
            return "Range: \(200 + level * 50)"
        case .warp:
            return "Warp Speed: \(level * 2)x"
        case .pulseScanner:
            return "Hidden POI Detection: \(level > 0 ? "Yes" : "No")"
        case .gravityDrive:
            return "Anomaly Access: \(level > 0 ? "Yes" : "No")"
        case .signalDecoder:
            return "Decode Level: \(level)"
        case .starHarvester:
            return "Unstable Star Collection: \(level > 0 ? "Yes" : "No")"
        case .phaseDrive:
            return "Phase Through Obstacles: \(level > 0 ? "Yes" : "No")"
        }
    }
}
