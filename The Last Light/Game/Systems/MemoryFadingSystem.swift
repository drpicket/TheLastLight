import Foundation

/// MEMORY FADE MECHANIC - VISUAL AND AUDIO "FORGETTING."
/// As Signal Echo risk increases, some discoveries visually fade from player memory.
/// The universe itself is forgetting what the player has found.
/// Players must decide: do I want to remember this discovery enough to invest time?
/// Risk resets in safe regions, and memory anchor saves preserve important lore permanently.

class MemoryFadingSystem {
    static let shared = MemoryFadingSystem()
    
    private var gameState: GameState { GameState.shared }
    private var fadingDiscoveries: [(discovery: Discovery, lastChecked: Date)] = []
    
    /// How many discoveries should be checked for memory fade (don't track all in production)
    private let maxTrackable = 20
    
    /// Calculate how much a specific lore entry's visual memory should fade based on current risk
    func getMemoryFadeAmount(for loreId: String, currentRisk: Double) -> Double {
        // Low risk = almost no fading
        if currentRisk < EnhancementConfig.riskThreshold {
            return max(0.0, (currentRisk - EnhancementConfig.riskThreshold) * 2.0)
        } else {
            // Higher rates at elevated risk
            return min(1.0, currentRisk * 3.0)
        }
    }
    
    /// Get how many lore entries should visually fade due to accumulated risk
    func getFadingEntries(currentRisk: Double) -> [(loreId: String, fadeLevel: Double)] {
        if currentRisk < EnhancementConfig.riskThreshold {
            return [] // No fading below threshold
        }
        
        let entries = LoreSystem.allEntries
        var result: [(loreId: String, fadeLevel: Double)] = []
        
        for entry in entries {
            if !gameState.discoveredLore.contains(entry.id) {
                continue // Not discovered yet
            }
            
            let fade = getMemoryFadeAmount(for: entry.id, currentRisk: currentRisk)
            result.append((entry.id, fade))
        }
        
        return result.sorted { $0.fadeLevel > $1.fadeLevel }
    }
    
    /// Check which discoveries should fade and update their visual state (used by UI system)
    func checkMemoryFades(currentRisk: Double) -> [String] {
        guard currentRisk >= EnhancementConfig.riskThreshold else { return [] }
        
        let toFade = getFadingEntries(currentRisk: currentRisk).filter { $0.fadeLevel > 0.3 }
        return toFade.map { $0.loreId }
    }
    
    /// Get fade level for a specific discovered entry
    func getFadeLevel(for loreId: String, using risk: Double) -> Double {
        if !gameState.discoveredLore.contains(loreId) { return 0.0 }
        let entries = LoreSystem.allEntries
        guard let entry = entries.first(where: { $0.id == loreId }) else { return 0.0 }
        return getMemoryFadeAmount(for: entry.id, currentRisk: risk)
    }
    
    /// Track a POI interaction for memory purposes
    func trackPOIInteraction(_ poi: POI) {
        // This will cause "risk echo" from this discovery
        var updated = false
        
        if gameState.riskChanged != nil {
            RiskAccrualSystem.shared.trackDiscovery(poi, type: poi.type)
            updated = true
        }
    }
}
