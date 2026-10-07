import Foundation
import SpriteKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum StarType: String, Codable, CaseIterable {
    case small
    case blue
    case golden
    case ancient
    
    var energyValue: Int {
        switch self {
        case .small: return 1
        case .blue: return 5
        case .golden: return 15
        case .ancient: return 50
        }
    }
    
    var displayName: String {
        switch self {
        case .small: return "Star Fragment"
        case .blue: return "Blue Star"
        case .golden: return "Golden Star"
        case .ancient: return "Ancient Star"
        }
    }
    
    var size: CGFloat {
        switch self {
        case .small: return 12
        case .blue: return 18
        case .golden: return 24
        case .ancient: return 32
        }
    }
    
    var color: SKColor {
        switch self {
        case .small: return SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1.0)
        case .blue: return SKColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
        case .golden: return SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        case .ancient: return SKColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 1.0)
        }
    }
    
    var glowColor: SKColor {
        switch self {
        case .small: return SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 0.6)
        case .blue: return SKColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 0.6)
        case .golden: return SKColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 0.6)
        case .ancient: return SKColor(red: 0.6, green: 0.2, blue: 1.0, alpha: 0.6)
        }
    }
    
    var particleColor: SKColor {
        switch self {
        case .small: return SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.8)
        case .blue: return SKColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 0.8)
        case .golden: return SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.8)
        case .ancient: return SKColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 0.8)
        }
    }
    
    var collectSound: String {
        switch self {
        case .small: return "collect"
        case .blue: return "collectBlue"
        case .golden: return "collectGolden"
        case .ancient: return "collectAncient"
        }
    }
    
    var canTriggerLore: Bool {
        switch self {
        case .ancient: return true
        default: return false
        }
    }
}

class StarNode: SKSpriteNode {
    let starType: StarType
    private var glowNode: SKShapeNode?
    
    init(type: StarType) {
        self.starType = type
        let texture = StarNode.createStarTexture(size: type.size, color: type.color)
        super.init(texture: texture, color: .clear, size: CGSize(width: type.size, height: type.size))
        setupGlow()
        setupPhysics()
        startFloatingAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func createStarTexture(size: CGFloat, color: SKColor) -> SKTexture {
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size * 2, height: size * 2))
        let image = renderer.image { context in
            let cgContext = context.cgContext
            let center = CGPoint(x: size, y: size)
            
            let glowGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [color.withAlphaComponent(0.3).cgColor, color.withAlphaComponent(0.0).cgColor] as CFArray,
                locations: [0.0, 1.0]
            )
            if let gradient = glowGradient {
                cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: size,
                    options: .drawsBeforeStartLocation
                )
            }
            
            let coreGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [SKColor.white.cgColor, color.cgColor] as CFArray,
                locations: [0.0, 1.0]
            )
            if let gradient = coreGradient {
                cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: size * 0.5,
                    options: .drawsBeforeStartLocation
                )
            }
        }
        return SKTexture(image: image)
        #elseif canImport(AppKit)
        let image = NSImage(size: CGSize(width: size * 2, height: size * 2))
        image.lockFocus()
        let center = CGPoint(x: size, y: size)
        
        let glowGradient = NSGradient(colors: [
            color.withAlphaComponent(0.3),
            color.withAlphaComponent(0.0)
        ])
        if let gradient = glowGradient {
            gradient.draw(fromCenter: center, radius: 0, toCenter: center, radius: size)
        }
        
        let coreGradient = NSGradient(colors: [
            SKColor.white,
            color
        ])
        if let gradient = coreGradient {
            gradient.draw(fromCenter: center, radius: 0, toCenter: center, radius: size * 0.5)
        }
        
        image.unlockFocus()
        return SKTexture(image: image)
        #endif
    }
    
    private func setupGlow() {
        let glow = SKShapeNode(circleOfRadius: starType.size)
        glow.fillColor = starType.glowColor
        glow.strokeColor = .clear
        glow.alpha = 0.3
        glow.blendMode = .add
        glowNode = glow
        addChild(glow)
    }
    
    private func setupPhysics() {
        physicsBody = SKPhysicsBody(circleOfRadius: starType.size / 2)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = PhysicsCategory.star
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = 0
    }
    
    private func startFloatingAnimation() {
        let pulseIn = SKAction.scale(to: 1.2, duration: 1.0)
        let pulseOut = SKAction.scale(to: 0.8, duration: 1.0)
        let pulseSequence = SKAction.sequence([pulseIn, pulseOut])
        let pulseLoop = SKAction.repeatForever(pulseSequence)
        glowNode?.run(pulseLoop)
        
        let floatUp = SKAction.moveBy(x: 0, y: 5, duration: 2.0)
        let floatDown = SKAction.moveBy(x: 0, y: -5, duration: 2.0)
        let floatSequence = SKAction.sequence([floatUp, floatDown])
        let floatLoop = SKAction.repeatForever(floatSequence)
        run(floatLoop)
    }
    
    func collect() {
        removeAllActions()
        glowNode?.removeAllActions()
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([scaleUp, fadeOut, remove])
        
        run(sequence)
        glowNode?.run(sequence)
    }
}

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0x1 << 0
    static let star: UInt32 = 0x1 << 1
    static let asteroid: UInt32 = 0x1 << 2
    static let boundary: UInt32 = 0x1 << 3
}
