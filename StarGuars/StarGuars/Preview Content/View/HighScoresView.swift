//
//  HighScoresView.swift
//  StarGuars
//
//  Created by Xavier Moreno on 10/3/25.
//

import SwiftUI
import SwiftData

// MARK: - HighScores View
struct HighScoresView: View {
    // MARK: - Properties
    @EnvironmentObject var viewModel: ViewModel
    @Query(sort: \Item.score, order: .reverse) private var highScores: [Item]
    @Binding var isPresented: Bool
    @State private var showSortOptions = false
    @State private var sortOption: SortOption = .score
    @State private var showPodiumAnimation = false
    
    // MARK: - Sort Option Enum
    enum SortOption: String, CaseIterable, Identifiable {
        case score = "Score"
        case date = "Most Recent"
        case shipType = "Ship Type"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Helper Methods
    private func sortByScore(_ items: [Item]) -> [Item] {
        items.sorted { $0.score > $1.score }
    }
    
    private func sortByDate(_ items: [Item]) -> [Item] {
        items.sorted { $0.timestamp > $1.timestamp }
    }
    
    private func sortByShipType(_ items: [Item]) -> [Item] {
        items.sorted { $0.shipType < $1.shipType }
    }
    
    private var sortedScores: [Item] {
        let scores = highScores
        switch sortOption {
        case .score:
            return sortByScore(scores)
        case .date:
            return sortByDate(scores)
        case .shipType:
            return sortByShipType(scores)
        }
    }
    
    // MARK: - Body View
    var body: some View {
        NavigationView {
            ZStack {
                // Animated Mesh Gradient
                AnimatedBackgroundView()
                
                // Main content with fade in
                VStack(spacing: 0) {
                    if highScores.isEmpty {
                        emptyScoresView
                            .transition(.opacity)
                    } else {
                        scoreboardView
                            .transition(.opacity)
                    }
                }
                .animation(.easeIn(duration: 0.3), value: highScores.isEmpty)
                .navigationTitle("Podium")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(SortOption.allCases) { option in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        sortOption = option
                                    }
                                } label: {
                                    Text(option.rawValue)
                                        .foregroundStyle(Color.primary)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Color.white)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    private var emptyScoresView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "square.and.arrow.down.badge.clock")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 80))
                .foregroundColor(.white)
                .padding(.bottom, 10)
            
