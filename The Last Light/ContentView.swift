import Foundation
import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject private var gameState = GameState.shared
    @State private var gameScene: GameScene?
    
    var body: some View {
        ZStack {
            switch gameState.currentView {
            case .mainMenu:
                MainMenuView()
                    .transition(.opacity)
            case .game:
                GameView(scene: $gameScene)
                    .transition(.opacity)
            case .starMap:
                StarMapView()
                    .transition(.opacity)
            case .archives:
                ArchivesView()
                    .transition(.opacity)
            case .shipUpgrade:
                ShipUpgradeView()
                    .transition(.opacity)
            case .settings:
                SettingsView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gameState.currentView)
        .onAppear {
            AudioManager.shared.setup()
        }
    }
}

struct GameView: View {
    @Binding var scene: GameScene?
    @ObservedObject var gameState = GameState.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            if let gameScene = scene {
                SpriteView(scene: gameScene)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }
            GameUI(scene: scene)
        }
        .onAppear {
            if scene == nil {
                let newScene = GameScene(size: CGSize(width: 1000, height: 1000))
                newScene.scaleMode = .resizeFill
                scene = newScene
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { scene?.resumeScanner() }
        }
        .onDisappear {
            gameState.pauseGame()
            gameState.joystickDirection = .zero
            gameState.selectedPOIID = nil
            gameState.nearbyPOIID = nil
            scene = nil // Recreate from the saved region when returning from the map or menu.
        }
    }
}
