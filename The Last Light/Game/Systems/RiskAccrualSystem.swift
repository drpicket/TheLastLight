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

    func trackDiscovery() {
        let gs = GameState.shared
        let newRisk = gs.currentRisk + EnhancementConfig.riskPerDiscovery
        if newRisk > EnhancementConfig.riskThreshold {
            let overage = max(0, gs.currentRisk - EnhancementConfig.riskThreshold) * EnhancementConfig.riskOverageMultiplier
            gs.currentRisk = min(1.0, EnhancementConfig.riskThreshold + overage)
        } else {
            gs.currentRisk += EnhancementConfig.riskPerDiscovery
        }
    }

    func decay(deltaTime: Double) {
        GameState.shared.ventRisk(EnhancementConfig.riskDecayPerSecond * deltaTime)
    }
}
