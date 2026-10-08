import Foundation
import SpriteKit

/// GHOST SIGNAL DECAY - TIMED DISAPPEARANCE OF UNDETECTED POIS.
/// When the scanner detects a signal but the player doesn't follow it,
/// that opportunity slowly fades away. It may completely vanish after enough time.
/// This creates natural urgency without punishing players harshly—they just need to act.

class GhostSignalDecay {
    static let shared = GhostSignalDecay()
    
    private var gameState: GameState { GameState.shared }
    private var poisToTrack: [(poi: POI, detectedAt: Date)] = []
    
    /// Start tracking a POI for potential decay (called when scanner detects it)
    func startTracking(_ poi: POI) {
        let now = Date()
        
        // Calculate how long this POI has been waiting based on save data if available, else fresh start
        var lastDetected: Date?
        
        poisToTrack.removeAll()
        for tracked in poisToTrack {
            if tracked.poi.id == poi.id {
                lastDetected = tracked.detectedAt
            }
        }
        poisToTrack.append((poi, lastDetected ?? now))
    }
    
    /// Get remaining fade time for an POI (how much more it has to wait before disappearing)
    func getRemainingDecayTime(for poi: POI) -> Double {
        guard let tracking = poisToTrack.first(where: { $0.poi.id == poi.id }) else { return 0.0 }
        
        let elapsedSeconds = Date().timeIntervalSince(tracking.detectedAt)
        
        // Only begin decay after ghostDecayStartTime (default 5 minutes)
        if elapsedSeconds < EnhancementConfig.ghostDecayStartTime {
            return max(0, EnhancementConfig.ghostDecayStartTime - elapsedSeconds)
        } else {
            // Decay from start of actual fadeout period over default duration
            let fadedTime = elapsedSeconds - EnhancementConfig.ghostDecayStartTime
            return max(0, EnhancementConfig.ghostDecayDuration - (fadedTime / 60.0) * EnhancementConfig.ghostDecayDuration)
        }
    }
}
