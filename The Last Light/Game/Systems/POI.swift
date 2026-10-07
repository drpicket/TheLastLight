import Foundation
import SpriteKit

/// Represents a type of Point of Interest in the game world.
enum POIType: String, Codable, CaseIterable {
    case stellarFragment
    case unknownSignal
    case abandonedProbe
    case anomaly
    case derelictShip
    case ancientStructure
    case hiddenObject
    case regionGateway
    
    var displayName: String {
        switch self {
        case .stellarFragment: return "Stellar Fragment"
        case .unknownSignal: return "Unknown Signal"
        case .abandonedProbe: return "Abandoned Probe"
        case .anomaly: return "Gravitational Anomaly"
        case .derelictShip: return "Derelict Ship"
        case .ancientStructure: return "Ancient Structure"
        case .hiddenObject: return "Hidden Object"
        case .regionGateway: return "Region Gateway"
        }
    }
    
    var icon: String {
        switch self {
        case .stellarFragment: return "star.fill"
        case .unknownSignal: return "antenna.radiowaves.left.and.right"
        case .abandonedProbe: return "sensor.tag.radiowaves.forward.fill"
        case .anomaly: return "waveform.path.ecg"
        case .derelictShip: return "airplane"
        case .ancientStructure: return "building.columns.fill"
        case .hiddenObject: return "questionmark.circle.fill"
        case .regionGateway: return "arrow.triangle.branch"
        }
    }
    
    var riskLevel: RiskLevel {
        switch self {
        case .stellarFragment: return .low
        case .abandonedProbe: return .low
        case .hiddenObject: return .low
        case .unknownSignal: return .medium
        case .derelictShip: return .medium
        case .anomaly: return .high
        case .ancientStructure: return .high
        case .regionGateway: return .none
        }
    }
    
    var color: SKColor {
        switch self {
        case .stellarFragment: return SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1.0)
        case .unknownSignal: return SKColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
        case .abandonedProbe: return SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        case .anomaly: return SKColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 1.0)
        case .derelictShip: return SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        case .ancientStructure: return SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
        case .hiddenObject: return SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        case .regionGateway: return SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)
        }
    }
}

enum RiskLevel: String, Codable {
    case none
    case low
    case medium
    case high
    
    var displayName: String {
        switch self {
        case .none: return "No Risk"
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        }
    }
    
    var color: SKColor {
        switch self {
        case .none: return SKColor.green
        case .low: return SKColor.green
        case .medium: return SKColor.yellow
        case .high: return SKColor.red
        }
    }
}

/// Represents a Point of Interest in the game world.
/// POIs are discovered through the scanner and can be interacted with.
class POI: Identifiable, Codable {
    let id: String
    let type: POIType
    var position: CGPoint
    var isDiscovered: Bool
    var isCompleted: Bool
    var discoveryHint: String?
    var signalStrength: Double?
    var loreEntryId: String?
    var rewardResources: [ResourceType: Int]
    var requiredUpgrade: UpgradeType?
    
    init(
        id: String = UUID().uuidString,
        type: POIType,
        position: CGPoint,
        isDiscovered: Bool = false,
        isCompleted: Bool = false,
        discoveryHint: String? = nil,
        signalStrength: Double? = nil,
        loreEntryId: String? = nil,
        rewardResources: [ResourceType: Int] = [:],
        requiredUpgrade: UpgradeType? = nil
    ) {
        self.id = id
        self.type = type
        self.position = position
        self.isDiscovered = isDiscovered
        self.isCompleted = isCompleted
        self.discoveryHint = discoveryHint
        self.signalStrength = signalStrength
        self.loreEntryId = loreEntryId
        self.rewardResources = rewardResources
        self.requiredUpgrade = requiredUpgrade
    }
    
    var riskLevel: RiskLevel {
        return type.riskLevel
    }
    
    var displayName: String {
        return type.displayName
    }
    
    var canInteract: Bool {
        if isCompleted { return false }
        if let required = requiredUpgrade {
            return (GameState.shared.upgradeLevels[required] ?? 0) > 0
        }
        return true
    }
}

/// Resource types in the new economy.
enum ResourceType: String, Codable, CaseIterable {
    case energy
    case fragments
    case signal
    
    var displayName: String {
        switch self {
        case .energy: return "Energy"
        case .fragments: return "Fragments"
        case .signal: return "Signal"
        }
    }
    
    var icon: String {
        switch self {
        case .energy: return "bolt.fill"
        case .fragments: return "cube.fill"
        case .signal: return "waveform"
        }
    }
    
    var color: SKColor {
        switch self {
        case .energy: return SKColor.yellow
        case .fragments: return SKColor.cyan
        case .signal: return SKColor.purple
        }
    }
}
