import Foundation
import SwiftUI

enum Region: String, Codable, CaseIterable, Identifiable, Hashable {
    case silentBelt = "silent_belt"
    case shatteredNebula = "shattered_nebula"
    case forgottenOrbit = "forgotten_orbit"
    case blackExpanse = "black_expanse"
    case heart = "heart"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .silentBelt: return "The Silent Belt"
        case .shatteredNebula: return "The Shattered Nebula"
        case .forgottenOrbit: return "The Forgotten Orbit"
        case .blackExpanse: return "The Black Expanse"
        case .heart: return "The Heart"
        }
    }
    
    var description: String {
        switch self {
        case .silentBelt:
            return "A beautiful asteroid belt filled with scattered stars and the remnants of abandoned spacecraft."
        case .shatteredNebula:
            return "A colorful nebula where gravitational anomalies twist space itself."
        case .forgottenOrbit:
            return "The remains of an ancient Astral structure orbiting a dying star."
        case .blackExpanse:
            return "A vast darkness where almost no stars remain. Something pulled them away."
        case .heart:
            return "The mysterious location toward which all collected stars appear to be traveling."
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .silentBelt: return Color(red: 0.02, green: 0.02, blue: 0.08)
        case .shatteredNebula: return Color(red: 0.05, green: 0.02, blue: 0.12)
        case .forgottenOrbit: return Color(red: 0.08, green: 0.05, blue: 0.02)
        case .blackExpanse: return Color(red: 0.01, green: 0.01, blue: 0.03)
        case .heart: return Color(red: 0.12, green: 0.02, blue: 0.05)
        }
    }
    
    var nebulaColors: [Color] {
        switch self {
        case .silentBelt:
            return [Color.blue.opacity(0.1), Color.purple.opacity(0.08)]
        case .shatteredNebula:
            return [Color.pink.opacity(0.15), Color.cyan.opacity(0.12), Color.orange.opacity(0.08)]
        case .forgottenOrbit:
            return [Color.yellow.opacity(0.1), Color.orange.opacity(0.08)]
        case .blackExpanse:
            return [Color.gray.opacity(0.05), Color.black.opacity(0.1)]
        case .heart:
            return [Color.red.opacity(0.15), Color.pink.opacity(0.1)]
        }
    }
    
    var starWeights: [StarType: Int] {
        switch self {
        case .silentBelt:
            return [.small: 70, .blue: 20, .golden: 8, .ancient: 2]
        case .shatteredNebula:
            return [.small: 40, .blue: 35, .golden: 18, .ancient: 7]
        case .forgottenOrbit:
            return [.small: 30, .blue: 30, .golden: 28, .ancient: 12]
        case .blackExpanse:
            return [.small: 50, .blue: 30, .golden: 15, .ancient: 5]
        case .heart:
            return [.small: 20, .blue: 25, .golden: 30, .ancient: 25]
        }
    }
    
    var starCount: Int {
        switch self {
        case .silentBelt: return 80
        case .shatteredNebula: return 100
        case .forgottenOrbit: return 90
        case .blackExpanse: return 50
        case .heart: return 120
        }
    }
    
    var asteroidCount: Int {
        switch self {
        case .silentBelt: return 25
        case .shatteredNebula: return 30
        case .forgottenOrbit: return 35
        case .blackExpanse: return 45
        case .heart: return 20
        }
    }
    
    var asteroidSpeedMultiplier: Double {
        switch self {
        case .silentBelt: return 1.0
        case .shatteredNebula: return 1.3
        case .forgottenOrbit: return 1.1
        case .blackExpanse: return 1.5
        case .heart: return 0.8
        }
    }
    
    var hasGravityAnomalies: Bool {
        switch self {
        case .shatteredNebula, .heart: return true
        default: return false
        }
    }
    
    var hasAncientStructures: Bool {
        switch self {
        case .forgottenOrbit, .heart: return true
        default: return false
        }
    }
    
    var energyDrainRate: Double {
        switch self {
        case .silentBelt: return 0.005
        case .shatteredNebula: return 0.008
        case .forgottenOrbit: return 0.01
        case .blackExpanse: return 0.015
        case .heart: return 0.003
        }
    }
    
    var unlockRequirement: Int {
        switch self {
        case .silentBelt: return 0
        case .shatteredNebula: return 50
        case .forgottenOrbit: return 150
        case .blackExpanse: return 300
        case .heart: return 500
        }
    }
    
    func isUnlocked(gameState: GameState) -> Bool {
        return gameState.totalStarsCollected >= unlockRequirement
    }
    
    var loreEntryIds: [String] {
        switch self {
        case .silentBelt: return ["transmission_01", "ship_log_01", "signal_01"]
        case .shatteredNebula: return ["transmission_02", "astral_log_01", "signal_02"]
        case .forgottenOrbit: return ["transmission_03", "astral_log_02", "ship_log_02"]
        case .blackExpanse: return ["transmission_04", "signal_03", "astral_log_03"]
        case .heart: return ["transmission_05", "astral_log_04", "final_signal"]
        }
    }
}
