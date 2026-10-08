import Foundation
import SpriteKit

/// Manages discovery events and story moments.
/// Discoveries happen during gameplay, not in a separate archive.
class DiscoveryManager {
    static let shared = DiscoveryManager()
    
    private var gameState: GameState { GameState.shared }
    private var discoveries: [Discovery] = []
    private var activeDiscovery: Discovery?
    
    var onDiscoveryStarted: ((Discovery) -> Void)?
    var onDiscoveryCompleted: ((Discovery) -> Void)?
    
    private init() {}
    
    /// Create a discovery for a POI
    func createDiscovery(for poi: POI) -> Discovery {
        if let existing = discoveries.first(where: { $0.poiId == poi.id }) {
            return existing
        }
        let moment = poi.loreEntryId.flatMap { StoryMoment.byLoreID[$0] }
        let discovery = Discovery(
            id: poi.id,
            poiId: poi.id,
            title: LoreSystem.entry(withId: poi.loreEntryId ?? "")?.title ?? poi.displayName,
            type: poi.type,
            lines: moment?.lines ?? ["\(poi.displayName) located. Instruments record an unfamiliar signature."],
            question: moment?.question,
            isCompleted: false
        )
        discoveries.append(discovery)
        return discovery
    }
    
    /// Start a discovery event
    func startDiscovery(_ discovery: Discovery) {
        guard activeDiscovery == nil, !discovery.isCompleted else { return }
        activeDiscovery = discovery
        gameState.activeDiscovery = discovery
        onDiscoveryStarted?(discovery)
    }

    /// The POI manager is the sole owner of rewards and completion persistence.
    func completeDiscovery(_ discovery: Discovery) {
        guard activeDiscovery?.id == discovery.id,
              let poi = POIManager.shared.getPOI(by: discovery.poiId),
              !poi.isCompleted else { return }
        POIManager.shared.completePOI(poi)
        guard poi.isCompleted else { return }
        if let index = discoveries.firstIndex(where: { $0.id == discovery.id }) {
            discoveries[index].isCompleted = true
        }
        activeDiscovery = nil
        gameState.activeDiscovery = nil
        onDiscoveryCompleted?(discovery)
    }
    
    /// Get all discoveries
    func getDiscoveries() -> [Discovery] {
        return discoveries
    }
    
    /// Get completed discoveries
    func getCompletedDiscoveries() -> [Discovery] {
        return discoveries.filter { $0.isCompleted }
    }
    
    /// Get active discovery
    func getActiveDiscovery() -> Discovery? {
        return activeDiscovery
    }
    
    /// Check if there's an active discovery
    func hasActiveDiscovery() -> Bool {
        return activeDiscovery != nil
    }
    
    /// Clear all discoveries
    func clear() {
        discoveries.removeAll()
        activeDiscovery = nil
        gameState.activeDiscovery = nil
    }
}

/// Represents a discovery event in the game.
struct Discovery: Identifiable, Codable {
    let id: String
    let poiId: String
    let title: String
    let type: POIType
    let lines: [String]
    let question: String?
    var isCompleted: Bool
    var discoveredAt: Date = Date()
    
    var icon: String {
        return type.icon
    }
    
    var riskLevel: RiskLevel {
        return type.riskLevel
    }
}
