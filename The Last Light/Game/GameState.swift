import Foundation
import SwiftUI
import SpriteKit
import Combine

/// THE GAME'S STATE ORCHESTRATOR.
/// Tracks player state, discoveries, resources, regions, risk, combo, noise and storms.
class GameState: ObservableObject {
    static let shared = GameState()

    @Published var starEnergy: Int = 0
    @Published var currentRegion: Region = .silentBelt
    @Published var lastKnownRegion: Region = .silentBelt
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
    @Published var activeDiscovery: Discovery? {
        didSet {
            NotificationCenter.default.post(name: .discoveryStateChange, object: activeDiscovery)
        }
    }

    // MARK: - Scanner State
    @Published var isScanning: Bool = false
    @Published var lastScanResults: [POI] = []
    @Published var nearbyPOIs: [POI] = []
    @Published var selectedPOIID: String?
    @Published var nearbyPOIID: String?
    @Published var playerPosition: CGPoint = .zero

    // MARK: - Risk / Visual
    @Published var currentRisk: Double = 0.0
    @Published var activeVisualTrails: Set<String> = []
    @Published var trackedIds: Set<String> = []
    @Published var collectedConstellationStars: [String: StarType] = [:]

    var riskLevel: Double { min(max(currentRisk, 0), 1.0) }

    // MARK: - Feature A: Starlight Combo + Volatiles
    @Published var comboCount: Int = 0
    @Published var comboTimeLeft: Double = 0
    @Published var comboMultiplier: Int = 1
    @Published var bestCombo: Int = 0
    @Published var totalVolatilesCollected: Int = 0
    @Published var lastComboAward: Int = 0

    // MARK: - Feature B: Noise / Stalker pressure
    @Published var noiseLevel: Double = 0.0
    @Published var stalkerActive: Bool = false
    @Published var stalkerDistance: CGFloat = 9999

