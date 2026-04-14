import SwiftUI

// MARK: - Auxiliary Components
// Componente para animar números
struct NumericText: View {
    let value: Int
    let format: String
    
    @State private var animatedValue: Double
    
    init(value: Int, format: String = "%d") {
        self.value = value
        self.format = format
        self._animatedValue = State(initialValue: Double(value))
    }
    
    var body: some View {
        Text(String(format: format, Int(animatedValue)))
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animatedValue = Double(value)
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animatedValue = Double(newValue)
                }
            }
    }
}

// Componente para animar el nombre de la nave
struct ShipNameText: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(.title3)
            .bold()
            .foregroundColor(.indigo)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: name)
    }
}

// MARK: - Main View
struct ContentView: View {
    // MARK: - Properties
    @EnvironmentObject var viewModel: ViewModel
    @State private var showStartSheet = true // Controls the visibility of the sheet
    @State private var levelChanged = false // Controls the level animation
    @State private var isPauseSheet = false // Distinguishes between start and pause
    @State private var showGoldenEffect = false // Controls the golden effect
    @State private var showHighScores = false // Shows the highest scores
    @State private var selectedShip: String = "starship3"
    @ObservedObject private var soundManager = SoundManager.shared
    
    // MARK: - Helper Methods
    // Helper functions for meteors
    private func getObstacleImageName(for meteorito: Meteorito) -> String {
        if let imageName = meteorito.imageName {
            return imageName
        }
        if meteorito.isZigzag {
            return "meteor2"
        }
        if meteorito.isBig {
            return "deathstar"
        }
        return viewModel.level >= 10 ? "meteor3" : "meteor"
    }
    
    private func getObstacleSize(for meteorito: Meteorito) -> CGFloat {
        if meteorito.isBig {
            return 100
        }
        if meteorito.isZigzag {
            return 60
        }
        return 80
    }
    
