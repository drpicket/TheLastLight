import Foundation

/// Manages the three core resources: Energy, Fragments, and Signal.
class ResourceManager {
    static let shared = ResourceManager()
    
    private var gameState: GameState { GameState.shared }
    
    private init() {}
    
    /// Add resources to the player's inventory
    func addResource(_ type: ResourceType, amount: Int) {
        gameState.addResource(type, amount: amount)
    }
    
    /// Remove resources from the player's inventory
    func removeResource(_ type: ResourceType, amount: Int) -> Bool {
        return gameState.removeResource(type, amount: amount)
    }
    
    /// Check if the player has enough resources
    func hasResource(_ type: ResourceType, amount: Int) -> Bool {
        return gameState.getResource(type) >= amount
    }
    
    /// Get the amount of a resource
    func getResource(_ type: ResourceType) -> Int {
        return gameState.getResource(type)
    }
    
    /// Get all resources
    func getAllResources() -> [ResourceType: Int] {
        return [
            .energy: gameState.getResource(.energy),
            .fragments: gameState.getResource(.fragments),
            .signal: gameState.getResource(.signal)
        ]
    }
}
