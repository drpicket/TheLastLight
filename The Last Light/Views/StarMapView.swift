import Foundation
import SwiftUI

/// Star map view for selecting and traveling between regions.
/// Shows all regions with their unlock status and requirements.
struct StarMapView: View {
    @ObservedObject var gameState = GameState.shared
    @State private var selectedRegion: Region?
    @State private var showTravelConfirmation = false
    
    var body: some View {
        ZStack {
            // Background
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
                    
                    Text("Star Map")
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
                
                // Region list
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Region.allCases) { region in
                            RegionCard(
                                region: region,
                                isUnlocked: gameState.unlockedRegions.contains(region),
                                isCurrent: gameState.currentRegion == region,
                                isSelected: selectedRegion == region,
                                totalStars: gameState.totalStarsCollected,
                                onSelect: { selectedRegion = region }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                
                // Travel button
                if let region = selectedRegion, gameState.unlockedRegions.contains(region), region != gameState.currentRegion {
                    Button(action: { showTravelConfirmation = true }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Travel to \(region.displayName)")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .alert("Travel to \(selectedRegion?.displayName ?? "")?", isPresented: $showTravelConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Travel") {
                if let region = selectedRegion {
                    gameState.travelToRegion(region)
                    gameState.currentView = .game
                }
            }
        } message: {
            Text("Your ship will warp to this region. Energy will be restored.")
        }
    }
}

/// Card displaying region information
struct RegionCard: View {
    let region: Region
    let isUnlocked: Bool
    let isCurrent: Bool
    let isSelected: Bool
    let totalStars: Int
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            if isUnlocked {
                onSelect()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(region.displayName)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(isUnlocked ? .white : .gray)
                        
                        if !isUnlocked {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12))
                                Text("Collect \(region.unlockRequirement) stars to unlock")
                                    .font(.system(size: 12, design: .rounded))
                            }
                            .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    if isCurrent {
                        Text("CURRENT")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cyan.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                Text(region.description)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(isUnlocked ? .white.opacity(0.7) : .gray.opacity(0.5))
                    .lineLimit(2)
                
                if isUnlocked {
                    HStack(spacing: 16) {
                        Label("\(region.starCount)", systemImage: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow.opacity(0.7))
                        
                        Label("\(region.asteroidCount)", systemImage: "circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.7))
                        
                        if region.hasGravityAnomalies {
                            Label("Anomalies", systemImage: "waveform")
                                .font(.system(size: 12))
                                .foregroundColor(.purple.opacity(0.7))
                        }
                        
                        if region.hasAncientStructures {
                            Label("Ancient", systemImage: "building.columns.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange.opacity(0.7))
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.cyan.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.cyan.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .disabled(!isUnlocked)
    }
}
