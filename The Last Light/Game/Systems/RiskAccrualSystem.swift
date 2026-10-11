import Foundation
import SpriteKit

/// SIGNAL ECHO RISK ACCUMULATION - TENSION SYSTEM BASED ON DISCOVERIES.
class RiskAccrualSystem {
    static let shared = RiskAccrualSystem()
    private init() {
        NotificationCenter.default.addObserver(
            forName: .discoveryStarted, object: nil, queue: .main
        ) { [weak self] _ in
            self?.trackDiscovery()
        }
    }

    var currentRisk: Double {
        min(GameState.shared.currentRisk, 1.0)
    }

    /// Applies one discovery's worth of risk.
    ///
    /// Below the threshold risk accrues linearly. Once the threshold is crossed the
    /// *post-increment* overage is amplified, so late discoveries bite much harder.
    /// Measuring overage from the pre-increment value would pin risk at the threshold.
    func trackDiscovery() {
        let gs = GameState.shared
        let newRisk = gs.currentRisk + EnhancementConfig.riskPerDiscovery
        if newRisk > EnhancementConfig.riskThreshold {
            let overage = (newRisk - EnhancementConfig.riskThreshold) * EnhancementConfig.riskOverageMultiplier
            gs.currentRisk = min(1.0, EnhancementConfig.riskThreshold + overage)
        } else {
            gs.currentRisk = newRisk
        }
    }

    func decay(deltaTime: Double) {
        GameState.shared.ventRisk(EnhancementConfig.riskDecayPerSecond * deltaTime)
    }
}
