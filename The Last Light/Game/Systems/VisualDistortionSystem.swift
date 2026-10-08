import Foundation
import SpriteKit

/// VISUAL MANIFESTATION OF SIGNAL ECHO RISK - A DYNAMIC FILTER SYSTEM.
/// As risk accumulates, the game world subtly distorts: colors shift, edges blur, vignette intensifies.
/// This creates an immersive sense that the universe itself is degrading as you uncover too much truth.

class VisualDistortionSystem {
    static let shared = VisualDistortionSystem()
    
    private var gameState: GameState { GameState.shared }
    private var distortionNode: SKShapeNode?
    private var currentIntensity: Double = 0.0
    
    /// Generate a color shift based on risk level (hue rotation in HSV space)
    func generateColorShift(amount: Double) -> SKColor {
        // Low to moderate amounts shift toward blue/purple tones
        let hue: CGFloat = min(1.0, amount * 0.8)
        
        if amount < 0.5 {
            // Subtle cyan-blue tint at low risk
            return SKColor(red: 0.2 + (amount * 0.3), green: 0.6 + (amount * 0.4), blue: 0.8 + (amount * 0.2), alpha: 1.0)
        } else if amount < 0.75 {
            // Purple-violet tint at moderate risk
            return SKColor(red: 0.1 + (hue * 0.3), green: 0.6 - (hue * 0.2), blue: 0.9, alpha: 1.0)
        } else {
            // Deep violet-black gradient at high risk
            let saturation = 1.0 - ((amount - 0.75) / 0.25)
            return SKColor(red: CGFloat.random(in: 0...0.02), green: 0, blue: 0.8 + (saturation * 0.1), alpha: 1.0)
        }
    }
    
    /// Generate intensity-based vignette (darkening edges of screen as risk increases)
    func generateVignetteIntensity(amount: Double) -> CGFloat {
        if amount < 0.5 {
            // Very subtle edge darkening at low risk
            return -0.5 - (amount * 3.0)
        } else {
            // More pronounced vignetting at moderate-to-high risk
            return min(-1.0, -0.5 - (amount * 6.0))
        }
    }
    
    /// Apply color filter to the entire game world as a node
    func applyFilter() {
        guard distortionNode == nil else { return }
        
        distortionNode = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height), edgeWidth: 1, antialiased: true)
        let color = generateColorShift(amount: gameState.riskLevel)
        distortionNode!.fillColor = color
        addChild(distortionNode!)
    }
    
    /// Remove the distortion node (restore normal viewing)
    func removeFilter() {
        distortionNode?.removeFromParent()
        distortionNode = nil
    }
    
    /// Get current intensity for UI adjustments based on active filter
    var effectiveIntensity: Double {
        let base = gameState.riskLevel * 5.0
        if base > EnhancementConfig.riskThreshold * 2 {
            return min(10.0, (base - EnhancementConfig.riskThreshold) * EnhancementConfig.riskOverageMultiplier)
        }
        return base
    }
}
