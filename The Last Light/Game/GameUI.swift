import Foundation
import SwiftUI
import SpriteKit

struct GameUI: View {
    let scene: GameScene?
    @ObservedObject var gameState = GameState.shared
    @State private var showPauseMenu = false
    @State private var showLoreNotification = false
    @State private var lastLoreEntry: LoreEntry?
    @State private var showRegionNotification = false
    @State private var lastUnlockedRegion: Region?
    @State private var showStarCollection = false
    @State private var lastCollectedStar: StarType?
    @State private var showDiscoveryNotification = false
    @State private var lastDiscoveredPOI: POI?
    @State private var lastCompletedPOI: POI?
    @State private var discoveryLineIndex = 0
    
    var body: some View {
        ZStack {
            // Top HUD
            VStack {
                HStack {
                    // Resources display
                    HStack(spacing: 12) {
                        ResourceDisplay(icon: "bolt.fill", value: gameState.getResource(.energy), color: .yellow)
                        ResourceDisplay(icon: "cube.fill", value: gameState.getResource(.fragments), color: .cyan)
                        ResourceDisplay(icon: "waveform", value: gameState.getResource(.signal), color: .purple)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    Text(gameState.currentRegion.displayName)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(20)
                    
                    Button(action: { showPauseMenu = true }) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(18)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
                
                // Virtual Joystick - bottom left
                HStack {
                    VirtualJoystick()
                        .padding(.leading, 20)
                        .padding(.bottom, 20)
                    Spacer()
                }
                
                // Bottom HUD - Energy and Shield bars
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "battery.100")
                            .font(.system(size: 12))
                            .foregroundColor(energyColor)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.black.opacity(0.4))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(energyColor)
                                    .frame(width: geometry.size.width * gameState.shipEnergy, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 12))
                            .foregroundColor(shieldColor)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.black.opacity(0.4))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(shieldColor)
                                    .frame(width: geometry.size.width * gameState.shipShield, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            
            // Scanner display - top right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ScannerDisplay()
                        .padding(.trailing, 16)
                        .padding(.bottom, 100)
                }
            }
            
            // Right-side contextual action leaves the movement control free.
            if gameState.activeDiscovery == nil,
               let id = gameState.nearbyPOIID,
               let poi = POIManager.shared.getPOI(by: id),
               let prompt = ScannerSystem.shared.getInteractionPrompt(for: poi) {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { scene?.interactWithNearbyPOI() } label: {
                            Label(prompt, systemImage: poi.type.icon)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(poi.canInteract ? Color.cyan.opacity(0.75) : Color.gray.opacity(0.7))
                                .cornerRadius(20)
                        }
                        .disabled(!poi.canInteract)
                        .padding(.trailing, 16)
                        .padding(.bottom, 65)
                    }
                }
            }
            
            // POI Discovery notification
            if showDiscoveryNotification, let poi = lastDiscoveredPOI {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: poi.type.icon)
                                .font(.system(size: 20))
                                .foregroundColor(Color(poi.type.color))
                            Text("POI Discovered")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Text(poi.displayName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(poi.type.color))
                        
                        if let hint = poi.discoveryHint {
                            Text(hint)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: showDiscoveryNotification)
            }
            
            if let poi = lastCompletedPOI {
                VStack {
                    Spacer()
                    Text(poi.type == .stellarFragment ? "Stellar Fragment collected" :
                         poi.type == .unknownSignal ? "Unknown Signal decoded" :
                         "\(poi.displayName) investigated")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.cyan)
                        .padding(12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .padding(.bottom, 165)
                }
                .allowsHitTesting(false)
            }

            // Star collection notification
            if showStarCollection, let starType = lastCollectedStar {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(Color(starType.color))
                            Text("+\(starType.energyValue)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(25)
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .animation(.spring(), value: showStarCollection)
            }
            
            // Lore discovery notification
            if showLoreNotification, let entry = lastLoreEntry {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: entry.category.icon)
                                .font(.system(size: 20))
                                .foregroundColor(.cyan)
                            Text("New Lore Discovered")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Text(entry.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                        
                        Button(action: {
                            showLoreNotification = false
                            gameState.currentView = .archives
                        }) {
                            Text("View in Archives")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.cyan.opacity(0.3))
                                .cornerRadius(20)
                        }
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: showLoreNotification)
            }
            
            // Region unlock notification
            if showRegionNotification, let region = lastUnlockedRegion {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                            Text("New Region Unlocked")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Text(region.displayName)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                        
                        Text(region.description)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: showRegionNotification)
            }

            if let discovery = gameState.activeDiscovery {
                Color.black.opacity(0.65).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 18) {
                    Label("TRANSMISSION RECOVERED", systemImage: discovery.icon)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                    Text(discovery.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(discovery.lines[min(discoveryLineIndex, discovery.lines.count - 1)])
                        .font(.system(size: 17, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                    if discoveryLineIndex == discovery.lines.count - 1, let question = discovery.question {
                        Text(question)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.cyan)
                    }
                    Button(discoveryLineIndex < discovery.lines.count - 1 ? "Continue" : "Recover Evidence") {
                        if discoveryLineIndex < discovery.lines.count - 1 {
                            discoveryLineIndex += 1
                        } else {
                            scene?.completeActiveDiscovery()
                        }
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.cyan)
                    .cornerRadius(10)
                }
                .padding(20)
                .frame(maxWidth: 380)
                .background(Color(red: 0.04, green: 0.07, blue: 0.14))
                .cornerRadius(16)
                .padding(20)
            }
        }
        .onChange(of: gameState.activeDiscovery?.id) { _, _ in
            discoveryLineIndex = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .starCollected)) { notification in
            if let starType = notification.object as? StarType {
                lastCollectedStar = starType
                showStarCollection = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showStarCollection = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .loreDiscovered)) { notification in
            if let entry = notification.object as? LoreEntry {
                lastLoreEntry = entry
                showLoreNotification = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showLoreNotification = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .regionUnlocked)) { notification in
            if let region = notification.object as? Region {
                lastUnlockedRegion = region
                showRegionNotification = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showRegionNotification = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .poiDiscovered)) { notification in
            if let poi = notification.object as? POI {
                lastDiscoveredPOI = poi
                showDiscoveryNotification = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showDiscoveryNotification = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .poiCompleted)) { notification in
            if let poi = notification.object as? POI {
                lastCompletedPOI = poi
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    if lastCompletedPOI?.id == poi.id { lastCompletedPOI = nil }
                }
            }
        }
        .sheet(isPresented: $showPauseMenu) {
            PauseMenuView(isPresented: $showPauseMenu)
        }
    }
    
    private var energyColor: Color {
        if gameState.shipEnergy > 0.5 {
            return .green
        } else if gameState.shipEnergy > 0.25 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private var shieldColor: Color {
        if gameState.shipShield > 0.5 {
            return .cyan
        } else if gameState.shipShield > 0.25 {
            return .orange
        } else {
            return .red
        }
    }
}

