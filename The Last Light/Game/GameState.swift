import Foundation
import SwiftUI
import Combine

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
    
    // New resource system
    @Published var resources: [ResourceType: Int] = [
        .energy: 50,
        .fragments: 0,
        .signal: 0
    ]
    
    // Discovery tracking
    @Published var discoveredPOIs: Set<String> = []
    @Published var completedPOIs: Set<String> = []
    @Published var activeDiscovery: Discovery?
    
    // Scanner state
    @Published var isScanning: Bool = false
    @Published var lastScanResults: [POI] = []
    @Published var nearbyPOIs: [POI] = []
    @Published var selectedPOIID: String?
    @Published var nearbyPOIID: String?
    @Published var playerPosition: CGPoint = .zero
    
    var shipStats: ShipStats {
        ShipStats(
            maxEnergy: 100.0 + Double(upgradeLevels[.energy] ?? 0) * 25.0,
            maxShield: 100.0 + Double(upgradeLevels[.shield] ?? 0) * 25.0,
            speed: 200.0 + Double(upgradeLevels[.engine] ?? 0) * 40.0,
            turnRate: 3.0 + Double(upgradeLevels[.maneuverability] ?? 0) * 0.5,
            collectionRadius: 50.0 + Double(upgradeLevels[.collector] ?? 0) * 15.0,
            scannerRange: 200.0 + Double(upgradeLevels[.scanner] ?? 0) * 50.0
        )
    }
    
    private init() {
        loadGame()
    }
    
    func startNewGame() {
        starEnergy = 0
        currentRegion = .silentBelt
        unlockedRegions = [.silentBelt]
        discoveredLore = []
        upgradeLevels = [:]
        shipEnergy = 1.0
        shipShield = 1.0
        totalStarsCollected = 0
        regionStarsCollected = 0
        hasStartedGame = true
        isPlaying = true
        currentView = .game
        
        // Reset new systems
        resources = [.energy: 50, .fragments: 0, .signal: 0]
        discoveredPOIs = []
        completedPOIs = []
        activeDiscovery = nil
        lastScanResults = []
        nearbyPOIs = []
        selectedPOIID = nil
        nearbyPOIID = nil
        playerPosition = .zero
        POIManager.shared.clear()
        DiscoveryManager.shared.clear()

        saveGame()
    }
    
    func continueGame() {
        isPlaying = true
        currentView = .game
    }
    
    func pauseGame() {
        isPlaying = false
    }
    
    func returnToMenu() {
        isPlaying = false
        currentView = .mainMenu
    }
    
    // MARK: - Resource Management
    
    func addResource(_ type: ResourceType, amount: Int) {
        let current = resources[type] ?? 0
        resources[type] = current + amount
        saveGame()
    }
    
    func removeResource(_ type: ResourceType, amount: Int) -> Bool {
        let current = resources[type] ?? 0
        guard current >= amount else { return false }
        resources[type] = current - amount
        saveGame()
        return true
    }
    
    func getResource(_ type: ResourceType) -> Int {
        return resources[type] ?? 0
    }
    
    // MARK: - Discovery Management
    
    func discoverPOI(_ poi: POI) {
        discoveredPOIs.insert(poi.id)
        saveGame()
    }
    
    func completePOI(_ poi: POI) {
        completedPOIs.insert(poi.id)
        saveGame()
    }
    
    func isPOIDiscovered(_ poi: POI) -> Bool {
        return discoveredPOIs.contains(poi.id)
    }
    
    func isPOICompleted(_ poi: POI) -> Bool {
        return completedPOIs.contains(poi.id)
    }
    
    // MARK: - Star Collection (legacy, kept for compatibility)
    
    func collectStar(_ starType: StarType) {
        starEnergy += starType.energyValue
        totalStarsCollected += 1
        regionStarsCollected += 1
        shipEnergy = min(1.0, shipEnergy + Double(starType.energyValue) / 100.0)
        checkLoreDiscovery()
        checkRegionUnlock()
        saveGame()
    }
    
    func takeDamage(_ damage: Double) {
        shipShield = max(0.0, shipShield - damage)
        if shipShield <= 0 {
            shipEnergy = max(0.0, shipEnergy - damage * 0.5)
        }
    }
    
    func useEnergy(_ amount: Double) {
        shipEnergy = max(0.0, shipEnergy - amount)
    }
    
    func restoreEnergy(_ amount: Double) {
        shipEnergy = min(1.0, shipEnergy + amount)
    }
    
    func purchaseUpgrade(_ type: UpgradeType) -> Bool {
        let currentLevel = upgradeLevels[type] ?? 0
        guard currentLevel < type.maxLevel else { return false }
        let cost = type.cost(forLevel: currentLevel + 1)
        guard starEnergy >= cost else { return false }
        starEnergy -= cost
        upgradeLevels[type] = currentLevel + 1
        saveGame()
        return true
    }
    
    func unlockRegion(_ region: Region) {
        unlockedRegions.insert(region)
        saveGame()
    }
    
    func discoverLore(_ loreId: String) {
        discoveredLore.insert(loreId)
        saveGame()
    }
    
    func travelToRegion(_ region: Region) {
        currentRegion = region
        regionStarsCollected = 0
        shipEnergy = 1.0
        shipShield = 1.0
        saveGame()
    }
    
    private func checkLoreDiscovery() {
        for entry in LoreSystem.allEntries where !discoveredLore.contains(entry.id) {
            if entry.isDiscovered(gameState: self) {
                discoverLore(entry.id)
            }
        }
    }
    
    private func checkRegionUnlock() {
        for region in Region.allCases where !unlockedRegions.contains(region) {
            if region.isUnlocked(gameState: self) {
                unlockRegion(region)
            }
        }
    }
    
    func saveGame() {
        SaveSystem.save(gameState: self)
    }
    
    func loadGame() {
        if let data = SaveSystem.load() {
            starEnergy = data.starEnergy
            currentRegion = data.currentRegion
            unlockedRegions = data.unlockedRegions
            discoveredLore = data.discoveredLore
            upgradeLevels = data.upgradeLevels
            totalStarsCollected = data.totalStarsCollected
            soundEnabled = data.soundEnabled
            musicEnabled = data.musicEnabled
            hasStartedGame = true
            
            // Load new systems
            resources = data.resources ?? [.energy: 50, .fragments: 0, .signal: 0]
            discoveredPOIs = data.discoveredPOIs ?? []
            completedPOIs = data.completedPOIs ?? []
        }
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
}
