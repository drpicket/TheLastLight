import Foundation
import SwiftUI

/// Settings view for configuring game options.
/// Includes audio, graphics, and save data management.
struct SettingsView: View {
    @ObservedObject var gameState = GameState.shared
    @State private var showDeleteConfirmation = false
    @State private var showAbout = false
    
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
                    
                    Text("Settings")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Audio section
                        SettingsSection(title: "Audio") {
                            SettingsToggle(
                                title: "Sound Effects",
                                icon: "speaker.wave.2.fill",
                                isOn: $gameState.soundEnabled
                            )
                            
                            SettingsToggle(
                                title: "Music",
                                icon: "music.note",
                                isOn: $gameState.musicEnabled
                            )
                        }
                        
                        // Graphics section
                        SettingsSection(title: "Graphics") {
                            SettingsToggle(
                                title: "Screen Shake",
                                icon: "iphone.radiowaves.left.and.right",
                                isOn: .constant(true)
                            )
                            
                            SettingsToggle(
                                title: "Particle Effects",
                                icon: "sparkles",
                                isOn: .constant(true)
                            )
                        }
                        
                        // Data section
                        SettingsSection(title: "Data") {
                            SettingsButton(
                                title: "Delete Save Data",
                                icon: "trash.fill",
                                iconColor: .red,
                                action: { showDeleteConfirmation = true }
                            )
                        }
                        
                        // About section
                        SettingsSection(title: "About") {
                            SettingsButton(
                                title: "About Starfall",
                                icon: "info.circle.fill",
                                iconColor: .cyan,
                                action: { showAbout = true }
                            )
                            
                            HStack {
                                Text("Version")
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text("1.0.0")
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onChange(of: gameState.soundEnabled) { _, newValue in
            gameState.saveGame()
        }
        .onChange(of: gameState.musicEnabled) { _, newValue in
            if newValue {
                AudioManager.shared.startAmbientMusic()
            } else {
                AudioManager.shared.stopAmbientMusic()
            }
            gameState.saveGame()
        }
        .alert("Delete Save Data?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                SaveSystem.deleteSave()
                gameState.starEnergy = 0
                gameState.currentRegion = .silentBelt
                gameState.unlockedRegions = [.silentBelt]
                gameState.discoveredLore = []
                gameState.upgradeLevels = [:]
                gameState.totalStarsCollected = 0
                gameState.resources = [.energy: 50, .fragments: 0, .signal: 0]
                gameState.discoveredPOIs = []
                gameState.completedPOIs = []
                gameState.selectedPOIID = nil
                gameState.nearbyPOIID = nil
                POIManager.shared.clear()
                gameState.hasStartedGame = false
                gameState.currentView = .mainMenu
            }
        } message: {
            Text("This will permanently delete all your progress, upgrades, and discovered lore.")
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }
}

/// Settings section container
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.cyan)
                .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                content
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

/// Toggle row in settings
struct SettingsToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// Button row in settings
struct SettingsButton: View {
    let title: String
    let icon: String
    var iconColor: Color = .cyan
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

/// About view
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.08)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Text("STARFALL")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("The Last Light")
                        .font(.system(size: 18, weight: .light, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("A 2D space exploration game about collecting scattered stars and uncovering the mystery of the ancient Astrals.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
                
                Spacer()
                
                Text("Built with Swift and SpriteKit")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 40)
            }
        }
    }
}
