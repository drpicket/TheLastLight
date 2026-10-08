import Foundation
import SpriteKit

/// SIGNAL ECHO RISK ACCUMULATION - TENSION SYSTEM BASED ON DISCOVERIES.
/// As players interact with POIs and uncover lore, the universe itself begins to fade.
/// Risk accumulates through discoveries, dissipates slowly in "safe" moments.
/// At risk thresholds, visual distortions intensify: vignette darkening, color shifts, audio warping.
/// A tension/relief mechanic that creates natural pacing for discovery events.

class RiskAccrualSystem {
    static let shared = RiskAccrualSystem()
    
    private var instance: GameState
    
    /// Create a singleton tracking risk by game session state
    init(instance: GameState) {
        self.instance = instance
        
        // Subscribe to notifications when discoveries occur
        NotificationCenter.default.addObserver(
            forName: .discoveryStarted, object: nil, queue: mainQueue
        ) { [weak self] _ in
            self?.trackDiscovery()
        }
    }
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Current risk level (0.0 to 1.0) - 0 = no distortions, 1 = full chaos
    var currentRisk: Double {
        return min(instance.currentRisk, 1.0)
    }
    
    /// Track a new discovery event (adds to tension if applicable)
    private func trackDiscovery() {
        let newRisk = instance.currentRisk + EnhancementConfig.riskPerDiscovery
        
        // Check if we've exceeded threshold for overage multiplier
        if newRisk > EnhancementConfig.riskThreshold {
            let overage = max(0, instance.currentRisk - EnhancementConfig.riskThreshold) * EnhancementConfig.riskOverageMultiplier
            
            if instance.currentRisk < 1.0 {
                instance.currentRisk = min(1.0, EnhancementConfig.riskThreshold + overage)
            }
        } else {
            instance.currentRisk += EnhancementConfig.riskPerDiscovery
        }
    }
}

/// Notification names for new mechanics

let discoveryStarted = NSNotification.Name("discoveryStarted")