struct ResourceDisplay: View {
    let icon: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text("\(value)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

struct ScannerDisplay: View {
    @ObservedObject var gameState = GameState.shared

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(gameState.lastScanResults.isEmpty ? "SCANNING NEARBY SPACE" : "SCAN · TAP TO TRACK")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.cyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)

            ForEach(gameState.lastScanResults.prefix(3), id: \.id) { poi in
                let distance = Int(hypot(poi.position.x - gameState.playerPosition.x,
                                         poi.position.y - gameState.playerPosition.y))
                Button {
                    gameState.selectedPOIID = poi.id == gameState.selectedPOIID ? nil : poi.id
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: poi.type.icon)
                            .foregroundColor(Color(poi.type.color))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(poi.displayName)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text("\(poi.riskLevel.displayName) · \(distance)m")
                                .font(.system(size: 9, design: .rounded))
                                .foregroundColor(Color(poi.riskLevel.color))
                        }
                        if gameState.selectedPOIID == poi.id {
                            Image(systemName: "location.fill").foregroundColor(.cyan)
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(gameState.selectedPOIID == poi.id ? Color.cyan.opacity(0.3) : Color.black.opacity(0.65))
                    .cornerRadius(9)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct VirtualJoystick: View {
    @ObservedObject var gameState = GameState.shared
    @State private var knobPosition: CGSize = .zero
    @State private var isDragging = false
    
    private let baseSize: CGFloat = 120
    private let knobSize: CGFloat = 50
    private let maxKnobDistance: CGFloat = 35
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: baseSize, height: baseSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
            
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: knobSize, height: knobSize)
                .offset(knobPosition)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            let translation = value.translation
                            let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
                            let clampedDistance = min(distance, maxKnobDistance)
                            let angle = atan2(translation.height, translation.width)
                            knobPosition = CGSize(
                                width: cos(angle) * clampedDistance,
                                height: sin(angle) * clampedDistance
                            )
                            
                            let normalizedX = knobPosition.width / maxKnobDistance
                            let normalizedY = knobPosition.height / maxKnobDistance
                            gameState.joystickDirection = CGVector(dx: normalizedX, dy: normalizedY)
                        }
                        .onEnded { _ in
                            isDragging = false
                            knobPosition = .zero
                            gameState.joystickDirection = .zero
                        }
                )
        }
        .frame(width: baseSize, height: baseSize)
    }
}

struct PauseMenuView: View {
    @Binding var isPresented: Bool
    @ObservedObject var gameState = GameState.shared
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("PAUSED")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    MenuButton(title: "Resume", icon: "play.fill") {
                        isPresented = false
                        gameState.isPlaying = true
                    }
                    
                    MenuButton(title: "Star Map", icon: "map.fill") {
                        isPresented = false
                        gameState.currentView = .starMap
                    }
                    
                    MenuButton(title: "Archives", icon: "book.fill") {
                        isPresented = false
                        gameState.currentView = .archives
                    }
                    
                    MenuButton(title: "Settings", icon: "gearshape.fill") {
                        isPresented = false
                        gameState.currentView = .settings
                    }
                    
                    MenuButton(title: "Main Menu", icon: "house.fill") {
                        isPresented = false
                        gameState.returnToMenu()
                    }
                }
            }
            .padding(40)
        }
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

extension Notification.Name {
    static let starCollected = Notification.Name("starCollected")
    static let loreDiscovered = Notification.Name("loreDiscovered")
    static let regionUnlocked = Notification.Name("regionUnlocked")
    static let poiDiscovered = Notification.Name("poiDiscovered")
    static let poiCompleted = Notification.Name("poiCompleted")
}
