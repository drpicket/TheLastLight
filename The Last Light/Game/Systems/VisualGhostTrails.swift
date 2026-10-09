import Foundation
import SpriteKit

/// VISUAL GHOST TRAILS - faint outlines of explored spots.
/// Scene-agnostic: caller passes the scene for addChild.
class VisualGhostTrails {
    static let shared = VisualGhostTrails()
    private init() {}

    private var trailNodes: [String: SKNode] = [:]
    private var positions: [String: CGPoint] = [:]

    func recordTrail(at position: CGPoint, in scene: SKNode?) {
        let nodeId = UUID().uuidString
        // Avoid stacking at same spot.
        for (_, p) in positions where hypot(p.x - position.x, p.y - position.y) < 20 {
            return
        }
        positions[nodeId] = position
        let ghostNode = SKShapeNode(circleOfRadius: 15.0)
        ghostNode.fillColor = SKColor.black.withAlphaComponent(0.25)
        ghostNode.strokeColor = SKColor.gray.withAlphaComponent(0.4)
        ghostNode.lineWidth = 1
        ghostNode.position = position
        ghostNode.zPosition = 5
        scene?.addChild(ghostNode)
        trailNodes[nodeId] = ghostNode
        DispatchQueue.main.asyncAfter(deadline: .now() + EnhancementConfig.ghostTrailDuration) { [weak self] in
            self?.removeTrail(for: nodeId)
        }
    }

    func removeTrail(for nodeId: String) {
        trailNodes[nodeId]?.removeFromParent()
        trailNodes.removeValue(forKey: nodeId)
        positions.removeValue(forKey: nodeId)
    }

    func clear() {
        for (_, n) in trailNodes { n.removeFromParent() }
        trailNodes.removeAll()
        positions.removeAll()
    }
}
