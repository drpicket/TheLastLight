import Foundation

/// Centralized configuration for all enhanced gameplay features.
struct EnhancementConfig {
    // MARK: - Signal Echo Risk
    static let riskPerDiscovery: Double = 0.12
    static let riskThreshold: Double = 0.75
    static let riskOverageMultiplier: Double = 1.5
    static let riskDecayPerSecond: Double = 0.01

    // MARK: - Ghost Signal Decay
    static let ghostDecayStartTime: TimeInterval = 300.0
    static let ghostDecayDuration: TimeInterval = 120.0

    // MARK: - Memory Anchors
    static let maxMemoryAnchorRegions: Int = 3

    // MARK: - Visual Features
    static var enableGhostTrails: Bool = true
    static let ghostTrailDuration: TimeInterval = 30.0

    // MARK: - Constellation Memory
    static let constellationThreshold: Int = 8
    static let constellationPointsRequired: Int = 6
    static let constellationRiskVent: Double = 0.3

    // MARK: - Sound / UI
    static var enableDynamicAmbience: Bool = true
    static var enableFloatingText: Bool = true

    // MARK: - Feature A: Combo + Volatiles
    static let comboWindow: Double = 4.0
    static let volatileChance: Double = 0.12
    static let volatileFuse: Double = 10.0
    static let volatileBonusMultiplier: Double = 2.0
    static let starRespawnInterval: Double = 2.0

    static func multiplier(forCombo count: Int) -> Int {
        switch count {
        case 0...1: return 1
        case 2...3: return 2
        case 4...5: return 3
        default: return 5
        }
    }

    // MARK: - Feature B: Stalker + Vortex
    static let noiseDecayPerSecond: Double = 0.03
    static let stalkerNoiseThreshold: Double = 0.55
    static let stalkerBaseSpeed: CGFloat = 170
    static let stalkerHuntSpeed: CGFloat = 260
    static let stalkerDamage: Double = 0.25
    static let stalkerDespawnNoise: Double = 0.15
    static let vortexSlingshotBonus: Int = 10

    // MARK: - Feature C: Storms
    static let stormInterval: Double = 110.0
    static let stormInitialDelay: Double = 45.0
    static let stormDuration: Double = 30.0
    static let stormPOICount: Int = 4
    static let stormScanBonus: CGFloat = 250.0
}