    private func getObstacleAnimationDuration(for meteorito: Meteorito) -> Double {
        if meteorito.isSpecial {
            return 0.2
        }
        if meteorito.isBig {
            return 0.5
        }
        return 0.3
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Image("space")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .edgesIgnoringSafeArea(.all)
                
                // Game elements (meteors, red lines, player)
                if !showStartSheet {  // Only show meteors if the game has started
                    ForEach(viewModel.obstacles) { meteorito in
                        let imageName = getObstacleImageName(for: meteorito)
                        let size = getObstacleSize(for: meteorito)
                        let duration = getObstacleAnimationDuration(for: meteorito)
                        
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: size, height: size)
                            .rotationEffect(.degrees(meteorito.rotation))
                            .scaleEffect(meteorito.isSpecial ? 1.2 : 1.0)
                            .opacity(meteorito.isColliding ? meteorito.collisionOpacity : (meteorito.isZigzag ? 0.9 : 1.0))
                            .position(meteorito.center)
                            .animation(.linear(duration: duration), value: meteorito.rotation)
                            .animation(.easeOut(duration: 0.3), value: meteorito.collisionOpacity)
                    }
                    
                    // Red lines
                    ForEach(viewModel.redLines) { redLine in
                        RedLineView(redLine: redLine, geometry: geometry)
                    }
                    
                    if let player = viewModel.player {
                        Image(viewModel.selectedShipImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: player.width, height: player.height)
                            .position(player.center)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        viewModel.movePlayer(to: value.location)
                                    }
                            )
                    }
                }
                
                // User interface (always above game elements)
                VStack {
                    HStack {
                        // Score
                        HStack(spacing: 0) {
                            Text("Points: ")
                                .font(.headline.monospaced())
                                .bold()
                                .foregroundColor(.white)
                            Text("\(viewModel.score)")
                                .font(.headline.monospaced())
                                .bold()
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.score)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.6))
                        )
                        .zIndex(10) // Make sure it's above everything
                        
                        // Pause button
                        Button(action: {
                            // Haptic feedback when pausing
                            let pauseFeedback = UIImpactFeedbackGenerator(style: .medium)
                            pauseFeedback.prepare()
                            pauseFeedback.impactOccurred()
                            
                            viewModel.pauseGame()
                            isPauseSheet = true
                            showStartSheet = true
                        }) {
                            Image(systemName: "pause.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.6))
                                )
                        }
                        .zIndex(10) // Make sure it's above everything
                        
                        Spacer()
                        
                        // Level with golden effect
                        HStack(spacing: 0) {
                            Text("Level ")
                                .font(.headline.monospaced())
                                .bold()
                                .foregroundColor(showGoldenEffect ? Color(red: 1.0, green: 0.84, blue: 0.0) : .white)
                            Text("\(viewModel.level)")
                                .font(.headline.monospaced())
                                .bold()
                                .foregroundColor(showGoldenEffect ? Color(red: 1.0, green: 0.84, blue: 0.0) : .white)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.level)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.6))
                        )
                        .scaleEffect(levelChanged ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: levelChanged)
                        .overlay(
                            showGoldenEffect ?
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color(red: 1.0, green: 0.84, blue: 0.0), lineWidth: 2)
                                    .opacity(showGoldenEffect ? 1 : 0)
                            : nil
                        )
                        .zIndex(10) // Make sure it's above everything
                    }
                    .padding(.top, 60)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .zIndex(10) // Make sure the entire interface is above the game elements
            }
            .sheet(isPresented: $showStartSheet, onDismiss: nil) {
                StartView(
                    isPresented: $showStartSheet,
                    geometry: geometry,
                    lastScore: viewModel.lastScore,
                    isPaused: isPauseSheet
                )
                .interactiveDismissDisabled(true)
            }
            .sheet(isPresented: $showHighScores) {
                HighScoresView(isPresented: $showHighScores)
            }
            .onChange(of: viewModel.level) { oldValue, newValue in
                if oldValue != newValue {
                    // Activate scale animation
                    levelChanged = true
                    // Activate golden effect
                    showGoldenEffect = true
                    
                    // Return to normal size after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        levelChanged = false
                    }
                    
                    // Deactivate golden effect after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation {
                            showGoldenEffect = false
                        }
                    }
                }
            }
            .onChange(of: viewModel.isGameOver) { oldValue, newValue in
                if newValue {
                    viewModel.lastScore = viewModel.score
                    isPauseSheet = false
                    showStartSheet = true
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Start View
struct StartView: View {
    // MARK: - Properties
    @Binding var isPresented: Bool
    let geometry: GeometryProxy
    let lastScore: Int?
    let isPaused: Bool
    @EnvironmentObject var viewModel: ViewModel
    @State private var selectedShip: String = "starship3"
    @State private var showHighScores: Bool = false
    @State private var showInfo: Bool = false
    @ObservedObject private var soundManager = SoundManager.shared
    
    let shipOptions = ["starship", "starship2", "starship3", "starship4", "starship5"]
    let shipNames = [
        "starship": "T-65B X-Wing Starfighter",
        "starship2": "ARC-170 Starfighter",
        "starship3": "Classic X-Wing",
        "starship4": "B-Wing Starfighter",
        "starship5": "Podracer 620C"
    ]
    
    // MARK: - Helper Methods
    func getShipWidth(ship: String) -> CGFloat {
        return ship == "starship" || ship == "starship2" || ship == "starship5" ? 70 : 60
    }
    
    func getShipHeight(ship: String) -> CGFloat {
        return ship == "starship" || ship == "starship2" || ship == "starship5" ? 70 : 60
    }
    
    // MARK: - Body View
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                
                // Logo image
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 35)
                            .stroke(Color.primary, lineWidth: 2)
                    )
                    .padding(.bottom, 20)
                
                // Game title
                Text("StarGuars")
                    .font(.title)
                    .foregroundColor(.primary)
                
                Text("Score 30 points to advance to the next level.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
                Text("Do or do not, there is no try. - Yoda")
                    .font(.callout)
                    .foregroundColor(.indigo)
                    .padding(.top)
                
                Spacer()
                
                // Show last score if it exists
                if let score = lastScore {
                    VStack(spacing: 5) {
                        Text("Last score:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("\(score)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.bottom, 30)
                }
                
                // Ship selector (only visible if not paused)
                if !isPaused {
                    Spacer()
                    
                    Text("You have chosen:")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.bottom, 10)
                    
                    ShipNameText(name: shipNames[selectedShip] ?? "")
                        .padding(.bottom, 30)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        ScrollViewReader { proxy in
                            HStack(spacing: 15) {
                                ForEach(shipOptions, id: \.self) { ship in
                                    Button(action: {
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.prepare()
                                        impactFeedback.impactOccurred()
                                        
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedShip = ship
                                            viewModel.selectedShipImage = ship
                                        }
                                    }) {
                                        ZStack {
                                            // Background for the box (gray for unselected, AnimatedMeshGradient for selected)
                                            if selectedShip == ship {
                                                AnimatedMeshGradient(cornerRadius: 12, size: CGSize(width: 90, height: 90))
                                                    .frame(width: 90, height: 90)
                                            } else {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.gray.opacity(0.1))
                                                    .frame(width: 90, height: 90)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(Color.white.opacity(0.05))
                                                            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                                                    )
                                            }
                                            
                                            // Border for selected ship
                                            if selectedShip == ship {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 2.5)
                                                    .frame(width: 86, height: 86)
                                                    .transition(.opacity)
                                            }
                                            
                                            // Ship image
                                            Image(ship)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: getShipWidth(ship: ship), height: getShipHeight(ship: ship))
                                                .scaleEffect(selectedShip == ship ? 1.1 : 1.0)
                                        }
                                        .frame(width: 90, height: 90)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedShip)
                                        .id(ship)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .onAppear {
                                // Center on the selected ship when the ScrollView appears
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        proxy.scrollTo(selectedShip, anchor: .center)
                                    }
                                }
                            }
                            .onChange(of: selectedShip) { _, newShip in
                                withAnimation {
                                    proxy.scrollTo(newShip, anchor: .center)
                                }
                            }
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .padding(.bottom, 20)
                    }
                }
                
                // Start/continue button
                Button(action: {
                    isPresented = false
                    if isPaused {
                        // If paused, just resume
                        viewModel.resumeGame()
                    } else {
                        // If starting, begin new game
                        viewModel.initializePlayer(with: geometry.size)
                        viewModel.startGame()
                    }
                }) {
                    Text(isPaused ? "Continue Playing" : "Start Game!")
                        .bold()
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.indigo.gradient)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 15)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                // When the view appears, set the default value
                if !isPaused {
                    // Only if not paused (game start)
                    selectedShip = "starship3"
                    viewModel.selectedShipImage = "starship3"
                    
                    // We no longer need to center the ScrollView here
                    // because we do it with the ScrollViewReader
                } else {
                    // If paused, keep the current ship
                    selectedShip = viewModel.selectedShipImage
                }
            }
            .toolbar {
                // Background music control
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.2)) {
                            soundManager.toggleMusic()
                        }
                        let musicFeedback = UIImpactFeedbackGenerator(style: .light)
                        musicFeedback.impactOccurred()
                    } label: {
                        Image(systemName: soundManager.isMusicEnabled ? "speaker.circle" : "speaker.slash.circle")
                            .symbolRenderingMode(.hierarchical)
                            .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                    }
                }
                
                // Sound effects control
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.2)) {
                            soundManager.toggleSoundEffects()
                        }
                        let soundFeedback = UIImpactFeedbackGenerator(style: .light)
                        soundFeedback.impactOccurred()
                    } label: {
                        Image(systemName: soundManager.isSoundEffectsEnabled ? "bell.circle" : "bell.slash.circle")
                            .symbolRenderingMode(.hierarchical)
                            .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                    }
                }
                
                // Info button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showInfo = true
                    } label: {
                        Image(systemName: "lightbulb.2")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                
                // Practice button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Text("These games will not be registered in the Podium.")
                        
                        Divider()
                        
                        Button {
                            isPresented = false
                            viewModel.initializePlayer(with: geometry.size)
                            viewModel.startPracticeGame(fromLevel: 5)
                        } label: {
                            Label("Start from level 5", systemImage: "5.circle")
                        }
                        
                        Button {
                            isPresented = false
                            viewModel.initializePlayer(with: geometry.size)
                            viewModel.startPracticeGame(fromLevel: 10)
                        } label: {
                            Label("Start from level 10", systemImage: "10.circle")
                        }
                        
                        Button {
                            isPresented = false
                            viewModel.initializePlayer(with: geometry.size)
                            viewModel.startPracticeGame(fromLevel: 15)
                        } label: {
                            Label("Start from level 15", systemImage: "15.circle")
                        }
                        
                        Button {
                            isPresented = false
                            viewModel.initializePlayer(with: geometry.size)
                            viewModel.startPracticeGame(fromLevel: 20)
                        } label: {
                            Label("Start from level 20", systemImage: "20.circle")
                        }
                    } label: {
                        Image(systemName: "shuffle")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                
                // Podium button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showHighScores = true
                    } label: {
                        Image(systemName: "star.hexagon")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
        .sheet(isPresented: $showHighScores) {
            HighScoresView(isPresented: $showHighScores)
        }
        .sheet(isPresented: $showInfo) {
            InfoView(isPresented: $showInfo)
        }
    }
}

