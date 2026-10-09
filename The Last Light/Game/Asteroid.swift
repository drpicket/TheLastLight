import Foundation
import SpriteKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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
        #if canImport(UIKit)
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
        #elseif canImport(AppKit)
        let image = NSImage(size: CGSize(width: size, height: size))
        image.lockFocus()
        let center = CGPoint(x: size / 2, y: size / 2)
        let radius = size / 2
        SKColor(red: 0.35, green: 0.3, blue: 0.25, alpha: 1.0).setFill()
        let path = NSBezierPath()
        let points = 8
        for i in 0..<points {
            let angle = Double(i) * 2 * Double.pi / Double(points)
            let r = radius * Double.random(in: 0.7...1.0)
            let p = CGPoint(x: center.x + CGFloat(cos(angle) * r), y: center.y + CGFloat(sin(angle) * r))
            if i == 0 { path.move(to: p) } else { path.line(to: p) }
        }
        path.close()
        path.fill()
        SKColor.black.withAlphaComponent(0.3).setFill()
        for _ in 0..<3 {
            let craterRadius = CGFloat.random(in: size/10...size/6)
            let p = CGPoint(x: center.x + CGFloat.random(in: -radius/3...radius/3),
                            y: center.y + CGFloat.random(in: -radius/3...radius/3))
            NSBezierPath(ovalIn: CGRect(x: p.x - craterRadius, y: p.y - craterRadius,
                                        width: craterRadius * 2, height: craterRadius * 2)).fill()
        }
        image.unlockFocus()
        return SKTexture(image: image)
        #endif
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

/// VOID STALKER - noise-hunting threat. Telegraphs, chases, loses interest when quiet.
class VoidStalkerNode: SKNode {
    enum State { case lurking, hunting, stunned }

    var state: State = .lurking
    var cruiseSpeed: CGFloat = EnhancementConfig.stalkerBaseSpeed
    var stunLeft: Double = 0
    var touchRadius: CGFloat = 34
    private var eye: SKShapeNode!
    private var ring: SKShapeNode!

    override init() {
        super.init()
        name = "voidStalker"
        eye = SKShapeNode(circleOfRadius: 14)
        eye.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.25, alpha: 0.95)
        eye.strokeColor = .clear
        eye.glowWidth = 8
        addChild(eye)
        ring = SKShapeNode(circleOfRadius: 26)
        ring.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.35, alpha: 0.6)
        ring.lineWidth = 2
        ring.fillColor = .clear
        addChild(ring)
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.6),
            SKAction.scale(to: 1.0, duration: 0.6)
        ])
        ring.run(SKAction.repeatForever(pulse))
        for i in 0..<3 {
            let wisp = SKShapeNode(circleOfRadius: 8 - CGFloat(i) * 2)
            wisp.fillColor = SKColor(red: 0.4, green: 0.05, blue: 0.15, alpha: 0.5)
            wisp.strokeColor = .clear
            wisp.position = CGPoint(x: -18 - CGFloat(i) * 10, y: 0)
            addChild(wisp)
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func stun(duration: Double) {
        state = .stunned
        stunLeft = duration
        eye.fillColor = SKColor.gray
    }

    @discardableResult
    func update(deltaTime: CGFloat, playerPos: CGPoint, aggression: Double) -> CGFloat {
        if stunLeft > 0 {
            stunLeft -= Double(deltaTime)
            if stunLeft <= 0 {
                state = .hunting
                eye.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.25, alpha: 0.95)
            }
            return hypot(position.x - playerPos.x, position.y - playerPos.y)
        }
        let dx = playerPos.x - position.x
        let dy = playerPos.y - position.y
        let dist = max(1, hypot(dx, dy))
        let huntSpeed = EnhancementConfig.stalkerHuntSpeed * CGFloat(0.8 + aggression * 0.4)
        let useSpeed = state == .hunting ? huntSpeed : cruiseSpeed
        position.x += dx / dist * useSpeed * deltaTime
        position.y += dy / dist * useSpeed * deltaTime
        zRotation = atan2(dy, dx)
        return dist
    }
}

/// GRAVITY VORTEX - physics hazard + slingshot opportunity.
class GravityVortexNode: SKNode {
    let strength: Double
    let outerRadius: CGFloat = 220
    let killRadius: CGFloat = 36
    let rimWidth: CGFloat = 60
    var slingshotCooldownUntil: TimeInterval = 0

    init(strength: Double) {
        self.strength = strength
        super.init()
        name = "gravityVortex"
        let core = SKShapeNode(circleOfRadius: 22)
        core.fillColor = SKColor(red: 0.5, green: 0.2, blue: 1.0, alpha: 0.9)
        core.strokeColor = SKColor(red: 0.8, green: 0.5, blue: 1.0, alpha: 1.0)
        core.lineWidth = 2
        core.glowWidth = 10
        addChild(core)
        for i in 1...3 {
            let ring = SKShapeNode(circleOfRadius: 40 + CGFloat(i) * 45)
            ring.strokeColor = SKColor(red: 0.6, green: 0.35, blue: 1.0, alpha: 0.5 - CGFloat(i) * 0.1)
            ring.lineWidth = 2
            ring.fillColor = .clear
            addChild(ring)
            let dir: CGFloat = i % 2 == 0 ? 1 : -1
            ring.run(SKAction.repeatForever(SKAction.rotate(byAngle: dir * CGFloat.pi * 2, duration: 6 + Double(i) * 3)))
        }
        core.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 4)))
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func pullVector(for shipPos: CGPoint, phased: Bool) -> CGVector {
        let dx = position.x - shipPos.x
        let dy = position.y - shipPos.y
        let dist = max(1, hypot(dx, dy))
        guard dist < outerRadius else { return .zero }
        var force = strength / Double(dist) * 60.0
        if phased { force *= 0.35 }
        if dist < killRadius { force *= 0.5 }
        return CGVector(dx: dx / dist * CGFloat(force), dy: dy / dist * CGFloat(force))
    }

    func isInRim(_ shipPos: CGPoint) -> Bool {
        let dist = hypot(position.x - shipPos.x, position.y - shipPos.y)
        return dist > killRadius + 20 && dist < killRadius + 20 + rimWidth + 60
    }
}
