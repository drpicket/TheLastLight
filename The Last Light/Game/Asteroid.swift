import Foundation
import SpriteKit

/// Represents an asteroid hazard in the game.
/// Asteroids drift through space and damage the player on contact.
class AsteroidNode: SKSpriteNode {
    private let rotationSpeed: CGFloat
    private let driftSpeed: CGFloat
    private let driftDirection: CGVector
    
    init(size: CGFloat, speedMultiplier: Double = 1.0) {
        self.rotationSpeed = CGFloat.random(in: -2.0...2.0)
        self.driftSpeed = CGFloat.random(in: 20...50) * CGFloat(speedMultiplier)
        self.driftDirection = CGVector(
            dx: CGFloat.random(in: -1...1),
            dy: CGFloat.random(in: -1...1)
        )
        
        let texture = AsteroidNode.createAsteroidTexture(size: size)
        super.init(texture: texture, color: .clear, size: CGSize(width: size, height: size))
        
        setupPhysics()
        startDrifting()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Create a procedural asteroid texture
    private static func createAsteroidTexture(size: CGFloat) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            let cgContext = context.cgContext
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2
            
            // Draw irregular asteroid shape
            let points = 8
            let angleStep = 2 * Double.pi / Double(points)
            
            cgContext.beginPath()
            for i in 0..<points {
                let angle = Double(i) * angleStep
                let variance = Double.random(in: 0.7...1.0)
                let r = radius * variance
                let x = center.x + CGFloat(cos(angle) * r)
                let y = center.y + CGFloat(sin(angle) * r)
                
                if i == 0 {
                    cgContext.move(to: CGPoint(x: x, y: y))
                } else {
                    cgContext.addLine(to: CGPoint(x: x, y: y))
                }
            }
            cgContext.closePath()
            
            // Fill with gradient
            let colors = [
                UIColor(red: 0.4, green: 0.35, blue: 0.3, alpha: 1.0).cgColor,
                UIColor(red: 0.2, green: 0.18, blue: 0.15, alpha: 1.0).cgColor
            ] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0])
            if let grad = gradient {
                cgContext.saveGState()
                cgContext.clip()
                cgContext.drawLinearGradient(
                    grad,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size, y: size),
                    options: []
                )
                cgContext.restoreGState()
            }
            
            // Add some crater details
            for _ in 0..<3 {
                let craterX = center.x + CGFloat.random(in: -radius/3...radius/3)
                let craterY = center.y + CGFloat.random(in: -radius/3...radius/3)
                let craterRadius = CGFloat.random(in: size/10...size/6)
                
                cgContext.setFillColor(UIColor.black.withAlphaComponent(0.3).cgColor)
                cgContext.fillEllipse(in: CGRect(
                    x: craterX - craterRadius,
                    y: craterY - craterRadius,
                    width: craterRadius * 2,
                    height: craterRadius * 2
                ))
            }
        }
        return SKTexture(image: image)
    }
    
    /// Setup physics body
    private func setupPhysics() {
        physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        physicsBody?.isDynamic = true
        physicsBody?.categoryBitMask = PhysicsCategory.asteroid
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = PhysicsCategory.boundary
        physicsBody?.restitution = 0.5
        physicsBody?.linearDamping = 0.1
    }
    
    /// Start drifting and rotating
    private func startDrifting() {
        // Apply initial velocity
        physicsBody?.velocity = CGVector(
            dx: driftDirection.dx * driftSpeed,
            dy: driftDirection.dy * driftSpeed
        )
        
        // Rotation animation
        let rotate = SKAction.rotate(byAngle: rotationSpeed * CGFloat.pi, duration: 1.0)
        let rotateLoop = SKAction.repeatForever(rotate)
        run(rotateLoop)
    }
    
    /// Called when the asteroid hits the player
    func onHit() {
        // Flash red
        let flash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.8, duration: 0.1),
            SKAction.colorize(with: .clear, colorBlendFactor: 0.0, duration: 0.1)
        ])
        run(flash)
    }
}
