import Foundation
import SwiftUI

/// Archives view for browsing discovered lore entries.
/// Organized by region and category for easy navigation.
struct ArchivesView: View {
    @ObservedObject var gameState = GameState.shared
    @State private var selectedRegion: Region?
    @State private var selectedEntry: LoreEntry?
    @State private var searchText = ""
    
    var filteredEntries: [LoreEntry] {
        var entries = LoreSystem.discoveredEntries(gameState: gameState)
        
        if let region = selectedRegion {
            entries = entries.filter { $0.region == region }
        }
        
        if !searchText.isEmpty {
            entries = entries.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return entries.sorted { $0.region.rawValue < $1.region.rawValue }
    }
    
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
                    
                    Text("Archives")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(gameState.discoveredLore.count)/\(LoreSystem.allEntries.count)")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.5))
                    
                    TextField("Search lore...", text: $searchText)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white)
                        .accentColor(.cyan)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                // Region filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedRegion == nil) {
                            selectedRegion = nil
                        }
                        
                        ForEach(Region.allCases) { region in
                            FilterChip(
                                title: region.displayName,
                                isSelected: selectedRegion == region
                            ) {
                                selectedRegion = region
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)
                
                // Lore entries list
                if filteredEntries.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No lore discovered yet")
                            .font(.system(size: 18, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                        Text("Explore the galaxy to uncover the story of the Astrals")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredEntries) { entry in
                                LoreEntryCard(entry: entry) {
                                    selectedEntry = entry
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            LoreDetailView(entry: entry)
        }
    }
}

/// Filter chip for region selection
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.cyan : Color.white.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

/// Card displaying a lore entry summary
struct LoreEntryCard: View {
    let entry: LoreEntry
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Category icon
                Image(systemName: entry.category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.cyan)
                    .frame(width: 40, height: 40)
                    .background(Color.cyan.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(entry.region.displayName)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

/// Detail view for reading a full lore entry
struct LoreDetailView: View {
    let entry: LoreEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.08)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(entry.category.rawValue)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.cyan)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(entry.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(entry.region.displayName)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.cyan)
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        Text(entry.content)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}
