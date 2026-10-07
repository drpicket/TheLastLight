import Foundation
import SpriteKit

/// Manages the lifecycle of Points of Interest in the game world.
/// Handles spawning, discovery, interaction, and completion of POIs.
class POIManager {
    static let shared = POIManager()
    
    private var pois: [POI] = []
    private var gameState: GameState { GameState.shared }
    
    private init() {}
    
    /// Fixed locations and types let a pilot return to the same investigation after leaving the game.
    /// The first few contacts are deliberately close enough to appear in the initial scan.
    func generatePOIs(for region: Region, around center: CGPoint, radius: CGFloat) {
        let types: [POIType]
        switch region {
        case .silentBelt:
            types = [.stellarFragment, .abandonedProbe, .unknownSignal, .stellarFragment,
                     .anomaly, .derelictShip, .hiddenObject, .unknownSignal]
        case .shatteredNebula:
            types = [.stellarFragment, .unknownSignal, .abandonedProbe, .anomaly,
                     .ancientStructure, .stellarFragment, .hiddenObject, .derelictShip]
        case .forgottenOrbit:
            types = [.abandonedProbe, .unknownSignal, .stellarFragment, .ancientStructure,
                     .derelictShip, .anomaly, .hiddenObject, .regionGateway]
        case .blackExpanse:
            types = [.unknownSignal, .stellarFragment, .anomaly, .ancientStructure,
                     .hiddenObject, .derelictShip, .abandonedProbe, .regionGateway]
        case .heart:
            types = [.unknownSignal, .ancientStructure, .stellarFragment, .hiddenObject,
                     .regionGateway, .anomaly, .abandonedProbe, .derelictShip]
        }

        let locations: [CGPoint] = [
            CGPoint(x: 150, y: 35), CGPoint(x: -190, y: 115),
            CGPoint(x: 60, y: 275), CGPoint(x: 310, y: -160),
            CGPoint(x: -380, y: -220), CGPoint(x: 510, y: 280),
            CGPoint(x: -590, y: 390), CGPoint(x: 150, y: -640)
        ]
        pois = zip(types, locations).enumerated().map { index, contact in
            let id = "\(region.rawValue)_poi_\(index)"
            let scale = min(1, max(radius, 1) / 800)
            let position = CGPoint(x: center.x + contact.1.x * scale,
                                   y: center.y + contact.1.y * scale)
            let poi = createPOI(id: id, type: contact.0, position: position, region: region)
            poi.isDiscovered = gameState.discoveredPOIs.contains(id)
            poi.isCompleted = gameState.completedPOIs.contains(id)
            return poi
        }
    }

    private func createPOI(id: String, type: POIType, position: CGPoint, region: Region) -> POI {
        var rewardResources: [ResourceType: Int] = [:]
        var loreEntryId: String? = nil
        var requiredUpgrade: UpgradeType? = nil
        var signalStrength: Double? = nil
        
        switch type {
        case .stellarFragment:
            rewardResources = [.energy: Int.random(in: 5...15), .fragments: Int.random(in: 1...3)]
        case .unknownSignal:
            rewardResources = [.signal: Int.random(in: 10...25)]
            signalStrength = Double.random(in: 0.3...0.9)
            loreEntryId = region.loreEntryIds.randomElement()
        case .abandonedProbe:
            rewardResources = [.fragments: Int.random(in: 3...8), .signal: Int.random(in: 5...15)]
            loreEntryId = region.loreEntryIds.randomElement()
        case .anomaly:
            rewardResources = [.energy: Int.random(in: 15...30), .fragments: Int.random(in: 5...10)]
            requiredUpgrade = .gravityDrive
            signalStrength = Double.random(in: 0.6...1.0)
        case .derelictShip:
            rewardResources = [.fragments: Int.random(in: 8...15), .signal: Int.random(in: 10...20)]
            loreEntryId = region.loreEntryIds.randomElement()
        case .ancientStructure:
            rewardResources = [.signal: Int.random(in: 20...40), .fragments: Int.random(in: 10...20)]
            loreEntryId = region.loreEntryIds.randomElement()
            requiredUpgrade = .signalDecoder
        case .hiddenObject:
            rewardResources = [.energy: Int.random(in: 20...40), .fragments: Int.random(in: 10...20), .signal: Int.random(in: 15...30)]
            requiredUpgrade = .pulseScanner
        case .regionGateway:
            rewardResources = [.energy: 50]
        }
        
        return POI(
            id: id,
            type: type,
            position: position,
            signalStrength: signalStrength,
            loreEntryId: loreEntryId,
            rewardResources: rewardResources,
            requiredUpgrade: requiredUpgrade
        )
    }
    
    /// Get all POIs
    func getAllPOIs() -> [POI] {
        return pois
    }
    
    /// Get discovered POIs
    func getDiscoveredPOIs() -> [POI] {
        return pois.filter { $0.isDiscovered }
    }
    
    /// Get completed POIs
    func getCompletedPOIs() -> [POI] {
        return pois.filter { $0.isCompleted }
    }
    
    /// Get nearby POIs within a distance
    func getNearbyPOIs(from position: CGPoint, within distance: CGFloat) -> [POI] {
        return pois.filter { poi in
            let dx = poi.position.x - position.x
            let dy = poi.position.y - position.y
            let dist = sqrt(dx * dx + dy * dy)
            return dist <= distance
        }
    }
    
    /// Discover a POI
    func discoverPOI(_ poi: POI) {
        guard let stored = getPOI(by: poi.id), !stored.isDiscovered else { return }
        stored.isDiscovered = true
        gameState.discoverPOI(stored)
    }

    /// Complete a POI at most once, including across scene reloads.
    func completePOI(_ poi: POI) {
        guard let stored = getPOI(by: poi.id), stored.isDiscovered,
              !stored.isCompleted, stored.canInteract else { return }
        stored.isCompleted = true
        gameState.completePOI(stored)
        for (resource, amount) in stored.rewardResources {
            gameState.addResource(resource, amount: amount)
        }
        if let loreId = stored.loreEntryId {
            gameState.discoverLore(loreId)
        }
    }
    
    /// Get POI by ID
    func getPOI(by id: String) -> POI? {
        return pois.first { $0.id == id }
    }
    
    /// Clear all POIs
    func clear() {
        pois.removeAll()
    }
}
