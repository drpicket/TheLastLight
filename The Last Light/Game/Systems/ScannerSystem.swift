import Foundation
import SpriteKit

/// Manages the ship's scanner, which periodically detects nearby POIs.
class ScannerSystem {
    static let shared = ScannerSystem()
    
    private var gameState: GameState { GameState.shared }
    private var scanTimer: TimeInterval = 0
    private var scanInterval: TimeInterval = 3.0
    private var isScanning: Bool = false
    private var lastScanResults: [POI] = []
    
    var onScanComplete: (([POI]) -> Void)?
    var onPOIDiscovered: ((POI) -> Void)?
    
    private init() {}
    
    /// Start scanning for POIs
    func startScanning() {
        isScanning = true
        scanTimer = scanInterval // Reveal nearby choices on the first update.
        gameState.isScanning = true
    }

    /// Stop scanning
    func stopScanning() {
        isScanning = false
        gameState.isScanning = false
        lastScanResults = []
    }
    
    /// Update the scanner (called every frame)
    func update(deltaTime: TimeInterval, playerPosition: CGPoint) {
        guard isScanning else { return }
        
        scanTimer += deltaTime
        if scanTimer >= currentInterval() {
            scanTimer = 0
            performScan(playerPosition: playerPosition)
        }
    }
    
    /// Refresh after an interaction rather than waiting for the next periodic sweep.
    func scan(playerPosition: CGPoint) {
        performScan(playerPosition: playerPosition)
    }

    /// Perform a scan for nearby POIs
    private func performScan(playerPosition: CGPoint) {
        let nearbyPOIs = POIManager.shared.getNearbyPOIs(from: playerPosition, within: getScanRange())
            .filter { !$0.isCompleted && ($0.type != .hiddenObject ||
                (gameState.upgradeLevels[.pulseScanner] ?? 0) > 0) }
            .sorted { hypot($0.position.x - playerPosition.x, $0.position.y - playerPosition.y) <
                      hypot($1.position.x - playerPosition.x, $1.position.y - playerPosition.y) }

        for poi in nearbyPOIs where !poi.isDiscovered {
            POIManager.shared.discoverPOI(poi)
            onPOIDiscovered?(poi)
        }

        lastScanResults = nearbyPOIs
        onScanComplete?(nearbyPOIs)
    }
    
    /// Get the current scan range based on upgrades
    func getScanRange() -> CGFloat {
        var range: CGFloat = 300.0
        
        // Pulse Scanner upgrade increases range
        let scannerLevel = gameState.upgradeLevels[.scanner] ?? 0
        range += CGFloat(scannerLevel) * 100.0
        if gameState.stormActive { range += EnhancementConfig.stormScanBonus }
        
        return range
    }

    /// Storms sweep faster.
    func currentInterval() -> TimeInterval {
        gameState.stormActive ? 1.5 : scanInterval
    }
    
    /// Get the last scan results
    func getLastScanResults() -> [POI] {
        return lastScanResults
    }
    
    /// Check if a POI is within interaction range
    func isInInteractionRange(_ poi: POI, playerPosition: CGPoint) -> Bool {
        let dx = poi.position.x - playerPosition.x
        let dy = poi.position.y - playerPosition.y
        let distance = sqrt(dx * dx + dy * dy)
        return distance <= 80.0
    }
    
    /// Get interaction prompt for a POI
    func getInteractionPrompt(for poi: POI) -> String? {
        if poi.isCompleted {
            return nil
        }
        
        if let required = poi.requiredUpgrade {
            let level = gameState.upgradeLevels[required] ?? 0
            if level == 0 {
                return "Requires \(required.displayName)"
            }
        }
        
        switch poi.type {
        case .stellarFragment:
            return "Collect Star"
        case .unknownSignal:
            return "Decode Signal"
        case .abandonedProbe:
            return "Recover Data"
        case .anomaly:
            return "Enter Anomaly"
        case .derelictShip:
            return "Board Ship"
        case .ancientStructure:
            return "Investigate"
        case .hiddenObject:
            return "Scan Object"
        case .regionGateway:
            return "Travel"
        }
    }
}
