import Foundation
import SpriteKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The player's spaceship. Handles movement, rotation, and visual effects.
class PlayerShip: SKSpriteNode {
    
    // MARK: - Properties
    
    private var targetPosition: CGPoint?
    private var currentVelocity: CGVector = .zero
    private var engineTrail: SKEmitterNode?
    private var shieldNode: SKSpriteNode?
    private var collectionRadiusNode: SKShapeNode?
    
    var maxSpeed: CGFloat = 200.0
    var acceleration: CGFloat = 400.0
    var turnRate: CGFloat = 3.0
    var collectionRadius: CGFloat = 50.0
    private var isThrusting = false
    
    // MARK: - Initialization
    
    init() {
        let texture = PlayerShip.createShipTexture()
        super.init(texture: texture, color: .clear, size: CGSize(width: 40, height: 40))
        setupPhysics()
        setupEngineTrail()
        setupShield()
        setupCollectionRadius()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private static func createShipTexture() -> SKTexture {
        #if canImport(UIKit)
        let size = CGSize(width: 40, height: 40)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            let center = CGPoint(x: 20, y: 20)
            
            cgContext.beginPath()
            cgContext.move(to: CGPoint(x: 35, y: 20))
            cgContext.addLine(to: CGPoint(x: 10, y: 8))
            cgContext.addLine(to: CGPoint(x: 15, y: 20))
            cgContext.addLine(to: CGPoint(x: 10, y: 32))
            cgContext.closePath()
            
            let colors = [
                SKColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0).cgColor,
                SKColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1.0).cgColor
            ] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0])
            if let grad = gradient {
                cgContext.saveGState()
                cgContext.clip()
                cgContext.drawLinearGradient(
                    grad,
                    start: CGPoint(x: 10, y: 8),
                    end: CGPoint(x: 35, y: 32),
                    options: []
                )
                cgContext.restoreGState()
            }
            
            cgContext.setFillColor(SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.9).cgColor)
            cgContext.fillEllipse(in: CGRect(x: 22, y: 16, width: 8, height: 8))
            
            cgContext.setFillColor(SKColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.8).cgColor)
            cgContext.fillEllipse(in: CGRect(x: 8, y: 17, width: 6, height: 6))
        }
        return SKTexture(image: image)
        #elseif canImport(AppKit)
        let size = CGSize(width: 40, height: 40)
        let image = NSImage(size: size)
        image.lockFocus()
        
        let center = CGPoint(x: 20, y: 20)
        let path = NSBezierPath()
        path.move(to: CGPoint(x: 35, y: 20))
        path.line(to: CGPoint(x: 10, y: 8))
        path.line(to: CGPoint(x: 15, y: 20))
        path.line(to: CGPoint(x: 10, y: 32))
        path.close()
        
        let colors = [
            SKColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0),
            SKColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1.0)
        ]
        if let gradient = NSGradient(colors: colors) {
            gradient.draw(in: path, angle: 45)
        }
        
        SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.9).setFill()
        let cockpitRect = CGRect(x: 22, y: 16, width: 8, height: 8)
        let cockpitPath = NSBezierPath(ovalIn: cockpitRect)
        cockpitPath.fill()
        
        SKColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.8).setFill()
        let engineRect = CGRect(x: 8, y: 17, width: 6, height: 6)
        let enginePath = NSBezierPath(ovalIn: engineRect)
        enginePath.fill()
        
        image.unlockFocus()
        return SKTexture(image: image)
        #endif
    }
    
    private func setupPhysics() {
        physicsBody = SKPhysicsBody(circleOfRadius: 15)
        physicsBody?.isDynamic = true
        physicsBody?.categoryBitMask = PhysicsCategory.player
        physicsBody?.contactTestBitMask = PhysicsCategory.star | PhysicsCategory.asteroid
        physicsBody?.collisionBitMask = PhysicsCategory.boundary
        physicsBody?.restitution = 0.3
        physicsBody?.linearDamping = 0.5
        physicsBody?.angularDamping = 0.5
    }
    
    private func setupEngineTrail() {
        engineTrail = SKEmitterNode()
        engineTrail?.particleTexture = createParticleTexture()
        engineTrail?.particleBirthRate = 50
        engineTrail?.particleLifetime = 0.5
        engineTrail?.particleLifetimeRange = 0.2
        engineTrail?.particlePositionRange = CGVector(dx: 5, dy: 5)
        engineTrail?.particleSpeed = 30
        engineTrail?.particleSpeedRange = 10
        engineTrail?.particleAlpha = 0.6
        engineTrail?.particleAlphaSpeed = -1.0
        engineTrail?.particleScale = 0.3
        engineTrail?.particleScaleSpeed = -0.5
        engineTrail?.particleColor = SKColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.8)
        engineTrail?.particleColorBlendFactor = 1.0
        engineTrail?.targetNode = self
        engineTrail?.position = CGPoint(x: -15, y: 0)
        engineTrail?.isPaused = true
        
        if let trail = engineTrail {
            addChild(trail)
        }
    }
    
    private func setupShield() {
        shieldNode = SKSpriteNode(color: SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.2), size: CGSize(width: 50, height: 50))
        shieldNode?.alpha = 0.0
        addChild(shieldNode!)
    }
    
    private func setupCollectionRadius() {
        collectionRadiusNode = SKShapeNode(circleOfRadius: collectionRadius)
        collectionRadiusNode?.strokeColor = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.1)
        collectionRadiusNode?.lineWidth = 1
        collectionRadiusNode?.fillColor = .clear
        collectionRadiusNode?.alpha = 0.0
        addChild(collectionRadiusNode!)
    }
    
    private func createParticleTexture() -> SKTexture {
        #if canImport(UIKit)
        let size = CGSize(width: 8, height: 8)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            let center = CGPoint(x: 4, y: 4)
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [SKColor.white.cgColor, SKColor.clear.cgColor] as CFArray,
                locations: [0.0, 1.0]
            )
            if let grad = gradient {
                cgContext.drawRadialGradient(
                    grad,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: 4,
                    options: .drawsBeforeStartLocation
                )
            }
        }
        return SKTexture(image: image)
        #elseif canImport(AppKit)
        let size = CGSize(width: 8, height: 8)
        let image = NSImage(size: size)
        image.lockFocus()
        let center = CGPoint(x: 4, y: 4)
        if let gradient = NSGradient(colors: [SKColor.white, SKColor.clear]) {
            gradient.draw(fromCenter: center, radius: 0, toCenter: center, radius: 4)
        }
        image.unlockFocus()
        return SKTexture(image: image)
        #endif
    }
    
    // MARK: - Movement
    
    func moveToward(_ point: CGPoint) {
        targetPosition = point
    }
    
    func stop() {
        targetPosition = nil
        isThrusting = false
        engineTrail?.isPaused = true
    }
    
    func update(deltaTime: TimeInterval) {
        guard let target = targetPosition else {
            let damping = 0.95
            physicsBody?.velocity = CGVector(
                dx: physicsBody!.velocity.dx * damping,
                dy: physicsBody!.velocity.dy * damping
            )
            return
        }
        
        let dx = target.x - position.x
        let dy = target.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance < 10 {
            stop()
            return
        }
        
        let direction = CGVector(dx: dx / distance, dy: dy / distance)
        let desiredVelocity = CGVector(
            dx: direction.dx * maxSpeed,
            dy: direction.dy * maxSpeed
        )
        
        let lerpFactor = CGFloat(min(1.0, acceleration * deltaTime / maxSpeed))
        let newVelocity = CGVector(
            dx: physicsBody!.velocity.dx + (desiredVelocity.dx - physicsBody!.velocity.dx) * lerpFactor,
            dy: physicsBody!.velocity.dy + (desiredVelocity.dy - physicsBody!.velocity.dy) * lerpFactor
        )
        physicsBody?.velocity = newVelocity
        
        let angle = atan2(newVelocity.dy, newVelocity.dx)
        let currentRotation = zRotation
        let angleDiff = angle - currentRotation
        
        var normalizedDiff = angleDiff
        while normalizedDiff > CGFloat.pi { normalizedDiff -= 2 * CGFloat.pi }
        while normalizedDiff < -CGFloat.pi { normalizedDiff += 2 * CGFloat.pi }
        
        let rotationStep = normalizedDiff * turnRate * CGFloat(deltaTime)
        zRotation += rotationStep
        
        if !isThrusting {
            isThrusting = true
            engineTrail?.isPaused = false
        }
    }
    
    // MARK: - Visual Effects
    
    func showShield() {
        shieldNode?.alpha = 0.5
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        shieldNode?.run(fadeOut)
    }
    
    func showCollectionRadius() {
        collectionRadiusNode?.alpha = 0.3
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        collectionRadiusNode?.run(fadeOut)
    }
    
    func flash() {
        let flashOn = SKAction.colorize(with: .red, colorBlendFactor: 0.8, duration: 0.1)
        let flashOff = SKAction.colorize(with: .clear, colorBlendFactor: 0.0, duration: 0.2)
        run(SKAction.sequence([flashOn, flashOff]))
    }
    
    func updateStats(_ stats: ShipStats) {
        maxSpeed = CGFloat(stats.speed)
        turnRate = CGFloat(stats.turnRate)
        collectionRadius = CGFloat(stats.collectionRadius)
        collectionRadiusNode?.removeFromParent()
        setupCollectionRadius()
    }
}
