import Foundation

/// MEMORY FADE MECHANIC - visual "forgetting" as risk rises.
/// Anchored lore never fades.
class MemoryFadingSystem {
    static let shared = MemoryFadingSystem()
    private init() {}

    func getMemoryFadeAmount(for loreId: String, currentRisk: Double) -> Double {
        if GameState.shared.memoryAnchors.contains(loreId) { return 0 }
        if currentRisk < EnhancementConfig.riskThreshold { return 0 }
        return min(1.0, (currentRisk - EnhancementConfig.riskThreshold) / (1.0 - EnhancementConfig.riskThreshold))
    }

    func getFadingEntries(currentRisk: Double) -> [(loreId: String, fadeLevel: Double)] {
        guard currentRisk >= EnhancementConfig.riskThreshold else { return [] }
        var result: [(loreId: String, fadeLevel: Double)] = []
        for entry in LoreSystem.allEntries where GameState.shared.discoveredLore.contains(entry.id) {
            let fade = getMemoryFadeAmount(for: entry.id, currentRisk: currentRisk)
            if fade > 0 { result.append((entry.id, fade)) }
        }
        return result.sorted { $0.fadeLevel > $1.fadeLevel }
    }

    func checkMemoryFades(currentRisk: Double) -> [String] {
        getFadingEntries(currentRisk: currentRisk).filter { $0.fadeLevel > 0.3 }.map { $0.loreId }
    }

    func getFadeLevel(for loreId: String, using risk: Double) -> Double {
        guard GameState.shared.discoveredLore.contains(loreId) else { return 0 }
        return getMemoryFadeAmount(for: loreId, currentRisk: risk)
    }

    func trackPOIInteraction(_ poi: POI) {
        GameState.shared.addRisk(EnhancementConfig.riskPerDiscovery * 0.25)
    }

    func anchor(loreId: String) {
        GameState.shared.memoryAnchors.insert(loreId)
        GameState.shared.saveGame()
    }
}
