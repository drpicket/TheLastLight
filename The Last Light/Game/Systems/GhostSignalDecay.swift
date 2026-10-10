import Foundation
import SpriteKit

/// GHOST SIGNAL DECAY - timed disappearance of storm/undetected POIs.
class GhostSignalDecay {
    static let shared = GhostSignalDecay()
    private init() {}

    private var tracked: [String: Date] = [:]
    /// Game-time fuses for storm POIs: freeze-safe, unlike wall-clock Dates.
    private var stormFuses: [String: Double] = [:]
    var onPOIExpired: ((String) -> Void)?

    func startTracking(_ poi: POI) {
        if tracked[poi.id] == nil { tracked[poi.id] = Date() }
        if poi.isStorm && stormFuses[poi.id] == nil {
            stormFuses[poi.id] = EnhancementConfig.stormDuration
        }
    }

    func stopTracking(_ poiId: String) {
        tracked.removeValue(forKey: poiId)
        stormFuses.removeValue(forKey: poiId)
    }
    func clear() {
        tracked.removeAll()
        stormFuses.removeAll()
    }

    func getRemainingDecayTime(for poi: POI) -> Double {
        guard let since = tracked[poi.id] else { return EnhancementConfig.ghostDecayDuration }
        let elapsed = Date().timeIntervalSince(since)
        if elapsed < EnhancementConfig.ghostDecayStartTime {
            return EnhancementConfig.ghostDecayStartTime - elapsed
        }
        let faded = elapsed - EnhancementConfig.ghostDecayStartTime
        return max(0, EnhancementConfig.ghostDecayDuration - faded)
    }

    /// Remaining fuse for storm POIs (short, urgent timers).
    /// Prefers the game-time fuse table so modals and pauses don't burn fuses.
    func getRemainingStormTime(for poiId: String, total: Double) -> Double {
        if let left = stormFuses[poiId] { return max(0, left) }
        guard let since = tracked[poiId] else { return total }
        return max(0, total - Date().timeIntervalSince(since))
    }

    /// Per-frame fuse burn. Pass frozen=true while a discovery modal is open.
    func tickStormFuses(deltaTime: Double, frozen: Bool) {
        guard !frozen else { return }
        for id in stormFuses.keys {
            stormFuses[id] = max(0, (stormFuses[id] ?? 0) - deltaTime)
        }
    }

    /// Called each frame; expires storm POIs whose fuse ran out.
    func updateStormPOIs(ids: [String], fuse: Double) -> [String] {
        var expired: [String] = []
        for id in ids {
            if getRemainingStormTime(for: id, total: fuse) <= 0 {
                expired.append(id)
                tracked.removeValue(forKey: id)
                stormFuses.removeValue(forKey: id)
            }
        }
        for id in expired { onPOIExpired?(id) }
        return expired
    }
}
