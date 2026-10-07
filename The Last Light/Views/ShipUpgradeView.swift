import Foundation
import SwiftUI

/// Ship upgrade view for spending Star Energy on ship improvements.
/// Displays all available upgrades with their current levels and costs.
struct ShipUpgradeView: View {
    @ObservedObject var gameState = GameState.shared
    @State private var showPurchaseConfirmation = false
    @State private var selectedUpgrade: UpgradeType?
    @State private var showPurchaseSuccess = false
    @State private var purchaseMessage = ""
    
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.08)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { gameState.currentView = .mainMenu }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Ship")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Star energy display
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(gameState.starEnergy)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Ship stats summary
                ShipStatsView(stats: gameState.shipStats)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // Upgrades list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(UpgradeType.allCases) { upgrade in
                            UpgradeCard(
                                upgrade: upgrade,
                                currentLevel: gameState.upgradeLevels[upgrade] ?? 0,
                                canAfford: gameState.starEnergy >= (upgrade.cost(forLevel: (gameState.upgradeLevels[upgrade] ?? 0) + 1)),
                                onPurchase: {
                                    selectedUpgrade = upgrade
                                    showPurchaseConfirmation = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .alert("Purchase Upgrade?", isPresented: $showPurchaseConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Purchase") {
                if let upgrade = selectedUpgrade {
                    if gameState.purchaseUpgrade(upgrade) {
                        purchaseMessage = "\(upgrade.displayName) upgraded to level \(gameState.upgradeLevels[upgrade] ?? 0)!"
                        showPurchaseSuccess = true
                        AudioManager.shared.playEffect("upgrade")
                    }
                }
            }
        } message: {
            if let upgrade = selectedUpgrade {
                let currentLevel = gameState.upgradeLevels[upgrade] ?? 0
                if currentLevel < upgrade.maxLevel {
                    Text("Upgrade \(upgrade.displayName) to level \(currentLevel + 1) for \(upgrade.cost(forLevel: currentLevel + 1)) Star Energy?")
                }
            }
        }
        .alert("Success!", isPresented: $showPurchaseSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseMessage)
        }
    }
}

/// Displays current ship stats
struct ShipStatsView: View {
    let stats: ShipStats
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Wayfarer")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Stats")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            HStack(spacing: 16) {
                StatItem(icon: "battery.100", label: "Energy", value: "\(Int(stats.maxEnergy))")
                StatItem(icon: "shield.fill", label: "Shield", value: "\(Int(stats.maxShield))")
                StatItem(icon: "speedometer", label: "Speed", value: "\(Int(stats.speed))")
            }
            
            HStack(spacing: 16) {
                StatItem(icon: "circle.dashed", label: "Collector", value: "\(Int(stats.collectionRadius))")
                StatItem(icon: "radar", label: "Scanner", value: "\(Int(stats.scannerRange))")
                StatItem(icon: "arrow.triangle.2.circlepath", label: "Turn", value: String(format: "%.1f", stats.turnRate))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

/// Individual stat display
struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.cyan)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

/// Card displaying an upgrade option
struct UpgradeCard: View {
    let upgrade: UpgradeType
    let currentLevel: Int
    let canAfford: Bool
    let onPurchase: () -> Void
    
    var isMaxed: Bool {
        currentLevel >= upgrade.maxLevel
    }
    
    var nextCost: Int? {
        guard currentLevel < upgrade.maxLevel else { return nil }
        return upgrade.cost(forLevel: currentLevel + 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: upgrade.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.cyan)
                    .frame(width: 40, height: 40)
                    .background(Color.cyan.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(upgrade.displayName)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(upgrade.description)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Level indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Lv. \(currentLevel)/\(upgrade.maxLevel)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.cyan)
                    
                    // Level pips
                    HStack(spacing: 4) {
                        ForEach(0..<upgrade.maxLevel, id: \.self) { level in
                            Circle()
                                .fill(level < currentLevel ? Color.cyan : Color.white.opacity(0.2))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            
            // Current effect
            Text(upgrade.effectDescription(forLevel: currentLevel))
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            
            // Next level effect
            if !isMaxed {
                Text("Next: \(upgrade.effectDescription(forLevel: currentLevel + 1))")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.cyan.opacity(0.7))
            }
            
            // Purchase button
            if !isMaxed {
                Button(action: onPurchase) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                        Text("\(nextCost!) Star Energy")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(canAfford ? .white : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(canAfford ? Color.cyan.opacity(0.3) : Color.white.opacity(0.05))
                    .cornerRadius(10)
                }
                .disabled(!canAfford)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                    Text("MAX LEVEL")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}
