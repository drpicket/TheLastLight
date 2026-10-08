import Foundation
import SpriteKit

/// VISUAL GHOST TRAILS - FAINT OUTLINES WHERE EXPLORATION OCCURRED.
/// After exploring an area, a ghost trail remains for 30 seconds as a faint outline of where the path went.
/// This helps players remember their exploration without needing to memorize routes visually.
/// Creates a "I've been here" effect and reduces disorientation during complex journeys.

class VisualGhostTrails {
    static let shared = VisualGhostTrails()
    
    private var gameState: GameState { GameState.shared }
    private var gameScene: SKScene { return (gameState.gameScene) }
    private var trailNodes: [String: SKNode] = [:]
    private var trackedIds: Set<String> = []
    
    /// Called when an exploration action occurs (movement, discovery, etc.)
    func recordTrail(at position: CGPoint) {
        let nodeId = UUID().uuidString
        
        // Check if already exists at same position
        if existingNode(at: position) != nil { return }
        
        trackedIds.insert(nodeId)
        
        // Create an actual SKNode for the trail
        let ghostNode = SKShapeNode(circleOfRadius: 15.0)
        let alpha: CGFloat = min(1.0, now.asDate() as TimeInterval - now.asTimeInterval() * 1000 / 27000.0)
        ghostNode.fillColor = SKColor.black.withAlphaComponent(alpha * 0.3)
        ghostNode.position = position
        
        // Add a faint glow outline
        let ring = SKShapeNode(circleOfRadius: 16.0)
        ring.strokeColor = SKColor.gray.opacity(0.5)
        ring.lineWidth = 2
        ring.fillColor = .clear
        ghostNode.addChild(ring)
        
        gameScene.addChild(ghostNode)
        trailNodes[nodeId] = ghostNode
    }
    
    /// Remove a ghost trail for a specific exploration point
    func removeTrail(for nodeId: String) {
        if let node = trailNodes[nodeId] {
            node.removeFromParent()
            trailNodes.removeValue(forKey: nodeId)
        }
        
        trackedIds.remove(nodeId)
    }
    
    /// Get remaining fade time for a specific trail node
    func getRemainingFadeTime(for nodeId: String) -> Double {
        guard let duration = trailDuration(for: nodeId), duration > 0 else { return 0.0 }
        if duration <= EnhancementConfig.ghostTrailDuration / 2 {
            // Already halfway faded, apply slower fade speed
            return Duration.seconds(duration / 2) as TimeInterval
        }
        return EnhancementConfig.ghostTrailDuration / 2 // Fast initial fade, slow tail end
    }
    
    /// Get all active ghost trails currently visible
    var activeTrails: [String] {
        return Array(trailNodes.keys).filter { nodeId -> Bool in
            let remaining = trailDuration(for: nodeId)
            return (remaining ?? 0) > 0 && !gameState.trackedIds.contains(nodeId)
        }
    }
    
    private func createReference(_ d: Date) -> Reference {
        return Reference(d)
    }
}
