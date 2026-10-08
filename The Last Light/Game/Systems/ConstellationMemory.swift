import Foundation
import SpriteKit

/// CONSTELLATION MEMORY - COLLECTED STARS FORM PATTERN RECOGNITION.
/// As players collect stars, they arrange themselves into constellations in space.
/// Certain star combinations form recognizable patterns (triangles, lines, circles)
/// that hint at lore about the Astrals or reveal hidden knowledge.
/// Players must recognize these visually without text prompts—the game rewards observation.

class ConstellationMemory {
    static let shared = ConstellationMemory()
    
    private var gameState: GameState { GameState.shared }
    private var collectedStarPositions: [CGPoint: StarType] = [:]
    private var discoveredConstellations: [String: String] = [:] // "patternName: loreHint"
    private var patternCache: [(points: [CGPoint], type: ConstellationPattern)?] = []
    
    /// Get total collected stars
    var collectedCount: Int {
        return gameState.totalStarsCollected
    }
    
    /// Check if player has collected enough stars to begin tracking constellations
    func isAtConstellationThreshold() -> Bool {
        return collectedCount >= EnhancementConfig.constellationThreshold
    }
    
    /// Track a new star collection (must call this after successful collection)
    func trackStarCollection(position: CGPoint, type: StarType) {
        if gameState.totalStarsCollected < EnhancementConfig.constellationThreshold {
            // Not enough stars yet to find patterns
            return
        }
        
        collectedStarPositions[position] = type
        
        // Check for constellation matches
        discoverPatterns()
    }
    
    /// Remove a star from tracking (if it decayed or was collected in another region)
    func removeStar(from position: CGPoint) {
        collectedStarPositions.removeValue(forKey: position)
    }
}