    // MARK: - Feature C: Storms + Constellations
    @Published var stormActive: Bool = false
    @Published var stormTimeLeft: Double = 0
    @Published var stormNextIn: Double = EnhancementConfig.stormInitialDelay
    @Published var stormPOIIDs: [String] = []
    @Published var stormChainIndex: Int = 0
    @Published var completedConstellations: Set<String> = []
    @Published var memoryAnchors: Set<String> = []

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
        NotificationCenter.default.addObserver(
            forName: .discoveryStarted, object: nil, queue: .main
        ) { [weak self] _ in
            self?.addRisk(EnhancementConfig.riskPerDiscovery)
        }
    }

    // MARK: - Game flow
    func startNewGame() {
        starEnergy = 0
        currentRegion = .silentBelt
        lastKnownRegion = .silentBelt
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
        resources = [.energy: 50, .fragments: 0, .signal: 0]
        discoveredPOIs = []
        completedPOIs = []
        activeDiscovery = nil
        lastScanResults = []
        nearbyPOIs = []
        selectedPOIID = nil
        nearbyPOIID = nil
        playerPosition = .zero
        currentRisk = 0
        resetCombo()
        noiseLevel = 0
        stalkerActive = false
        stormActive = false
        stormTimeLeft = 0
        stormNextIn = EnhancementConfig.stormInitialDelay
        stormPOIIDs = []
        stormChainIndex = 0
        // Keep lifetime records across runs? Reset per journey except best.
        POIManager.shared.clear()
        DiscoveryManager.shared.clear()
        GhostSignalDecay.shared.clear()
        saveGame()
    }

    func continueGame() {
        isPlaying = true
        currentView = .game
    }

    func pauseGame() { isPlaying = false }
    func returnToMenu() {
        isPlaying = false
        currentView = .mainMenu
    }

    // MARK: - Resources
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

    func getResource(_ type: ResourceType) -> Int { resources[type] ?? 0 }

    // MARK: - Discovery
    func discoverPOI(_ poi: POI) {
        discoveredPOIs.insert(poi.id)
        addRisk(EnhancementConfig.riskPerDiscovery * 0.5)
        saveGame()
    }

    func completePOI(_ poi: POI) {
        completedPOIs.insert(poi.id)
        saveGame()
    }

    func isPOIDiscovered(_ poi: POI) -> Bool { discoveredPOIs.contains(poi.id) }
    func isPOICompleted(_ poi: POI) -> Bool { completedPOIs.contains(poi.id) }

    // MARK: - Stars + Combo (Feature A)
    @discardableResult
    func collectStar(_ starType: StarType, isVolatile: Bool = false) -> Int {
        // Combo first so award uses fresh multiplier.
        comboCount += 1
        comboTimeLeft = EnhancementConfig.comboWindow
        comboMultiplier = EnhancementConfig.multiplier(forCombo: comboCount)
        if comboCount > bestCombo { bestCombo = comboCount }

        var award = starType.energyValue * comboMultiplier
        if isVolatile {
            award = Int(Double(award) * EnhancementConfig.volatileBonusMultiplier)
            totalVolatilesCollected += 1
        }
        lastComboAward = award
        starEnergy += award
        totalStarsCollected += 1
        regionStarsCollected += 1
        shipEnergy = min(1.0, shipEnergy + Double(starType.energyValue) / 100.0)

        // Noise + risk pressure for threat loop.
        addNoise(isVolatile ? 0.22 : (starType == .ancient ? 0.15 : (starType == .golden ? 0.1 : 0.05)))
        if isVolatile { addRisk(0.03) }

        // Constellation tracking (string key avoids CGPoint Hashable issues).
        let key = "\(Int(playerPosition.x))_\(Int(playerPosition.y))_\(totalStarsCollected)"
        collectedConstellationStars[key] = starType
        if collectedConstellationStars.count > 200 {
            // Trim oldest to bound memory.
            let sorted = collectedConstellationStars.keys.sorted()
            for k in sorted.prefix(collectedConstellationStars.count - 200) {
                collectedConstellationStars.removeValue(forKey: k)
            }
        }
        ConstellationMemory.shared.trackStarCollection(type: starType)

        checkLoreDiscovery()
        checkRegionUnlock()
        saveGame()
        return award
    }

    func tickCombo(deltaTime: Double) {
        guard comboCount > 0 else { return }
        comboTimeLeft -= deltaTime
        if comboTimeLeft <= 0 {
            resetCombo()
        }
    }

    func resetCombo() {
        comboCount = 0
        comboTimeLeft = 0
        comboMultiplier = 1
    }

    func trackStarForConstellation(positionKey: String, starType: StarType) {
        collectedConstellationStars[positionKey] = starType
        ConstellationMemory.shared.trackStarCollection(type: starType)
    }

    // MARK: - Damage / energy
    func takeDamage(_ damage: Double) {
        // Phase drive reduces incoming damage.
        var scaled = damage
        if (upgradeLevels[.phaseDrive] ?? 0) > 0 { scaled *= 0.7 }
        shipShield = max(0.0, shipShield - scaled)
        if shipShield <= 0 {
            shipEnergy = max(0.0, shipEnergy - scaled * 0.5)
        }
        // Getting hit breaks combo — core risk/reward.
        if comboCount >= 2 { resetCombo() }
    }

    func useEnergy(_ amount: Double) { shipEnergy = max(0.0, shipEnergy - amount) }
    func restoreEnergy(_ amount: Double) { shipEnergy = min(1.0, shipEnergy + amount) }

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
        lastKnownRegion = currentRegion
        currentRegion = region
        regionStarsCollected = 0
        shipEnergy = 1.0
        shipShield = 1.0
        // Relief: entering a new region vents risk + noise, breaks combo fairly.
        ventRisk(0.25)
        noiseLevel = 0
        stalkerActive = false
        resetCombo()
        stormActive = false
        stormTimeLeft = 0
        stormNextIn = EnhancementConfig.stormInterval
        stormPOIIDs = []
        stormChainIndex = 0
        saveGame()
    }

    private func checkLoreDiscovery() {
        for entry in LoreSystem.allEntries where !discoveredLore.contains(entry.id) {
            // Legacy star-count lore path kept for compatibility; POI path is primary.
            // We keep it cheap: unlock transmission_01 after 5 total stars, etc.
            // Full thresholds live in GameScene.checkLoreDiscovery for region-scoped lore.
            if totalStarsCollected >= 5 && entry.id == "transmission_01" {
                discoverLore(entry.id)
            }
        }
    }

    private func checkRegionUnlock() {
        for region in Region.allCases where !unlockedRegions.contains(region) {
            if region.isUnlocked(gameState: self) { unlockRegion(region) }
        }
    }

    // MARK: - Risk (tension/relief)
    func addRisk(_ amount: Double) {
        currentRisk = min(1.0, currentRisk + amount)
    }

    func ventRisk(_ amount: Double) {
        currentRisk = max(0, currentRisk - amount)
    }

    // MARK: - Noise (stalker pressure)
    func addNoise(_ amount: Double) {
        noiseLevel = min(1.0, noiseLevel + amount)
    }

    func decayNoise(_ amount: Double) {
        noiseLevel = max(0, noiseLevel - amount)
    }

    // MARK: - Storms
    func tickStorm(deltaTime: Double) {
        if stormActive {
            stormTimeLeft -= deltaTime
            if stormTimeLeft <= 0 {
                stormActive = false
                stormTimeLeft = 0
                stormNextIn = EnhancementConfig.stormInterval
            }
        } else {
            stormNextIn -= deltaTime
            if stormNextIn <= 0 {
                stormActive = true
                stormTimeLeft = EnhancementConfig.stormDuration
                stormChainIndex = 0
            }
        }
    }

    func completeConstellation(named name: String, rewardSignal: Int, rewardFragments: Int) {
        completedConstellations.insert(name)
        addResource(.signal, amount: rewardSignal)
        addResource(.fragments, amount: rewardFragments)
        ventRisk(EnhancementConfig.constellationRiskVent)
        noiseLevel = max(0, noiseLevel - 0.3)
        // Memory anchor: protect newest lore from fading.
        if let newest = discoveredLore.sorted().last {
            memoryAnchors.insert(newest)
        }
        saveGame()
    }

    // MARK: - Persistence
    func saveGame() { SaveSystem.save(gameState: self) }

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
            resources = data.resources ?? [.energy: 50, .fragments: 0, .signal: 0]
            discoveredPOIs = data.discoveredPOIs ?? []
            completedPOIs = data.completedPOIs ?? []
            bestCombo = data.bestCombo ?? 0
            totalVolatilesCollected = data.totalVolatilesCollected ?? 0
            completedConstellations = data.completedConstellations ?? []
            memoryAnchors = data.memoryAnchors ?? []
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

extension Notification.Name {
    static let discoveryStarted = Notification.Name("discoveryStarted")
    static let discoveryStateChange = Notification.Name("discoveryStateChange")
    static let starCollected = Notification.Name("starCollected")
    static let loreDiscovered = Notification.Name("loreDiscovered")
    static let regionUnlocked = Notification.Name("regionUnlocked")
    static let poiDiscovered = Notification.Name("poiDiscovered")
    static let poiCompleted = Notification.Name("poiCompleted")
    static let comboChanged = Notification.Name("comboChanged")
    static let stormChanged = Notification.Name("stormChanged")
    static let stalkerChanged = Notification.Name("stalkerChanged")
}
