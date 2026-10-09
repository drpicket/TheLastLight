import Foundation
import SpriteKit

/// GHOST SIGNAL DECAY - timed disappearance of storm/undetected POIs.
class GhostSignalDecay {
    static let shared = GhostSignalDecay()
    private init() {}

    private var tracked: [String: Date] = [:]
    var onPOIExpired: ((String) -> Void)?

    func startTracking(_ poi: POI) {
        if tracked[poi.id] == nil { tracked[poi.id] = Date() }
    }

    func stopTracking(_ poiId: String) { tracked.removeValue(forKey: poiId) }
    func clear() { tracked.removeAll() }

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
    func getRemainingStormTime(for poiId: String, total: Double) -> Double {
        guard let since = tracked[poiId] else { return total }
        return max(0, total - Date().timeIntervalSince(since))
    }

    /// Called each frame; expires storm POIs whose fuse ran out.
    func updateStormPOIs(ids: [String], fuse: Double) -> [String] {
        var expired: [String] = []
        for id in ids {
            if getRemainingStormTime(for: id, total: fuse) <= 0 {
                expired.append(id)
                tracked.removeValue(forKey: id)
            }
        }
        for id in expired { onPOIExpired?(id) }
        return expired
    }
}
