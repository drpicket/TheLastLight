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
    private var starRespawnTimer: TimeInterval = 0
    private var starNodes: [StarNode] = []
    private var asteroidNodes: [AsteroidNode] = []
    private var vortexes: [GravityVortexNode] = []
    private var stalker: VoidStalkerNode?
    private var riskOverlay: SKShapeNode?
    private var sceneTime: TimeInterval = 0
    private var lastSlingshotAt: TimeInterval = 0
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
    
    // MARK: - Pause Controls

    func pause() {
        isPaused = true
        AudioManager.shared.stopAmbientMusic()
    }

    func resume() {
        isPaused = false
        lastUpdateTime = nil
        AudioManager.shared.startAmbientMusic()
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
        starNodes.removeAll()
        asteroidNodes.removeAll()
        vortexes.forEach { $0.removeFromParent() }
        vortexes.removeAll()
        stalker?.removeFromParent()
        stalker = nil
        addNebulaEffects()
        addStars()
        addAsteroids()
        addVortexes()
        if region.hasAncientStructures {
            addAncientStructures()
        }
        updateRiskOverlay(deltaTime: 0)
    }

    private func pickStarType() -> StarType {
        let weights = region.starWeights
        let totalWeight = weights.values.reduce(0, +)
        var roll = Int.random(in: 0..<totalWeight)
        var type: StarType = .small
        for candidate in StarType.allCases {
            roll -= weights[candidate] ?? 0
            if roll < 0 {
                type = candidate
                break
            }
        }
        return type
    }

    private func addStars() {
        let startingStars: [CGPoint] = [
            CGPoint(x: 65, y: -25), CGPoint(x: -85, y: 50),
            CGPoint(x: 110, y: 85), CGPoint(x: -130, y: -110),
            CGPoint(x: 225, y: 65), CGPoint(x: 30, y: 185)
        ]
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
            let type = pickStarType()
            let volatile = (type == .golden || type == .ancient) && Double.random(in: 0...1) < EnhancementConfig.volatileChance
            let star = StarNode(type: type, isVolatile: volatile)
            star.position = position
            worldNode.addChild(star)
            starNodes.append(star)
        }
        // Density fix: bonus near-field stars so the first minutes feel alive.
        for _ in 0..<(region.starCount / 4) {
            let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
            let dist = CGFloat.random(in: 120...900)
            let pos = CGPoint(x: cos(angle) * dist, y: sin(angle) * dist)
            let type = pickStarType()
            let volatile = (type == .golden || type == .ancient) && Double.random(in: 0...1) < EnhancementConfig.volatileChance
            let star = StarNode(type: type, isVolatile: volatile)
            star.position = pos
            worldNode.addChild(star)
            starNodes.append(star)
        }
    }

    private func spawnRespawnStar() {
        guard starNodes.count < region.starCount + 30 else { return }
        // 2-at-a-time respawns; bias near the player so combos stay alive.
        for _ in 0..<2 {
            let pos: CGPoint
            if Double.random(in: 0...1) < 0.6 {
                let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
                let dist = CGFloat.random(in: 350...800)
                pos = CGPoint(
                    x: playerShip.position.x + cos(angle) * dist,
                    y: playerShip.position.y + sin(angle) * dist
                )
            } else {
                let half = worldSize / 2 - 120
                pos = CGPoint(
                    x: CGFloat.random(in: -half...half),
                    y: CGFloat.random(in: -half...half)
                )
            }
            let type = pickStarType()
            let volatile = (type == .golden || type == .ancient) && Double.random(in: 0...1) < EnhancementConfig.volatileChance
            let star = StarNode(type: type, isVolatile: volatile)
            star.position = pos
            star.alpha = 0
            worldNode.addChild(star)
            starNodes.append(star)
            star.run(SKAction.fadeIn(withDuration: 0.8))
        }
    }

    private func addAsteroids() {
        for _ in 0..<region.asteroidCount {
            let size = CGFloat.random(in: 24...64)
            let node = AsteroidNode(size: size, speedMultiplier: region.asteroidSpeedMultiplier)
            node.position = CGPoint(
                x: CGFloat.random(in: -worldSize/2...worldSize/2),
                y: CGFloat.random(in: -worldSize/2...worldSize/2)
            )
            // Keep spawn away from origin.
            if hypot(node.position.x, node.position.y) < 220 {
                node.position = CGPoint(x: node.position.x + 400, y: node.position.y + 300)
            }
            worldNode.addChild(node)
            asteroidNodes.append(node)
        }
    }

    private func addVortexes() {
        for _ in 0..<region.vortexCount {
            let v = GravityVortexNode(strength: region.vortexStrength)
            v.position = CGPoint(
                x: CGFloat.random(in: -worldSize/3...worldSize/3),
                y: CGFloat.random(in: -worldSize/3...worldSize/3)
            )
            if hypot(v.position.x, v.position.y) < 300 {
                v.position.x += 600
            }
            worldNode.addChild(v)
            vortexes.append(v)
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
        gameState.evaluateDirectives(event: .poi(poi.type))
        // Feature C: storm chain progresses in stormOrder.
        if poi.isStorm {
            GhostSignalDecay.shared.stopTracking(poi.id)
            if poi.stormOrder == gameState.stormChainIndex {
                gameState.stormChainIndex += 1
                gameState.stormPOIIDs.removeAll { $0 == poi.id }
                AudioManager.shared.playEffect("signal")
                if let pattern = ConstellationMemory.shared.checkStormChain(
                    chainIndex: gameState.stormChainIndex,
                    needed: EnhancementConfig.stormPOICount
                ) {
                    AudioManager.shared.playEffect("constellation")
                    gameState.stormChainIndex = 0
                    _ = pattern
                }
            } else {
                // Out of order still counts, but no chain bonus.
                gameState.stormPOIIDs.removeAll { $0 == poi.id }
            }
            if let node = poiNodes[poi.id] {
                node.removeFromParent()
                poiNodes.removeValue(forKey: poi.id)
            }
        } else {
            AudioManager.shared.playEffect("signal")
        }
        scannerSystem.scan(playerPosition: playerShip.position)
        NotificationCenter.default.post(name: .poiCompleted, object: poi)
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
        // During storms with no manual track, auto-guide to the next chain link.
        if gameState.stormActive {
            let trackedValid = gameState.selectedPOIID
                .flatMap { POIManager.shared.getPOI(by: $0) }
                .map { !$0.isCompleted } ?? false
            if !trackedValid, let next = POIManager.shared.stormPOIs().first {
                gameState.selectedPOIID = next.id
            }
        }
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
        playerShip.stop()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        playerShip.stop()
    }
    #elseif os(macOS)
    override func mouseDown(with event: NSEvent) {
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
        playerShip.stop()
    }
    #endif
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        guard isReady else { return }

        let deltaTime = min(max(currentTime - (lastUpdateTime ?? currentTime), 0), 0.05)
        lastUpdateTime = currentTime
        sceneTime = currentTime
        playerShip.currentTime = currentTime
        scannerSystem.update(deltaTime: deltaTime, playerPosition: playerShip.position)

        if gameState.joystickDirection != .zero {
            // Dead-ship sluggishness during power failure.
            let scale: CGFloat = gameState.powerFailureActive ? 0.4 : 1.0
            playerShip.moveToward(CGPoint(
                x: playerShip.position.x + gameState.joystickDirection.dx * 100 * scale,
                y: playerShip.position.y - gameState.joystickDirection.dy * 100 * scale
            ))
            wasUsingJoystick = true
        } else if wasUsingJoystick {
            playerShip.stop()
            wasUsingJoystick = false
        }
        applyVortexForces(deltaTime: deltaTime)
        playerShip.update(deltaTime: deltaTime)
        updateCamera()
        updateParallax()
        updateWaypoint()
        statusUpdateTimer += deltaTime
        if statusUpdateTimer >= 0.2 {
            statusUpdateTimer = 0
            updateNearbyContact()
        }
        // Feature tuning ticks.
        gameState.tickCombo(deltaTime: deltaTime)
        gameState.decayNoise(EnhancementConfig.noiseDecayPerSecond * deltaTime)
        RiskAccrualSystem.shared.decay(deltaTime: deltaTime)
        updateVolatiles(deltaTime: deltaTime)
        updateStarRespawn(deltaTime: deltaTime)
        updateStalker(deltaTime: deltaTime)
        updateStorm(deltaTime: deltaTime)
        updateRiskOverlay(deltaTime: deltaTime)
        updateEnergyVignette(deltaTime: deltaTime)
        pollDirectives(deltaTime: deltaTime)
        drainEnergy(deltaTime: deltaTime)
        updatePOIVisibility()
        checkLoreDiscovery()
        checkGameConditions()
        gameState.flushScheduledSave()
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
    
    private func drainEnergy(deltaTime: Double) {
        // energyDrainRate is a per-second rate; scale by real elapsed time so
        // the battery drains at the same rate on 60Hz and 120Hz displays.
        let drain = region.energyDrainRate * deltaTime
        gameState.useEnergy(drain)
        // Record last safe spot while powered.
        if gameState.shipEnergy > 0.3 {
            safePositionTimer += deltaTime
            if safePositionTimer >= 2.0 {
                safePositionTimer = 0
                gameState.lastSafePosition = playerShip.position
            }
        }
        if gameState.shipEnergy <= 0 && !gameState.powerFailureActive {
            gameState.shipEnergy = 0
            gameState.beginPowerFailure()
            AudioManager.shared.playEffect("volatileExpire")
        }
        if gameState.powerFailureActive {
            // Sluggish dead-ship drift while counting down.
            gameState.powerFailureCountdown -= deltaTime
            if gameState.shipEnergy > 0.05 {
                // Rebooted by collecting a star.
                gameState.endPowerFailure(rescued: true)
                playerShip.showShield()
            } else if gameState.powerFailureCountdown <= 0 {
                rescueStrandedShip()
            }
        }
    }

    private var safePositionTimer: Double = 0
    private var directivePollTimer: Double = 0

    /// Periodic evaluation so threshold-driven directives (star counts, nebula
    /// contacts, combo) still advance without a triggering event. Each step
    /// owns its own rule, so there are no magic indices here.
    private func pollDirectives(deltaTime: Double) {
        directivePollTimer += deltaTime
        guard directivePollTimer >= 0.5 else { return }
        directivePollTimer = 0
        // Loop so a single poll can carry through several freshly-unlocked steps.
        var remaining = GameState.directives.count
        while remaining > 0 {
            let before = gameState.directiveIndex
            let wasComplete = gameState.directiveComplete
            gameState.evaluateDirectives()
            if gameState.directiveIndex == before && gameState.directiveComplete == wasComplete { break }
            remaining -= 1
        }
    }

    private func rescueStrandedShip() {
        // Wayfarer rescue: tow to last safe position, tax 10% energy stores.
        let tax = Int(Double(gameState.starEnergy) * EnhancementConfig.powerFailureEnergyTax)
        gameState.starEnergy = max(0, gameState.starEnergy - tax)
        gameState.shipEnergy = 0.35
        gameState.shipShield = 0.5
        gameState.resetCombo()
        gameState.noiseLevel = 0
        gameState.ventRisk(0.2)
        stalker?.removeFromParent()
        stalker = nil
        gameState.stalkerActive = false
        playerShip.position = gameState.lastSafePosition
        playerShip.stop()
        playerShip.grantInvulnerability(duration: 2.0, now: sceneTime)
        playerShip.showShield()
        gameState.endPowerFailure(rescued: false)
        AudioManager.shared.playEffect("warp")
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
                    NotificationCenter.default.post(name: .loreDiscovered, object: entry)
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
                    NotificationCenter.default.post(name: .regionUnlocked, object: region)
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
            guard let n = contact.bodyA.node as? StarNode else { return }
            starNode = n
        } else {
            guard let n = contact.bodyB.node as? StarNode else { return }
            starNode = n
        }
        let starType = starNode.starType
        let wasVolatile = starNode.isVolatile
        starNode.physicsBody = nil
        starNode.collect()
        starNodes.removeAll { $0 === starNode }
        let award = gameState.collectStar(starType, isVolatile: wasVolatile)
        if gameState.comboMultiplier >= 5 {
            AudioManager.shared.playEffect("combo5")
            shakeCamera(intensity: 6)
        } else if gameState.comboMultiplier == 3 {
            AudioManager.shared.playEffect("combo3")
        } else if gameState.comboMultiplier == 2 {
            AudioManager.shared.playEffect("combo2")
        } else if wasVolatile {
            AudioManager.shared.playEffect("volatile")
        } else {
            AudioManager.shared.playEffect(starType.collectSound)
        }
        _ = award
        playerShip.showCollectionRadius()
        VisualGhostTrails.shared.recordTrail(at: starNode.position, in: worldNode)
        if wasVolatile {
            gameState.evaluateDirectives(event: .volatile)
        }
        NotificationCenter.default.post(name: .starCollected, object: starType)
        NotificationCenter.default.post(name: .comboChanged, object: nil)
    }

    private func handleAsteroidCollision(contact: SKPhysicsContact) {
        let asteroidNode: AsteroidNode
        if contact.bodyA.categoryBitMask == PhysicsCategory.asteroid {
            guard let n = contact.bodyA.node as? AsteroidNode else { return }
            asteroidNode = n
        } else {
            guard let n = contact.bodyB.node as? AsteroidNode else { return }
            asteroidNode = n
        }
        if playerShip.isInvulnerable(at: sceneTime) || playerShip.isPhased(at: sceneTime) { return }
        let damage = Double(asteroidNode.size.width) * 0.5 / 100.0
        gameState.takeDamage(damage)
        gameState.addNoise(0.12)
        playerShip.flash()
        playerShip.showShield()
        playerShip.grantInvulnerability(duration: 1.0, now: sceneTime)
        asteroidNode.onHit()
        AudioManager.shared.playEffect("damage")
        shakeCamera(intensity: 4)
    }

    // MARK: - Feature A helpers
    private func updateVolatiles(deltaTime: Double) {
        // Frozen mid-discovery, like the combo fuse: reading must not burn fuses.
        guard DiscoveryManager.shared.hasActiveDiscovery() == false else { return }
        var expired: [StarNode] = []
        for star in starNodes where star.isVolatile {
            if star.tickFuse(deltaTime: deltaTime) { expired.append(star) }
        }
        for star in expired {
            starNodes.removeAll { $0 === star }
            AudioManager.shared.playEffect("volatileExpire")
        }
    }

    private func updateStarRespawn(deltaTime: Double) {
        starRespawnTimer += deltaTime
        if starRespawnTimer >= EnhancementConfig.starRespawnInterval {
            starRespawnTimer = 0
            starNodes.removeAll { $0.parent == nil }
            spawnRespawnStar()
        }
    }

    private func shakeCamera(intensity: CGFloat) {
        guard let cam = cameraNode else { return }
        let shake = SKAction.sequence([
            SKAction.moveBy(x: intensity, y: 0, duration: 0.05),
            SKAction.moveBy(x: -intensity * 2, y: 0, duration: 0.05),
            SKAction.moveBy(x: intensity, y: 0, duration: 0.05)
        ])
        cam.run(shake)
    }

    // MARK: - Feature B: vortex + stalker
    private func applyVortexForces(deltaTime: Double) {
        let phased = playerShip.isPhased(at: sceneTime)
        for v in vortexes {
            let force = v.pullVector(for: playerShip.position, phased: phased)
            if force.dx != 0 || force.dy != 0 {
                playerShip.applyExternalForce(CGVector(
                    dx: force.dx * CGFloat(deltaTime) * 60 * 0.016,
                    dy: force.dy * CGFloat(deltaTime) * 60 * 0.016
                ))
            }
            let dist = hypot(v.position.x - playerShip.position.x, v.position.y - playerShip.position.y)
            if dist < v.killRadius {
                if !playerShip.isInvulnerable(at: sceneTime) && !phased {
                    gameState.takeDamage(0.15)
                    playerShip.flash()
                    playerShip.showShield()
                    playerShip.grantInvulnerability(duration: 1.2, now: sceneTime)
                    AudioManager.shared.playEffect("damage")
                }
            } else if v.isInRim(playerShip.position) {
                let speed = hypot(playerShip.physicsBody?.velocity.dx ?? 0, playerShip.physicsBody?.velocity.dy ?? 0)
                if speed > 160 && sceneTime - lastSlingshotAt > 3.0 {
                    lastSlingshotAt = sceneTime
                    let dx = playerShip.position.x - v.position.x
                    let dy = playerShip.position.y - v.position.y
                    let d = max(1, hypot(dx, dy))
                    playerShip.slingshotBoost(
                        direction: CGVector(dx: dx / d, dy: dy / d),
                        power: 120
                    )
                    gameState.starEnergy += EnhancementConfig.vortexSlingshotBonus
                    gameState.addNoise(0.05)
                    gameState.evaluateDirectives(event: .slingshot)
                    AudioManager.shared.playEffect("slingshot")
                    NotificationCenter.default.post(name: .starCollected, object: StarType.small)
                }
            }
        }
    }

    private func updateStalker(deltaTime: Double) {
        let shouldHunt = gameState.noiseLevel >= EnhancementConfig.stalkerNoiseThreshold
        if shouldHunt && stalker == nil {
            let s = VoidStalkerNode()
            // Spawn at screen edge away from player.
            let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
            s.position = CGPoint(
                x: playerShip.position.x + cos(angle) * 600,
                y: playerShip.position.y + sin(angle) * 600
            )
            s.state = .hunting
            worldNode.addChild(s)
            stalker = s
            gameState.stalkerActive = true
            AudioManager.shared.playEffect("stalker")
            NotificationCenter.default.post(name: .stalkerChanged, object: nil)
        } else if !shouldHunt && stalker != nil && gameState.noiseLevel <= EnhancementConfig.stalkerDespawnNoise {
            stalker?.removeFromParent()
            stalker = nil
            gameState.stalkerActive = false
            gameState.stalkerDistance = 9999
            // Relief beat: the hunter losing interest must feel like a reward.
            AudioManager.shared.playEffect("signal")
            NotificationCenter.default.post(name: .stalkerChanged, object: nil)
            return
        }
        guard let s = stalker else { return }
        let dist = s.update(
            deltaTime: CGFloat(deltaTime),
            playerPos: playerShip.position,
            aggression: region.stalkerAggression,
            playerTopSpeed: playerShip.maxSpeed
        )
        gameState.stalkerDistance = dist
        if dist < s.touchRadius + 18 {
            if !playerShip.isInvulnerable(at: sceneTime) && !playerShip.isPhased(at: sceneTime) {
                gameState.takeDamage(EnhancementConfig.stalkerDamage)
                gameState.noiseLevel = 0.3
                playerShip.flash()
                playerShip.showShield()
                playerShip.grantInvulnerability(duration: 1.5, now: sceneTime)
                AudioManager.shared.playEffect("damage")
                shakeCamera(intensity: 8)
            }
        }
    }

    // MARK: - Feature C: storms
    private func updateStorm(deltaTime: Double) {
        let wasActive = gameState.stormActive
        gameState.tickStorm(deltaTime: deltaTime)
        if gameState.stormActive && !wasActive {
            startStorm()
        } else if !gameState.stormActive && wasActive {
            endStorm(expired: true)
        }
        if gameState.stormActive {
            // Fuses burn on game time, frozen while a discovery modal is open.
            GhostSignalDecay.shared.tickStormFuses(
                deltaTime: deltaTime,
                frozen: DiscoveryManager.shared.hasActiveDiscovery()
            )
            let ids = gameState.stormPOIIDs
            let expired = GhostSignalDecay.shared.updateStormPOIs(ids: ids, fuse: EnhancementConfig.stormDuration)
            if !expired.isEmpty {
                POIManager.shared.removePOIs(ids: expired)
                for id in expired {
                    if let node = poiNodes[id] {
                        node.removeFromParent()
                        poiNodes.removeValue(forKey: id)
                    }
                }
                gameState.stormPOIIDs.removeAll { expired.contains($0) }
                scannerSystem.scan(playerPosition: playerShip.position)
            }
        }
    }

    private func startStorm() {
        let pois = POIManager.shared.spawnStormPOIs(
            count: EnhancementConfig.stormPOICount,
            around: playerShip.position,
            radius: scannerSystem.getScanRange()
        )
        gameState.stormPOIIDs = pois.map { $0.id }
        gameState.stormChainIndex = 0
        for poi in pois {
            let node = createPOINode(for: poi)
            node.position = poi.position
            // Storm tint.
            let ping = SKShapeNode(circleOfRadius: 30)
            ping.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.9, alpha: 0.8)
            ping.lineWidth = 2
            ping.fillColor = .clear
            node.addChild(ping)
            ping.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.7),
                SKAction.scale(to: 1.0, duration: 0.7)
            ])))
            worldNode.addChild(node)
            poiNodes[poi.id] = node
        }
        AudioManager.shared.playEffect("storm")
        NotificationCenter.default.post(name: .stormChanged, object: nil)
        scannerSystem.scan(playerPosition: playerShip.position)
    }

    private func endStorm(expired: Bool) {
        let remaining = gameState.stormPOIIDs
        if !remaining.isEmpty {
            POIManager.shared.removePOIs(ids: remaining)
            for id in remaining {
                poiNodes[id]?.removeFromParent()
                poiNodes.removeValue(forKey: id)
            }
        }
        gameState.stormPOIIDs = []
        gameState.stormChainIndex = 0
        NotificationCenter.default.post(name: .stormChanged, object: nil)
    }

    private var riskOverlayTimer: Double = 0
    private var riskOverlayBuiltFor: Double = -1
    private var energyVignette: SKShapeNode?
    private var energyVignettePhase: Double = 0

    private func updateRiskOverlay(deltaTime: Double) {
        // Throttled: rebuilding a shape node every frame shimmers and wastes fill-rate.
        riskOverlayTimer += deltaTime
        let risk = gameState.riskLevel
        guard risk > 0.05 else {
            riskOverlay?.removeFromParent()
            riskOverlay = nil
            riskOverlayBuiltFor = -1
            return
        }
        if let overlay = riskOverlay {
            overlay.position = cameraNode.position
            overlay.alpha = min(1.0, risk)
            // Rebuild only on significant band change so color tracks risk.
            if abs(risk - riskOverlayBuiltFor) > 0.15 && riskOverlayTimer >= 0.25 {
                riskOverlayTimer = 0
                overlay.removeFromParent()
                riskOverlay = nil
            } else {
                return
            }
        }
        guard riskOverlayTimer >= 0.25 else { return }
        riskOverlayTimer = 0
        riskOverlayBuiltFor = risk
        let overlay = VisualDistortionSystem.shared.makeOverlay(size: size, risk: risk)
        overlay.position = cameraNode.position
        overlay.alpha = min(1.0, risk)
        addChild(overlay)
        riskOverlay = overlay
    }

    /// Low-battery closing-in darkness: pulses faster as energy drains.
    private func updateEnergyVignette(deltaTime: Double) {
        let e = gameState.shipEnergy
        guard e < 0.3 else {
            energyVignette?.removeFromParent()
            energyVignette = nil
            return
        }
        energyVignettePhase += deltaTime * (2.0 + (0.3 - e) * 20.0)
        let pulse = 0.25 + 0.2 * sin(energyVignettePhase * 2.0 * .pi / 2.0)
        if energyVignette == nil {
            let v = SKShapeNode(rectOf: size)
            v.fillColor = SKColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
            v.strokeColor = .clear
            v.zPosition = 91
            v.name = "energyVignette"
            addChild(v)
            energyVignette = v
        }
        energyVignette?.position = cameraNode.position
        energyVignette?.alpha = CGFloat(pulse * (0.3 - e) / 0.3)
    }
    
    func travelToRegion(_ newRegion: Region) {
        region = newRegion
        for (_, node) in poiNodes {
            node.removeFromParent()
        }
        poiNodes.removeAll()
        POIManager.shared.clear()
        starNodes.removeAll()
        asteroidNodes.removeAll()
        vortexes.forEach { $0.removeFromParent() }
        vortexes.removeAll()
        stalker?.removeFromParent()
        stalker = nil
        riskOverlay?.removeFromParent()
        riskOverlay = nil
        riskOverlayBuiltFor = -1
        riskOverlayTimer = 0
        energyVignette?.removeFromParent()
        energyVignette = nil
        starRespawnTimer = 0
        VisualGhostTrails.shared.clear()
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
