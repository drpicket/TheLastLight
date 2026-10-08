import Foundation
import SpriteKit
import SwiftUI

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var playerShip: PlayerShip!
    private var cameraNode: SKCameraNode!
    private var backgroundLayers: [SKNode] = []
    private var worldNode: SKNode!
    private var region: Region = .silentBelt
    private var isTouching = false
    private var lastTouchLocation: CGPoint?
    private var gameState: GameState { GameState.shared }
    private let worldSize: CGFloat = 5000
    private var starSpawnTimer: TimeInterval = 0
    private var asteroidSpawnTimer: TimeInterval = 0
    var onStarCollected: ((StarType) -> Void)?
    var onLoreDiscovered: ((LoreEntry) -> Void)?
    var onRegionUnlocked: ((Region) -> Void)?
    var onEnergyDepleted: (() -> Void)?
    private var isReady = false
    
    // POI system
    private var poiNodes: [String: SKNode] = [:]
    private let scannerSystem = ScannerSystem.shared
    private var waypointLabel: SKLabelNode?
    private var lastUpdateTime: TimeInterval?
    private var statusUpdateTimer: TimeInterval = 0
    private var wasUsingJoystick = false
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        if isReady {
            resumeScanner()
            AudioManager.shared.startAmbientMusic()
            return
        }
        region = gameState.currentRegion
        setupScene()
        setupCamera()
        setupBackground()
        setupWorld()
        setupPlayer()
        setupPhysics()
        setupPOIs()
        isReady = true
        
        // Start scanner
        scannerSystem.onScanComplete = { [weak self] pois in
            self?.handleScanResults(pois)
        }
        scannerSystem.onPOIDiscovered = { [weak self] poi in
            self?.handlePOIDiscovered(poi)
        }
        resumeScanner()

        AudioManager.shared.startAmbientMusic()
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        scannerSystem.stopScanning()
        AudioManager.shared.stopAmbientMusic()
    }
    
    func resumeScanner() {
        guard isReady, view != nil else { return }
        isPaused = false
        lastUpdateTime = nil
        scannerSystem.startScanning()
        scannerSystem.scan(playerPosition: playerShip.position)
    }

    private func setupScene() {
        backgroundColor = SKColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1.0)
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }
    
    private func setupCamera() {
        cameraNode = SKCameraNode()
        cameraNode.setScale(1.0)
        addChild(cameraNode)
        camera = cameraNode

        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.fontSize = 13
        label.fontColor = .cyan
        label.zPosition = 100
        label.isHidden = true
        cameraNode.addChild(label)
        waypointLabel = label
    }
    
    private func setupBackground() {
        for i in 0..<3 {
            let layer = SKNode()
            layer.name = "background_\(i)"
            let starCount = 100 - i * 20
            for _ in 0..<starCount {
                let star = createBackgroundStar(layer: i)
                layer.addChild(star)
            }
            addChild(layer)
            backgroundLayers.append(layer)
        }
    }
    
    private func createBackgroundStar(layer: Int) -> SKSpriteNode {
        let size = CGFloat.random(in: 1...3) * CGFloat(3 - layer) * 0.5
        let star = SKSpriteNode(color: .white, size: CGSize(width: size, height: size))
        star.position = CGPoint(
            x: CGFloat.random(in: -worldSize/2...worldSize/2),
            y: CGFloat.random(in: -worldSize/2...worldSize/2)
        )
        star.alpha = CGFloat.random(in: 0.3...0.8) * CGFloat(3 - layer) / 3.0
        let twinkleDuration = CGFloat.random(in: 2...5)
        let twinkleIn = SKAction.fadeAlpha(to: star.alpha * 0.5, duration: twinkleDuration)
        let twinkleOut = SKAction.fadeAlpha(to: star.alpha, duration: twinkleDuration)
        let twinkle = SKAction.sequence([twinkleIn, twinkleOut])
        star.run(SKAction.repeatForever(twinkle))
        return star
    }
    
    private func setupWorld() {
        worldNode = SKNode()
        worldNode.name = "world"
        addChild(worldNode)
        addNebulaEffects()
        addStars()
        if region.hasAncientStructures {
            addAncientStructures()
        }
    }
    
    private func addStars() {
        let startingStars: [CGPoint] = [
            CGPoint(x: 65, y: -25), CGPoint(x: -85, y: 50),
            CGPoint(x: 110, y: 85), CGPoint(x: -130, y: -110),
            CGPoint(x: 225, y: 65), CGPoint(x: 30, y: 185)
        ]
        let weights = region.starWeights
        let totalWeight = weights.values.reduce(0, +)

        for index in 0..<region.starCount {
            let position: CGPoint
            if index < startingStars.count {
                position = startingStars[index]
            } else {
                position = CGPoint(
                    x: CGFloat.random(in: -worldSize / 2 + 80...worldSize / 2 - 80),
                    y: CGFloat.random(in: -worldSize / 2 + 80...worldSize / 2 - 80)
                )
            }
            var roll = Int.random(in: 0..<totalWeight)
            var type: StarType = .small
            for candidate in StarType.allCases {
                roll -= weights[candidate] ?? 0
                if roll < 0 {
                    type = candidate
                    break
                }
            }
            let star = StarNode(type: type)
            star.position = position
            worldNode.addChild(star)
        }
    }

    private func addNebulaEffects() {
        for _ in 0..<5 {
            let nebula = SKSpriteNode(color: SKColor(red: 0.5, green: 0.3, blue: 0.8, alpha: 0.15), size: CGSize(width: 800, height: 800))
            nebula.position = CGPoint(
                x: CGFloat.random(in: -worldSize/3...worldSize/3),
                y: CGFloat.random(in: -worldSize/3...worldSize/3)
            )
            nebula.alpha = 0.15
            let rotate = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 120)
            nebula.run(SKAction.repeatForever(rotate))
            worldNode.addChild(nebula)
        }
    }
    
    private func addAncientStructures() {
        for _ in 0..<3 {
            let structure = createAncientStructure()
            structure.position = CGPoint(
                x: CGFloat.random(in: -worldSize/4...worldSize/4),
                y: CGFloat.random(in: -worldSize/4...worldSize/4)
            )
            worldNode.addChild(structure)
        }
    }
    
    private func createAncientStructure() -> SKNode {
        let container = SKNode()
        let ring = SKShapeNode(circleOfRadius: 100)
        ring.strokeColor = SKColor(red: 0.6, green: 0.4, blue: 1.0, alpha: 0.6)
        ring.lineWidth = 3
        ring.fillColor = .clear
        ring.glowWidth = 5
        container.addChild(ring)
        for i in 0..<6 {
            let angle = CGFloat(i) * CGFloat.pi / 3
            let detail = SKShapeNode(circleOfRadius: 10)
            detail.fillColor = SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 0.8)
            detail.position = CGPoint(x: cos(angle) * 100, y: sin(angle) * 100)
            container.addChild(detail)
        }
        let rotate = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 60)
        container.run(SKAction.repeatForever(rotate))
        return container
    }
    
    private func setupPlayer() {
        playerShip = PlayerShip()
        playerShip.position = .zero
        playerShip.updateStats(gameState.shipStats)
        worldNode.addChild(playerShip)
    }
    
    private func setupPhysics() {
        let boundary = SKPhysicsBody(edgeLoopFrom: CGRect(
            x: -worldSize/2,
            y: -worldSize/2,
            width: worldSize,
            height: worldSize
        ))
        boundary.categoryBitMask = PhysicsCategory.boundary
        boundary.friction = 0
        physicsBody = boundary
    }
    
    // MARK: - POI System
    
    private func setupPOIs() {
        // Generate POIs around the player
        POIManager.shared.generatePOIs(for: region, around: .zero, radius: worldSize / 2)
        
        // Create visual nodes for each POI
        for poi in POIManager.shared.getAllPOIs() {
            let node = createPOINode(for: poi)
            node.position = poi.position
            worldNode.addChild(node)
            poiNodes[poi.id] = node
        }
    }
    
    private func createPOINode(for poi: POI) -> SKNode {
        let container = SKNode()
        container.name = "poi_\(poi.id)"
        
        // Visual representation based on type
        let visualNode: SKNode
        switch poi.type {
        case .stellarFragment:
            visualNode = createStellarFragmentNode()
        case .unknownSignal:
            visualNode = createUnknownSignalNode()
        case .abandonedProbe:
            visualNode = createAbandonedProbeNode()
        case .anomaly:
            visualNode = createAnomalyNode()
        case .derelictShip:
            visualNode = createDerelictShipNode()
        case .ancientStructure:
            visualNode = createAncientStructurePOINode()
        case .hiddenObject:
            visualNode = createHiddenObjectNode()
        case .regionGateway:
            visualNode = createRegionGatewayNode()
        }
        
        container.addChild(visualNode)
        
        // Add discovery indicator (hidden until discovered)
        let indicator = createDiscoveryIndicator(for: poi)
        indicator.alpha = poi.isDiscovered && !poi.isCompleted ? 1 : 0
        container.addChild(indicator)
        
        // Add interaction prompt (hidden until in range)
        let prompt = createInteractionPrompt(for: poi)
        prompt.alpha = 0
        container.addChild(prompt)
        
        return container
    }
    
    private func createStellarFragmentNode() -> SKNode {
        let node = SKSpriteNode(color: SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1.0), size: CGSize(width: 20, height: 20))
        node.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 1.0),
            SKAction.scale(to: 0.8, duration: 1.0)
        ])))
        return node
    }
    
    private func createUnknownSignalNode() -> SKNode {
        let node = SKShapeNode(circleOfRadius: 15)
        node.strokeColor = SKColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
        node.lineWidth = 2
        node.fillColor = .clear
        node.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 1.5),
            SKAction.scale(to: 1.0, duration: 1.5)
        ])))
        return node
    }
    
    private func createAbandonedProbeNode() -> SKNode {
        let node = SKShapeNode(rectOf: CGSize(width: 20, height: 10))
        node.fillColor = SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        node.strokeColor = .clear
        return node
    }
    
    private func createAnomalyNode() -> SKNode {
        let node = SKShapeNode(circleOfRadius: 25)
        node.strokeColor = SKColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 0.8)
        node.lineWidth = 3
        node.fillColor = .clear
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 3.0)))
        return node
    }
    
    private func createDerelictShipNode() -> SKNode {
        let node = SKShapeNode(rectOf: CGSize(width: 40, height: 15))
        node.fillColor = SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        node.strokeColor = .clear
        return node
    }
    
    private func createAncientStructurePOINode() -> SKNode {
        let node = SKShapeNode(circleOfRadius: 30)
        node.strokeColor = SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
        node.lineWidth = 3
        node.fillColor = .clear
        return node
    }
    
    private func createHiddenObjectNode() -> SKNode {
        let node = SKShapeNode(circleOfRadius: 10)
        node.strokeColor = SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        node.lineWidth = 1
        node.fillColor = .clear
        return node
    }
    
    private func createRegionGatewayNode() -> SKNode {
        let node = SKShapeNode(circleOfRadius: 35)
        node.strokeColor = SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)
        node.lineWidth = 3
        node.fillColor = .clear
        node.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 2.0),
            SKAction.scale(to: 1.0, duration: 2.0)
        ])))
        return node
    }
    
    private func createDiscoveryIndicator(for poi: POI) -> SKNode {
        let label = SKLabelNode(text: poi.displayName)
        label.fontName = "Helvetica"
        label.fontSize = 12
        label.fontColor = poi.type.color
        label.position = CGPoint(x: 0, y: 40)
        return label
    }
    
    private func createInteractionPrompt(for poi: POI) -> SKNode {
        let prompt = SKLabelNode(text: scannerSystem.getInteractionPrompt(for: poi) ?? "")
        prompt.fontName = "Helvetica"
        prompt.fontSize = 14
        prompt.fontColor = .white
        prompt.position = CGPoint(x: 0, y: -40)
        return prompt
    }
    
    private func handleScanResults(_ pois: [POI]) {
        gameState.lastScanResults = pois
        gameState.nearbyPOIs = pois
        
        // Update visual indicators for discovered POIs
        for poi in pois {
            if let node = poiNodes[poi.id] {
                if let indicator = node.children.first(where: { $0 is SKLabelNode }) {
                    indicator.alpha = 1
                }
            }
        }
    }
    
    private func handlePOIDiscovered(_ poi: POI) {
        if let node = poiNodes[poi.id], let indicator = node.children.compactMap({ $0 as? SKLabelNode }).first {
            indicator.alpha = 1
        }
        NotificationCenter.default.post(name: .poiDiscovered, object: poi)
    }
    
    /// Called by the contextual touch control (or by tapping a nearby contact).
    func interactWithNearbyPOI() {
        guard !DiscoveryManager.shared.hasActiveDiscovery(),
              let id = gameState.nearbyPOIID,
              let poi = POIManager.shared.getPOI(by: id), poi.isDiscovered,
              poi.canInteract,
              scannerSystem.isInInteractionRange(poi, playerPosition: playerShip.position) else { return }

        if poi.loreEntryId != nil {
            playerShip.stop()
            gameState.joystickDirection = .zero
            let discovery = DiscoveryManager.shared.createDiscovery(for: poi)
            DiscoveryManager.shared.startDiscovery(discovery)
        } else {
            POIManager.shared.completePOI(poi)
            finishInteraction(with: poi)
        }
    }

    func completeActiveDiscovery() {
        guard let discovery = DiscoveryManager.shared.getActiveDiscovery(),
              let poi = POIManager.shared.getPOI(by: discovery.poiId) else { return }
        DiscoveryManager.shared.completeDiscovery(discovery)
        finishInteraction(with: poi)
    }

    private func finishInteraction(with poi: POI) {
        guard poi.isCompleted else { return }
        if gameState.selectedPOIID == poi.id { gameState.selectedPOIID = nil }
        gameState.nearbyPOIID = nil
        scannerSystem.scan(playerPosition: playerShip.position)
        NotificationCenter.default.post(name: .poiCompleted, object: poi)
        AudioManager.shared.playEffect("signal")
    }

    private func contact(at point: CGPoint) -> POI? {
        POIManager.shared.getAllPOIs().first { poi in
            poi.isDiscovered && !poi.isCompleted &&
            hypot(poi.position.x - point.x, poi.position.y - point.y) < 40
        }
    }

    private func updateNearbyContact() {
        gameState.playerPosition = playerShip.position
        let candidates = POIManager.shared.getNearbyPOIs(from: playerShip.position, within: 80)
            .filter { $0.isDiscovered && !$0.isCompleted }
        if let id = gameState.selectedPOIID, candidates.contains(where: { $0.id == id }) {
            gameState.nearbyPOIID = id
        } else {
            gameState.nearbyPOIID = candidates.min {
                hypot($0.position.x - playerShip.position.x, $0.position.y - playerShip.position.y) <
                hypot($1.position.x - playerShip.position.x, $1.position.y - playerShip.position.y)
            }?.id
        }
    }

    private func updateWaypoint() {
        guard let label = waypointLabel, let id = gameState.selectedPOIID,
              let poi = POIManager.shared.getPOI(by: id), !poi.isCompleted else {
            waypointLabel?.isHidden = true
            return
        }
        let dx = poi.position.x - cameraNode.position.x
        let dy = poi.position.y - cameraNode.position.y
        let distance = Int(hypot(poi.position.x - playerShip.position.x,
                                 poi.position.y - playerShip.position.y))
        label.text = "◆ \(poi.displayName) · \(distance)m"
        // SKLabelNode is center-aligned: reserve half its width at screen edges.
        let horizontalInset = min(size.width / 2, label.frame.width / 2 + 12)
        let x = max(-size.width / 2 + horizontalInset,
                    min(size.width / 2 - horizontalInset, dx))
        let y = max(-size.height / 2 + 50, min(size.height / 2 - 50, dy))
        label.position = CGPoint(x: x, y: y)
        label.isHidden = false
    }

    // MARK: - Touch Handling
    
    #if os(iOS) || os(tvOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        isTouching = true
        let location = touch.location(in: self)
        lastTouchLocation = location
        let worldPoint = convert(location, to: worldNode)
        if let poi = contact(at: worldPoint) {
            gameState.selectedPOIID = poi.id
            if scannerSystem.isInInteractionRange(poi, playerPosition: playerShip.position) {
                gameState.nearbyPOIID = poi.id
                interactWithNearbyPOI()
            }
        } else {
            playerShip.moveToward(worldPoint)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchLocation = location
        playerShip.moveToward(convert(location, to: worldNode))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        playerShip.stop()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        playerShip.stop()
    }
    #elseif os(macOS)
    override func mouseDown(with event: NSEvent) {
        isTouching = true
        lastTouchLocation = event.location(in: self)
        if let camera = cameraNode {
            let worldPoint = convert(lastTouchLocation!, to: worldNode)
            playerShip.moveToward(worldPoint)
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        lastTouchLocation = event.location(in: self)
        if let camera = cameraNode {
            let worldPoint = convert(lastTouchLocation!, to: worldNode)
            playerShip.moveToward(worldPoint)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        isTouching = false
        playerShip.stop()
    }
    #endif
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        guard isReady else { return }
        
        let deltaTime = min(max(currentTime - (lastUpdateTime ?? currentTime), 0), 0.05)
        lastUpdateTime = currentTime
        scannerSystem.update(deltaTime: deltaTime, playerPosition: playerShip.position)

        // SwiftUI drag coordinates point down, while SpriteKit world coordinates point up.
        if gameState.joystickDirection != .zero {
            playerShip.moveToward(CGPoint(
                x: playerShip.position.x + gameState.joystickDirection.dx * 100,
                y: playerShip.position.y - gameState.joystickDirection.dy * 100
            ))
            wasUsingJoystick = true
        } else if wasUsingJoystick {
            playerShip.stop()
            wasUsingJoystick = false
        }
        playerShip.update(deltaTime: deltaTime)
        updateCamera()
        updateParallax()
        updateWaypoint()
        statusUpdateTimer += deltaTime
        if statusUpdateTimer >= 0.2 {
            statusUpdateTimer = 0
            updateNearbyContact()
        }
        drainEnergy()
        updatePOIVisibility()
        checkGameConditions()
    }
    
    private func updatePOIVisibility() {
        let scanRange = scannerSystem.getScanRange()
        
        for poi in POIManager.shared.getAllPOIs() {
            guard let node = poiNodes[poi.id] else { continue }
            
            let dx = poi.position.x - playerShip.position.x
            let dy = poi.position.y - playerShip.position.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if poi.type == .hiddenObject && (gameState.upgradeLevels[.pulseScanner] ?? 0) == 0 {
                node.alpha = 0
            } else if poi.isCompleted {
                node.alpha = 0.2
                node.children.compactMap { $0 as? SKLabelNode }.forEach { $0.alpha = 0 }
            } else if poi.isDiscovered {
                node.alpha = 1
                if let indicator = node.children.compactMap({ $0 as? SKLabelNode }).first {
                    let visibleX = abs(poi.position.x - cameraNode.position.x) + indicator.frame.width / 2 < size.width / 2 - 4
                    let visibleY = abs(poi.position.y - cameraNode.position.y) < size.height / 2 - 45
                    indicator.alpha = visibleX && visibleY ? 1 : 0
                }
                if let prompt = node.children.last as? SKLabelNode {
                    prompt.alpha = distance <= 80 ? 1 : 0
                }
            } else {
                node.alpha = distance <= scanRange ? 0.3 : 0
            }
        }
    }
    
    private func updateCamera() {
        guard let camera = cameraNode else { return }
        let targetPosition = playerShip.position
        let lerpFactor: CGFloat = 0.05
        let newX = camera.position.x + (targetPosition.x - camera.position.x) * lerpFactor
        let newY = camera.position.y + (targetPosition.y - camera.position.y) * lerpFactor
        camera.position = CGPoint(x: newX, y: newY)
    }
    
    private func updateParallax() {
        guard let camera = cameraNode else { return }
        for (index, layer) in backgroundLayers.enumerated() {
            let parallaxFactor = CGFloat(index + 1) * 0.2
            layer.position = CGPoint(
                x: camera.position.x * (1 - parallaxFactor),
                y: camera.position.y * (1 - parallaxFactor)
            )
        }
    }
    
    private func drainEnergy() {
        let drain = region.energyDrainRate / 60.0
        gameState.useEnergy(drain)
        if gameState.shipEnergy <= 0 {
            onEnergyDepleted?()
        }
    }
    
    private func checkLoreDiscovery() {
        for entry in LoreSystem.entries(for: region) {
            if !gameState.discoveredLore.contains(entry.id) {
                let starsNeeded: Int
                switch entry.category {
                case .transmission: starsNeeded = 5
                case .astralLog: starsNeeded = 10
                case .shipRecord: starsNeeded = 15
                case .signal: starsNeeded = 20
                case .environmental: starsNeeded = 25
                }
                if gameState.regionStarsCollected >= starsNeeded {
                    gameState.discoverLore(entry.id)
                    onLoreDiscovered?(entry)
                    AudioManager.shared.playEffect("lore")
                }
            }
        }
    }
    
    private func checkGameConditions() {
        for region in Region.allCases {
            if !gameState.unlockedRegions.contains(region) {
                if region.isUnlocked(gameState: gameState) {
                    gameState.unlockRegion(region)
                    onRegionUnlocked?(region)
                }
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if contactMask == PhysicsCategory.player | PhysicsCategory.star {
            handleStarCollection(contact: contact)
        }
        if contactMask == PhysicsCategory.player | PhysicsCategory.asteroid {
            handleAsteroidCollision(contact: contact)
        }
    }
    
    private func handleStarCollection(contact: SKPhysicsContact) {
        let starNode: StarNode
        if contact.bodyA.categoryBitMask == PhysicsCategory.star {
            starNode = contact.bodyA.node as! StarNode
        } else {
            starNode = contact.bodyB.node as! StarNode
        }
        let starType = starNode.starType
        starNode.physicsBody = nil // A lingering collection animation must not award the star twice.
        starNode.collect()
        gameState.collectStar(starType)
        AudioManager.shared.playEffect(starType.collectSound)
        playerShip.showCollectionRadius()
        onStarCollected?(starType)
        NotificationCenter.default.post(name: .starCollected, object: starType)
    }
    
    private func handleAsteroidCollision(contact: SKPhysicsContact) {
        let asteroidNode: AsteroidNode
        if contact.bodyA.categoryBitMask == PhysicsCategory.asteroid {
            asteroidNode = contact.bodyA.node as! AsteroidNode
        } else {
            asteroidNode = contact.bodyB.node as! AsteroidNode
        }
        let damage = Double(asteroidNode.size.width) * 0.5
        gameState.takeDamage(damage / 100.0)
        playerShip.flash()
        playerShip.showShield()
        asteroidNode.onHit()
        AudioManager.shared.playEffect("damage")
    }
    
    func travelToRegion(_ newRegion: Region) {
        region = newRegion
        
        // Clear existing POIs
        for (_, node) in poiNodes {
            node.removeFromParent()
        }
        poiNodes.removeAll()
        POIManager.shared.clear()
        
        worldNode.removeAllChildren()
        backgroundColor = SKColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1.0)
        setupWorld()
        setupPlayer()
        setupPOIs()
        playerShip.position = .zero
        gameState.travelToRegion(newRegion)
        AudioManager.shared.playEffect("warp")
    }
    
    func getCurrentRegion() -> Region {
        return region
    }
}

// POI discovery notifications are declared alongside the other gameplay notifications in GameUI.
