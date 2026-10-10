import Foundation

struct SaveSystem {
    private static let saveKey = "StarfallEnhancedSave_v2"

    struct SaveData: Codable {
        var starEnergy: Int
        var currentRegion: Region
        var unlockedRegions: Set<Region>
        var discoveredLore: Set<String>
        var upgradeLevels: [UpgradeType: Int]
        var totalStarsCollected: Int
        var soundEnabled: Bool
        var musicEnabled: Bool
        // Optional so old saves still decode.
        var resources: [ResourceType: Int]?
        var discoveredPOIs: Set<String>?
        var completedPOIs: Set<String>?
        var bestCombo: Int?
        var totalVolatilesCollected: Int?
        var completedConstellations: Set<String>?
        var memoryAnchors: Set<String>?
        var directiveIndex: Int?
        var directiveComplete: Bool?
        var highScore: Int?
    }

    static func save(gameState: GameState = GameState.shared) {
        let data = SaveData(
            starEnergy: gameState.starEnergy,
            currentRegion: gameState.currentRegion,
            unlockedRegions: gameState.unlockedRegions,
            discoveredLore: gameState.discoveredLore,
            upgradeLevels: gameState.upgradeLevels,
            totalStarsCollected: gameState.totalStarsCollected,
            soundEnabled: gameState.soundEnabled,
            musicEnabled: gameState.musicEnabled,
            resources: gameState.resources,
            discoveredPOIs: gameState.discoveredPOIs,
            completedPOIs: gameState.completedPOIs,
            bestCombo: gameState.bestCombo,
            totalVolatilesCollected: gameState.totalVolatilesCollected,
            completedConstellations: gameState.completedConstellations,
            memoryAnchors: gameState.memoryAnchors,
            directiveIndex: gameState.directiveIndex,
            directiveComplete: gameState.directiveComplete,
            highScore: gameState.highScore > 0 ? gameState.highScore : nil
        )
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: saveKey)
        } catch {
            print("Failed to save game: \(error)")
        }
    }

    static func load() -> SaveData? {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return nil }
        do {
            return try JSONDecoder().decode(SaveData.self, from: data)
        } catch {
            print("Failed to load game: \(error)")
            return nil
        }
    }

    static func deleteSave() {
        UserDefaults.standard.removeObject(forKey: saveKey)
    }
}
