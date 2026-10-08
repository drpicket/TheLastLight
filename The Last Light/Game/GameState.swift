import Foundation
import SwiftUI
import SpriteKit
import Combine

/// THE GAME'S STATE ORCHESTRATOR.
/// Tracks player state, discoveries, resources, regions, and risk accumulation.
/// Serves as the central hub connecting all gameplay systems.

class GameState: ObservableObject {
    static let shared = GameState()
    
    @Published var starEnergy: Int = 0
    @Published var currentRegion: Region = .silentBelt
    @Published var unlockedRegions: Set<Region> = [.silentBelt]
    @Published var discoveredLore: Set<String> = []
    @Published var upgradeLevels: [UpgradeType: Int] = [:]
    @Published var shipEnergy: Double = 1.0
    @Published var shipShield: Double = 1.0
    @Published var totalStarsCollected: Int = 0
    @Published var regionStarsCollected: Int = 0
    @Published var isPlaying: Bool = false
    @Published var hasStartedGame: Bool = false
    @Published var soundEnabled: Bool = true
    @Published var musicEnabled: Bool = true
    @Published var currentView: AppView = .mainMenu
    @Published var joystickDirection: CGVector = .zero
    
    // MARK: - Resource Management
    
    @Published var resources: [ResourceType: Int] = [
        .energy: 50,
        .fragments: 0,
        .signal: 0
    ]
    
    // MARK: - Discovery Tracking
    
    @Published var discoveredPOIs: Set<String> = []
    @Published var completedPOIs: Set<String> = []
    var activeDiscovery: Discovery? {
        didSet {
            
            NotificationCenter.default.post(
                name: .discoveryStateChange, object: activeDiscovery
            )
        }
    }
    
    // MARK: - Scanner State
    
    @Published var isScanning: Bool = false
    @Published var lastScanResults: [POI] = []
    @Published var nearbyPOIs: [POI] = []
    @Published var selectedPOIID: String?
    @Published var nearbyPOIID: String?
    @Published var playerPosition: CGPoint = .zero
    
    // MARK: - Visual & Risk (New Systems)
    
    @Published var currentRisk: Double = 0.0
    @Published var activeVisualTrails: Set<String> = []
    @Published var trackedIds: Set<String> = []
    @Published var collectedConstellationStars: [String: StarType] = [:] // Position identifier -> star type
    
    private var riskAccrualSystem: RiskAccrualSystem?
    
    init() {
        loadGame()
        
        // Create risk accrual system once game state loads
        if let system = RiskAccrualSystem.shared(instance: self) {
            riskAccrualSystem = system
        }
        
        NotificationCenter.default.addObserver(
            forName: .discoveryStarted, object: nil, queue: mainQueue
        ) { [weak self] _ in
            self?.riskAccrualSystem?.trackDiscovery()
        }
    }
    
    deinit {
        
        if let system = RiskAccrualSystem.shared.instance {
            
            NotificationCenter.default.removeObserver(self)
        }
        riskAccrualSystem = nil
    }
}

enum AppView: Codable {
    case mainMenu
    case game
    case starMap
    case archives
    case shipUpgrade
    case settings
}

struct ShipStats {
    let maxEnergy: Double
    let maxShield: Double
    let speed: Double
    let turnRate: Double
    let collectionRadius: Double
    let scannerRange: Double
    
    // MARK: - Visual Effects Calculator for New Mechanics
    
    private func calculateVisualEffects() -> VisualEffects {
        if currentRisk < EnhancementConfig.riskThreshold * 0.5 {
            return .normal
        } else if currentRisk < EnhancementConfig.riskThreshold {
            return .mild
        } else if currentRisk < EnhancementConfig.riskThreshold * 1.2 {
            return .moderate
        } else {
            return .severe
        }
    }
}

/// MARK: - The Last Light 1.1 Enhanced Mechanics Integration

class RiskAccrualSystem {
    static let shared = RiskAccrualSystem()
    
    var instance: GameState
    
    init(instance: GameState) {
        self.instance = instance
        
        NotificationCenter.default.addObserver(
            forName: .discoveryStarted, object: nil, queue: mainQueue
        ) { [weak self] _ in
            self?.trackDiscovery()
        }
    }
    
    var currentRisk: Double {
        return min(instance.currentRisk, 1.0)
    }
    
    private func trackDiscovery() {
        var newRisk = instance.currentRisk + EnhancementConfig.riskPerDiscovery
        
        // Check if we've exceeded threshold for overage multiplier
        if newRisk > EnhancementConfig.riskThreshold {
            let overage = max(0, instance.currentRisk - EnhancementConfig.riskThreshold) * EnhancementConfig.riskOverageMultiplier
            
            if instance.currentRisk < 1.0 {
                instance.currentRisk = min(1.0, EnhancementConfig.riskThreshold + overage)
            }
        } else {
            instance.currentRisk += EnhancementConfig.riskPerDiscovery - 0.05
        }
    }
}

extension GameState {
    
    // MARK: - New 1.1 Feature Methods
    
    @Published var lastKnownRegion: Region = .silentBelt
    
    /// Track discovery of a POI (increases risk accumulation)
    func discoverPOI(_ poi: POI) {
        discoveredPOIs.insert(poi.id)
        
        // Add risk from discovery accumulation
        currentRisk += EnhancementConfig.riskPerDiscovery * 0.5
        
        saveGame()
    }
    
    /// Complete a POI
    func completePOI(_ poi: POI) {
        completedPOIs.insert(poi.id)
        saveGame()
    }
    
    /// Track star collection for constellation pattern recognition
    func trackStarForConstellation(positionKey: String, starType: StarType) {
        if totalStarsCollected >= EnhancementConfig.constellationThreshold {
            collectedConstellation = [:]
        } else {
            
            collectedConstarations[positionKey] = starType
            
            // Check for constellation patterns periodically
           checkConstellations = NSNotification.Name("checkConstitutionPattern")
        }
    }
    
    func saveGame() {
        SaveSystem.save(gameState: self)
    }
}

let discoveryStarted = NSNotification.Name("discoveryStarted")
