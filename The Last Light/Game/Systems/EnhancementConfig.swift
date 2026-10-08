import Foundation

/// Centralized configuration for all enhanced gameplay features.
/// Allows fine-tuning of game feel without code changes.
struct EnhancementConfig {
    
    // MARK: - Signal Echo Risk Accumulation
    
    /// How much risk accumulates per POI interaction (0 = no accumulation)
    static let riskPerDiscovery: Double = 0.25
    
    /// Maximum risk before penalties begin (as percentage of max)
    static let riskThreshold: Double = 0.75
    
    /// Risk penalty multiplier after exceeding threshold
    static let riskOverageMultiplier: Double = 1.5
    
    // MARK: - Ghost Signal POI Decay
    
    /// Time in seconds before undiscovered POIs begin fading (0 = instant decay)
    static let ghostDecayStartTime: TimeInterval = 300.0
    
    /// Total time for complete POI fadeout after decay start time
    static let ghostDecayDuration: TimeInterval = 120.0
    
    // MARK: - Memory Anchors
    
    /// How many safe regions where players can save memory anchors (0 to disable)
    static let maxMemoryAnchorRegions: Int = 3
    
    // MARK: - Visual Features
    
    /// Enable ghost trails (faint outlines of explored POIs)
    static var enableGhostTrails: Bool = true
    
    /// Ghost trail duration in seconds
    static let ghostTrailDuration: TimeInterval = 30.0
    
    // MARK: - Constellation Memory
    
    /// Minimum stars collected to begin tracking constellations
    static let constellationThreshold: Int = 25
    
    /// Stars required per constellation pattern
    static let constellationPointsRequired: Int = 6
    
    // MARK: - Sound Effects
    
    /// Enable dynamic ambient layering (safety sound vs danger sound)
    static var enableDynamicAmbience: Bool = true
    
    // MARK: - UI Feedback
    
    /// Show resource collection numbers on screen ("+3 Fragments")
    static var enableFloatingText: Bool = true
    
}