// MARK: - Info View
struct InfoView: View {
    // MARK: - Properties
    @Binding var isPresented: Bool
    
    // MARK: - Body View
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Tip 1: Laser
                InfoCard(
                    icon: "deathstar",
                    title: "Beware of the Death Laser",
                    description: "The laser changes from green to red before activating. Stay away from the orange lines on the sides.",
                    useCustomImage: true
                )
                
                // Tip 2: Meteors
                InfoCard(
                    icon: "meteor",
                    title: "Types of Meteors",
                    description: "The more you progress, the more meteors will appear. Large meteors are worth more points.",
                    useCustomImage: true
                )
                
                // Tip 3: Ships
                InfoCard(
                    icon: "starship3",
                    title: "Choose Your Ship",
                    description: "Each spacecraft has a different size. Experiment to find the one that works best for you.",
                    useCustomImage: true
                )
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .navigationTitle("Game Tips")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Info Card Component
struct InfoCard: View {
    // MARK: - Properties
    let icon: String
    let title: String
    let description: String
    let useCustomImage: Bool
    
    // MARK: - Body View
    var body: some View {
        VStack(spacing: 16) {
            // Large centered image
            if useCustomImage {
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.cyan)
                    .frame(width: 80, height: 80)
            }
            
            // Title and description
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(16)
        )
    }
}

