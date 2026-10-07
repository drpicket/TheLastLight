import Foundation
import SwiftUI

/// The main menu screen. Provides access to all game features.
struct MainMenuView: View {
    @ObservedObject var gameState = GameState.shared
    @State private var showNewGameConfirmation = false
    @State private var animateTitle = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.08),
                    Color(red: 0.05, green: 0.02, blue: 0.12),
                    Color(red: 0.02, green: 0.02, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Animated stars background
            StarsBackground()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Title
                VStack(spacing: 8) {
                    Text("STARFALL")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .cyan.opacity(0.5), radius: 10)
                        .scaleEffect(animateTitle ? 1.0 : 0.8)
                        .opacity(animateTitle ? 1.0 : 0.0)
                    
                    Text("The Last Light")
                        .font(.system(size: 18, weight: .light, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(animateTitle ? 1.0 : 0.0)
                }
                .padding(.bottom, 60)
                
                // Menu buttons
                VStack(spacing: 16) {
                    if gameState.hasStartedGame {
                        MainMenuButton(title: "Continue", icon: "play.fill") {
                            gameState.continueGame()
                        }
                    }
                    
                    MainMenuButton(title: gameState.hasStartedGame ? "New Journey" : "Begin Journey", icon: "sparkles") {
                        if gameState.hasStartedGame {
                            showNewGameConfirmation = true
                        } else {
                            gameState.startNewGame()
                        }
                    }
                    
                    MainMenuButton(title: "Ship", icon: "airplane") {
                        gameState.currentView = .shipUpgrade
                    }
                    
                    MainMenuButton(title: "Star Map", icon: "map.fill") {
                        gameState.currentView = .starMap
                    }
                    
                    MainMenuButton(title: "Archives", icon: "book.fill") {
                        gameState.currentView = .archives
                    }
                    
                    MainMenuButton(title: "Settings", icon: "gearshape.fill") {
                        gameState.currentView = .settings
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Version info
                Text("v1.0")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateTitle = true
            }
        }
        .alert("Start New Journey?", isPresented: $showNewGameConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Start", role: .destructive) {
                gameState.startNewGame()
            }
        } message: {
            Text("This will erase your current progress.")
        }
    }
}

/// Animated stars background for the menu
struct StarsBackground: View {
    @State private var animate = false
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: false)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                for i in 0..<50 {
                    let x = (sin(Double(i) * 123.456 + time * 0.1) * 0.5 + 0.5) * size.width
                    let y = (cos(Double(i) * 789.012 + time * 0.15) * 0.5 + 0.5) * size.height
                    let brightness = (sin(Double(i) * 345.678 + time * 2.0) * 0.5 + 0.5)
                    
                    let rect = CGRect(x: x, y: y, width: 2, height: 2)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(brightness * 0.5)))
                }
            }
        }
    }
}

/// Main menu button component
struct MainMenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(width: 28, height: 28)
                
                Text(title)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .opacity(0.5)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Button scale animation style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
