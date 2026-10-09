import Foundation
import SpriteKit

/// VISUAL MANIFESTATION OF RISK - pure functions + overlay factory.
/// Callers add/remove the returned node; this class never touches a scene directly.
class VisualDistortionSystem {
    static let shared = VisualDistortionSystem()
    private init() {}

    func generateColorShift(amount: Double) -> SKColor {
        let a = min(max(amount, 0), 1.0)
        if a < 0.5 {
            return SKColor(red: 0.2 + (a * 0.3), green: 0.6, blue: 0.8, alpha: 0.10 + a * 0.1)
        } else if a < 0.75 {
            return SKColor(red: 0.35, green: 0.4, blue: 0.9, alpha: 0.18)
        } else {
            return SKColor(red: 0.45, green: 0.1, blue: 0.85, alpha: 0.28)
        }
    }

    func generateVignetteIntensity(amount: Double) -> CGFloat {
        if amount < 0.5 { return -0.5 - (amount * 3.0) }
        return min(-1.0, -0.5 - (amount * 6.0))
    }

    /// Full-screen translucent overlay sized by caller.
    func makeOverlay(size: CGSize, risk: Double) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size)
        node.fillColor = generateColorShift(amount: risk)
        node.strokeColor = .clear
        node.zPosition = 90
        node.name = "riskOverlay"
        return node
    }

    var effectiveIntensity: Double {
        let base = GameState.shared.riskLevel * 5.0
        if base > EnhancementConfig.riskThreshold * 2 {
            return min(10.0, (base - EnhancementConfig.riskThreshold) * EnhancementConfig.riskOverageMultiplier)
        }
        return base
    }
}