            Text("No saved scores yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 5)
            
            Text("Play to record your first score!")
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    private var scoreboardView: some View {
        VStack(spacing: 0) {
            // Podium for the top three
            if sortedScores.count >= 1 {
                podiumView
                    .padding(.bottom, 16)
                    .padding(.top, 8)
            }
            
            // Scoreboard table
            ScrollView {
                VStack(spacing: 8) {
                    // Top 10
                    ForEach(sortedScores.prefix(10).indices, id: \.self) { index in
                        scoreRowView(index: index, item: sortedScores[index])
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: sortOption)
                            .id("\(sortedScores[index].timestamp.timeIntervalSince1970)_\(index)")
                    }
                    
                    // Visual separator
                    if sortedScores.count > 10 {
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .padding(.vertical, 8)
                    }
                    
                    // Positions 11-20
                    if sortedScores.count > 10 {
                        ForEach(10..<min(20, sortedScores.count), id: \.self) { index in
                            scoreRowView(index: index, item: sortedScores[index])
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: sortOption)
                                .id("\(sortedScores[index].timestamp.timeIntervalSince1970)_\(index)")
                        }
                    }
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 16)
            }
        }
    }
    
    private var podiumView: some View {
        ZStack(alignment: .bottom) {
            // Base line of the podium
            Rectangle()
                .fill(Color.white.opacity(0.9))
                .frame(height: 4)
                .offset(y: -8)
                .shadow(color: .white.opacity(0.3), radius: 4, y: 2)
            
            HStack(alignment: .bottom, spacing: 0) {
                // Second place
                if sortedScores.count >= 2 {
                    VStack(spacing: 6) {
                        // Ship image
                        Image(sortedScores[1].shipType)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                            .opacity(showPodiumAnimation ? 1 : 0)
                        
                        Text("\(sortedScores[1].score)p")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(showPodiumAnimation ? 1 : 0)
                        
                        // Silver medal
                        Image(systemName: "2.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 22))
                            .foregroundColor(.gray)
                            .opacity(showPodiumAnimation ? 1 : 0)
                        
                        // Podium
                        Rectangle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 60, height: 60)
                            .clipShape(
                                RoundedCorner(radius: 8, corners: [.topLeft, .topRight])
                            )
                            .scaleEffect(y: showPodiumAnimation ? 1 : 0, anchor: .bottom)
                    }
                    .frame(width: 80)
                } else {
                    Spacer()
                        .frame(width: 80)
                }
                
                // First place
                VStack(spacing: 6) {
                    // Ship image
                    Image(sortedScores[0].shipType)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                        .opacity(showPodiumAnimation ? 1 : 0)
                    
                    Text("\(sortedScores[0].score)p")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(showPodiumAnimation ? 1 : 0)
                    
                    // Gold crown
                    Image(systemName: "medal.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.yellow)
                        .opacity(showPodiumAnimation ? 1 : 0)
                    
                    // Podium
                    Rectangle()
                        .fill(Color.yellow.opacity(0.7))
                        .frame(width: 70, height: 80)
                        .clipShape(
                            RoundedCorner(radius: 8, corners: [.topLeft, .topRight])
                        )
                        .scaleEffect(y: showPodiumAnimation ? 1 : 0, anchor: .bottom)
                }
                .frame(width: 90)
                
                // Third place
                if sortedScores.count >= 3 {
                    VStack(spacing: 6) {
                        // Ship image
                        Image(sortedScores[2].shipType)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                            .opacity(showPodiumAnimation ? 1 : 0)
                        
                        Text("\(sortedScores[2].score)p")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(showPodiumAnimation ? 1 : 0)
                        
                        // Bronze medal
                        Image(systemName: "3.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 20))
                            .foregroundColor(.brown)
                            .opacity(showPodiumAnimation ? 1 : 0)
                        
                        // Podium
                        Rectangle()
                            .fill(Color.brown.opacity(0.6))
                            .frame(width: 60, height: 40)
                            .clipShape(
                                RoundedCorner(radius: 8, corners: [.topLeft, .topRight])
                            )
                            .scaleEffect(y: showPodiumAnimation ? 1 : 0, anchor: .bottom)
                    }
                    .frame(width: 80)
                } else {
                    Spacer()
                        .frame(width: 80)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.5)) {
                showPodiumAnimation = true
            }
        }
    }
    
    private func scoreRowView(index: Int, item: Item) -> some View {
        HStack(spacing: 4) {
            // Position
            Text("\(index + 1)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(index < 3 ? medalColor(for: index) : .gray)
                .frame(width: 25, alignment: .center)
            
            // Ship
            Image(item.shipType)
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .padding(4)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                )
            
            // Central information
            VStack(alignment: .leading, spacing: 2) {
                Text("Level \(item.level)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(formattedDate(item.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            
            // Score
            HStack(spacing: 4) {
                Text("\(item.score)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(index < 3 ? medalColor(for: index) : .white)
                
                Text("pts")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 8)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.5))
                .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Helper UI Methods
    private func medalColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .blue
        case 2: return .purple
        default: return .gray
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Animated Background View
struct AnimatedBackgroundView: View {
    // MARK: - Properties
    @State private var time: Double = 0
    
    // MARK: - Body View
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // First gradient layer
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.3),
                        Color.black
                    ]),
                    center: .init(x: 0.5 + sin(time * 0.1) * 0.15,
                                y: 0.5 + cos(time * 0.1) * 0.15),
                    startRadius: 1,
                    endRadius: geometry.size.width
                )
                
                // Second gradient layer
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.0, green: 0.0, blue: 0.2).opacity(0.7),
                        Color.clear
                    ]),
                    center: .init(x: 0.5 + cos(time * 0.08) * 0.15,
                                y: 0.5 + sin(time * 0.08) * 0.15),
                    startRadius: 1,
                    endRadius: geometry.size.width * 0.8
                )
                .blendMode(.plusLighter)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                time = Date().timeIntervalSinceReferenceDate
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Rounded Corner Shape
struct RoundedCorner: Shape {
    // MARK: - Properties
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    // MARK: - Shape Methods
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
} 