// MARK: - RedLine View Component
struct RedLineView: View {
    // MARK: - Properties
    let redLine: RedLine
    let geometry: GeometryProxy
    
    // MARK: - Body View
    var body: some View {
        ZStack {
            // Background shadow that changes color
            Rectangle()
                .fill(redLine.laserColor.opacity(0.15))
                .frame(width: 20, height: geometry.size.height)
                .position(x: redLine.center.x, y: geometry.size.height / 2)
                .opacity(redLine.opacity * 0.8)
                .blur(radius: redLine.glowRadius * 2)
            
            // Orange side lines (fixed position)
            Rectangle()
                .fill(redLine.sideLineColor)
                .frame(width: 4, height: geometry.size.height)
                .position(x: redLine.center.x - (redLine.isBeaming ? (redLine.beamWidth/2 + 6) : redLine.beamWidth/2), y: geometry.size.height / 2)
                .opacity(redLine.leftLineOpacity)
                .shadow(color: redLine.sideLineColor.opacity(redLine.orangeLineShadowOpacity), radius: redLine.glowRadius, x: 0, y: 0)
            
            Rectangle()
                .fill(redLine.sideLineColor)
                .frame(width: 4, height: geometry.size.height)
                .position(x: redLine.center.x + (redLine.isBeaming ? (redLine.beamWidth/2 + 6) : redLine.beamWidth/2), y: geometry.size.height / 2)
                .opacity(redLine.rightLineOpacity)
                .shadow(color: redLine.sideLineColor.opacity(redLine.orangeLineShadowOpacity), radius: redLine.glowRadius, x: 0, y: 0)
            
            // Central red line
            Rectangle()
                .fill(redLine.laserColor)
                .frame(width: 4, height: geometry.size.height)
                .position(x: redLine.center.x, y: geometry.size.height / 2)
                .opacity(redLine.opacity)
                .shadow(color: redLine.laserColor.opacity(redLine.shadowOpacity), radius: redLine.glowRadius, x: 0, y: 0)
        }
    }
}

// MARK: - Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}
