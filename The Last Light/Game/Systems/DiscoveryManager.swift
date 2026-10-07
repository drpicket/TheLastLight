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
        let discovery = Discovery(
            id: UUID().uuidString,
            poiId: poi.id,
            title: poi.displayName,
            type: poi.type,
            isCompleted: false
        )
        discoveries.append(discovery)
        return discovery
    }
    
    /// Start a discovery event
    func startDiscovery(_ discovery: Discovery) {
        activeDiscovery = discovery
        onDiscoveryStarted?(discovery)
    }
    
    /// Complete a discovery
    func completeDiscovery(_ discovery: Discovery) {
        if let index = discoveries.firstIndex(where: { $0.id == discovery.id }) {
            discoveries[index].isCompleted = true
        }
        
        // Grant rewards
        if let poi = POIManager.shared.getPOI(by: discovery.poiId) {
            for (resource, amount) in poi.rewardResources {
                gameState.addResource(resource, amount: amount)
            }
            
            if let loreId = poi.loreEntryId {
                gameState.discoverLore(loreId)
            }
            
            POIManager.shared.completePOI(poi)
        }
        
        activeDiscovery = nil
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
    }
}

/// Represents a discovery event in the game.
struct Discovery: Identifiable, Codable {
    let id: String
    let poiId: String
    let title: String
    let type: POIType
    var isCompleted: Bool
    var discoveredAt: Date = Date()
    
    var icon: String {
        return type.icon
    }
    
    var riskLevel: RiskLevel {
        return type.riskLevel
    }
}
