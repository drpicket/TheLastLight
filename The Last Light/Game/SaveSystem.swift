import Foundation

struct SaveSystem {
    private static let saveKey = "StarfallSaveData"
    
    struct SaveData: Codable {
        var starEnergy: Int
        var currentRegion: Region
        var unlockedRegions: Set<Region>
        var discoveredLore: Set<String>
        var upgradeLevels: [UpgradeType: Int]
        var totalStarsCollected: Int
        var soundEnabled: Bool
        var musicEnabled: Bool
        
        // New systems
        // Optional so saves written by 1.0 (before POIs existed) still decode.
        var resources: [ResourceType: Int]?
        var discoveredPOIs: Set<String>?
        var completedPOIs: Set<String>?
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
            completedPOIs: gameState.completedPOIs
        )
        
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(data)
            UserDefaults.standard.set(encoded, forKey: saveKey)
        } catch {
            print("Failed to save game: \(error)")
        }
    }
    
    static func load() -> SaveData? {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(SaveData.self, from: data)
        } catch {
            print("Failed to load game: \(error)")
            return nil
        }
    }
    
    static func deleteSave() {
        UserDefaults.standard.removeObject(forKey: saveKey)
    }
}
