import Foundation
import SpriteKit

/// CONSTELLATION MEMORY - pattern recognition from collected stars + storm chains.
enum ConstellationPattern: String, CaseIterable, Codable {
    case lyraTriangle = "Lyra Triangle"
    case veilArc = "Veil Arc"
    case heartCross = "Heart Cross"

    var requiredGolden: Int {
        switch self {
        case .lyraTriangle: return 2
        case .veilArc: return 1
        case .heartCross: return 2
        }
    }
    var requiredTotal: Int {
        switch self {
        case .lyraTriangle: return 3
        case .veilArc: return 4
        case .heartCross: return 5
        }
    }
    var rewardSignal: Int {
        switch self {
        case .lyraTriangle: return 20
        case .veilArc: return 30
        case .heartCross: return 50
        }
    }
    var rewardFragments: Int {
        switch self {
        case .lyraTriangle: return 8
        case .veilArc: return 12
        case .heartCross: return 20
        }
    }
}

class ConstellationMemory {
    static let shared = ConstellationMemory()
    private init() {}

    private var recentTypes: [StarType] = []
    private let maxRecent = 12

    var collectedCount: Int { GameState.shared.totalStarsCollected }

    func isAtConstellationThreshold() -> Bool {
        collectedCount >= EnhancementConfig.constellationThreshold
    }

    func trackStarCollection(type: StarType) {
        recentTypes.append(type)
        if recentTypes.count > maxRecent { recentTypes.removeFirst() }
        discoverPatterns()
    }

    func removeStar() {
        if !recentTypes.isEmpty { recentTypes.removeFirst() }
    }

    @discardableResult
    func discoverPatterns() -> ConstellationPattern? {
        guard isAtConstellationThreshold() else { return nil }
        let gs = GameState.shared
        // Sliding window over recent picks; deterministic, no randomness.
        for pattern in ConstellationPattern.allCases {
            guard !gs.completedConstellations.contains(pattern.rawValue) else { continue }
            let window = recentTypes.suffix(pattern.requiredTotal)
            guard window.count == pattern.requiredTotal else { continue }
            let golden = window.filter { $0 == .golden || $0 == .ancient }.count
            if golden >= pattern.requiredGolden {
                gs.completeConstellation(
                    named: pattern.rawValue,
                    rewardSignal: pattern.rewardSignal,
                    rewardFragments: pattern.rewardFragments
                )
                NotificationCenter.default.post(name: .poiCompleted, object: pattern.rawValue)
                recentTypes.removeAll()
                return pattern
            }
        }
        return nil
    }

    /// Storm chain: completing storm POIs in order forges a constellation.
    func checkStormChain(chainIndex: Int, needed: Int) -> ConstellationPattern? {
        guard chainIndex >= needed else { return nil }
        let gs = GameState.shared
        // Award first incomplete constellation.
        for pattern in ConstellationPattern.allCases {
            if !gs.completedConstellations.contains(pattern.rawValue) {
                gs.completeConstellation(
                    named: pattern.rawValue,
                    rewardSignal: pattern.rewardSignal + 10,
                    rewardFragments: pattern.rewardFragments + 5
                )
                return pattern
            }
        }
        // All done: still vent + reward.
        gs.ventRisk(EnhancementConfig.constellationRiskVent)
        gs.addResource(.signal, amount: 15)
        return nil
    }
}
