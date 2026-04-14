import SwiftUI

struct StartView: View {
    @Binding var isPresented: Bool
    let geometry: GeometryProxy
    let lastScore: Int?
    let isPaused: Bool

    @EnvironmentObject private var viewModel: ViewModel
    @State private var selectedShip: String = "starship3"
    @State private var showHighScores = false
    @State private var showInfo = false
    @ObservedObject private var soundManager = SoundManager.shared

    private let shipOptions = ["starship", "starship2", "starship3", "starship4", "starship5"]
    private let shipNames = [
        "starship": "T-65B X-Wing Starfighter",
        "starship2": "ARC-170 Starfighter",
        "starship3": "Classic X-Wing",
        "starship4": "B-Wing Starfighter",
        "starship5": "Podracer 620C"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer(minLength: 56)

                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 35)
                            .stroke(Color.primary, lineWidth: 2)
                    )
                    .padding(.bottom, 20)

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

                Spacer(minLength: 24)

                if !isPaused {
                    Spacer(minLength: 12)

                    Text("You have chosen:")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.bottom, 8)

                    ShipNameText(name: shipNames[selectedShip] ?? "")
                        .padding(.bottom, 16)

                    ShipPickerView(
                        shipOptions: shipOptions,
                        selectedShip: $selectedShip,
                        onSelect: selectShip
                    )
                    .padding(.bottom, 12)
                }

                Spacer(minLength: isPaused ? 56 : 24)

                lastScoreLine

                Button(action: primaryAction) {
                    Text(isPaused ? "Continue Playing" : "Start Game!")
                        .bold()
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.indigo.gradient)
                        .cornerRadius(26)
                }
                .padding(.horizontal)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear(perform: configureInitialSelection)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: toggleMusic) {
                        Image(systemName: soundManager.isMusicEnabled ? "speaker.circle" : "speaker.slash.circle")
                            .symbolRenderingMode(.hierarchical)
                            .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                    }

                    Button(action: toggleSoundEffects) {
                        Image(systemName: soundManager.isSoundEffectsEnabled ? "bell.circle" : "bell.slash.circle")
                            .symbolRenderingMode(.hierarchical)
                            .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showInfo = true
                    } label: {
                        Image(systemName: "lightbulb.2")
                            .symbolRenderingMode(.hierarchical)
                    }

                    practiceMenu

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
            InfoView()
        }
    }

    private var practiceMenu: some View {
        Menu {
            Text("These games will not be registered in the Podium.")
            Divider()
            practiceButton(for: 5)
            practiceButton(for: 10)
            practiceButton(for: 15)
            practiceButton(for: 20)
        } label: {
            Image(systemName: "shuffle")
                .symbolRenderingMode(.hierarchical)
        }
    }

    private var lastScoreLine: some View {
        Group {
            if let score = lastScore {
                Text("Last score: \(score)")
            } else {
                Text("Last score: \(Image(systemName: "flag.filled.and.flag.crossed"))")
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundColor(.secondary)
        .padding(.bottom, 10)
    }

    private func practiceButton(for level: Int) -> some View {
        Button {
            startPracticeGame(from: level)
        } label: {
            Label("Start from level \(level)", systemImage: "\(level).circle")
        }
    }

    private func configureInitialSelection() {
        if isPaused {
            selectedShip = viewModel.selectedShipImage
        } else {
            selectedShip = "starship3"
            viewModel.selectedShipImage = "starship3"
        }
    }

    private func selectShip(_ ship: String) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedShip = ship
            viewModel.selectedShipImage = ship
        }
    }

    private func primaryAction() {
        isPresented = false

        if isPaused {
            viewModel.resumeGame()
        } else {
            viewModel.initializePlayer(with: geometry.size)
            viewModel.startGame()
        }
    }

    private func startPracticeGame(from level: Int) {
        isPresented = false
        viewModel.initializePlayer(with: geometry.size)
        viewModel.startPracticeGame(fromLevel: level)
    }

    private func toggleMusic() {
        withAnimation(.spring(response: 0.2)) {
            soundManager.toggleMusic()
        }

        let musicFeedback = UIImpactFeedbackGenerator(style: .light)
        musicFeedback.impactOccurred()
    }

    private func toggleSoundEffects() {
        withAnimation(.spring(response: 0.2)) {
            soundManager.toggleSoundEffects()
        }

        let soundFeedback = UIImpactFeedbackGenerator(style: .light)
        soundFeedback.impactOccurred()
    }
}

private struct ShipPickerView: View {
    let shipOptions: [String]
    @Binding var selectedShip: String
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 15) {
                    ForEach(shipOptions, id: \.self) { ship in
                        Button {
                            onSelect(ship)
                        } label: {
                            ZStack {
                                if selectedShip == ship {
                                    AnimatedMeshGradient(cornerRadius: 26, size: CGSize(width: 90, height: 90))
                                        .frame(width: 90, height: 90)
                                } else {
                                    RoundedRectangle(cornerRadius: 26)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 90, height: 90)
                                        .background(
                                            RoundedRectangle(cornerRadius: 26)
                                                .fill(Color.white.opacity(0.05))
                                                .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                                        )
                                }

                                if selectedShip == ship {
                                    RoundedRectangle(cornerRadius: 26)
                                        .strokeBorder(Color.white.opacity(0.95), lineWidth: 2.5)
                                        .frame(width: 84, height: 84)
                                        .transition(.opacity)
                                }

                                Image(ship)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: shipFrame(for: ship).width, height: shipFrame(for: ship).height)
                                    .scaleEffect(selectedShip == ship ? 1.1 : 1.0)
                            }
                            .frame(width: 96, height: 96)
                            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedShip)
                            .id(ship)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .onAppear {
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
            .frame(height: 108)
        }
    }

    private func shipFrame(for ship: String) -> CGSize {
        let size: CGFloat = ["starship", "starship2", "starship5"].contains(ship) ? 70 : 60
        return CGSize(width: size, height: size)
    }
}
