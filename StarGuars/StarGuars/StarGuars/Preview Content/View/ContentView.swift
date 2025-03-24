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
    @State private var showStartSheet = true // Controla la visibilidad de la sheet
    @State private var levelChanged = false // Para controlar la animación del nivel
    @State private var isPauseSheet = false // Para distinguir entre inicio y pausa
    @State private var showGoldenEffect = false // Para controlar el efecto dorado
    @State private var showHighScores = false // Para mostrar las puntuaciones más altas
    @State private var selectedShip: String = "starship3"
    @ObservedObject private var soundManager = SoundManager.shared
    
    // MARK: - Helper Methods
    // Funciones auxiliares para los meteoritos
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
                // Fondo
                Image("space")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .edgesIgnoringSafeArea(.all)
                
                // Elementos del juego (meteoritos, líneas rojas, jugador)
                if !showStartSheet {  // Solo mostramos los meteoritos si el juego ha comenzado
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
                    
                    // Líneas rojas
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
                
                // Interfaz de usuario (siempre por encima de los elementos del juego)
                VStack {
                    HStack {
                        // Puntuación
                        HStack(spacing: 0) {
                            Text("Puntos: ")
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
                        .zIndex(10) // Asegurar que esté por encima de todo
                        
                        // Botón de pausa
                        Button(action: {
                            // Feedback háptico al pausar
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
                        .zIndex(10) // Asegurar que esté por encima de todo
                        
                        Spacer()
                        
                        // Nivel con efecto dorado
                        HStack(spacing: 0) {
                            Text("Nivel ")
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
                        .zIndex(10) // Asegurar que esté por encima de todo
                    }
                    .padding(.top, 60)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .zIndex(10) // Asegurar que toda la interfaz esté por encima de los elementos del juego
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
                    // Activar la animación de escala
                    levelChanged = true
                    // Activar el efecto dorado
                    showGoldenEffect = true
                    
                    // Volver al tamaño normal después de un breve retraso
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        levelChanged = false
                    }
                    
                    // Desactivar el efecto dorado después de 3 segundos
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
                
                // Imagen del logo
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 35)
                            .stroke(Color.primary, lineWidth: 2)
                    )
                    .padding(.bottom, 20)
                
                // Título del juego
                Text("StarGuars")
                    .font(.title)
                    .foregroundColor(.primary)
                
                Text("Consigue 30 puntos y avanza de nivel.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
                Text("Hazlo o no lo hagas, pero no lo intentes. - Yoda")
                    .font(.callout)
                    .foregroundColor(.indigo)
                    .padding(.top, 5)
                
                Spacer()
                
                // Mostrar la última puntuación si existe
                if let score = lastScore {
                    VStack(spacing: 5) {
                        Text("Última puntuación")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("\(score)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.bottom, 30)
                }
                
                // Selector de naves (solo visible si no estamos en pausa)
                if !isPaused {
                    Spacer()
                    
                    Text("Has escogido:")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.bottom, 5)
                    
                    ShipNameText(name: shipNames[selectedShip] ?? "")
                        .padding(.bottom, 20)
                    
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
                                            // Fondo del recuadro (gris para no seleccionado, AnimatedMeshGradient para seleccionado)
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
                                            
                                            // Borde para la nave seleccionada
                                            if selectedShip == ship {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 2.5)
                                                    .frame(width: 86, height: 86)
                                                    .transition(.opacity)
                                            }
                                            
                                            // Imagen de la nave
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
                                // Centrar en la nave seleccionada cuando aparece el ScrollView
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
                
                // Botón de empezar/continuar
                Button(action: {
                    isPresented = false
                    if isPaused {
                        // Si estamos en pausa, solo reanudamos
                        viewModel.resumeGame()
                    } else {
                        // Si es inicio, iniciamos nuevo juego
                        viewModel.initializePlayer(with: geometry.size)
                        viewModel.startGame()
                    }
                }) {
                    Text(isPaused ? "Continuar jugando" : "¡Empezar!")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.indigo.gradient)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 15)
                
                // Versión de la app
                Text("Versión 1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                // Al aparecer la vista, establecemos el valor por defecto
                if !isPaused {
                    // Solo si no estamos en pausa (inicio del juego)
                    selectedShip = "starship3"
                    viewModel.selectedShipImage = "starship3"
                    
                    // Ya no necesitamos centrar el ScrollView aquí
                    // porque lo hacemos con el ScrollViewReader
                } else {
                    // Si estamos en pausa, mantenemos la nave actual
                    selectedShip = viewModel.selectedShipImage
                }
            }
            .toolbar {
                // Control de música de fondo
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.spring(response: 0.2)) {
                            soundManager.toggleMusic()
                        }
                        // Feedback háptico al cambiar música
                        let musicFeedback = UIImpactFeedbackGenerator(style: .light)
                        musicFeedback.impactOccurred()
                    }) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .indigo]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: soundManager.isMusicEnabled ? "play.fill" : "play.slash.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .symbolRenderingMode(.hierarchical)
                                    .contentTransition(.symbolEffect(.replace.downUp))
                                    .foregroundColor(.white)
                            )
                            .animation(.spring(response: 0.2), value: soundManager.isMusicEnabled)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.trailing, 4)
                }
                
                // Control de efectos de sonido
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.spring(response: 0.2)) {
                            soundManager.toggleSoundEffects()
                        }
                        // Feedback háptico al cambiar efectos de sonido
                        let soundFeedback = UIImpactFeedbackGenerator(style: .light)
                        soundFeedback.impactOccurred()
                    }) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .indigo]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: soundManager.isSoundEffectsEnabled ? "bell.fill" : "bell.slash.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .symbolRenderingMode(.hierarchical)
                                    .contentTransition(.symbolEffect(.replace.downUp))
                                    .foregroundColor(.white)
                            )
                            .animation(.spring(response: 0.2), value: soundManager.isSoundEffectsEnabled)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                // Botón de información
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showInfo = true }) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .indigo]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "lightbulb.2.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.trailing, -4)
                }
                
                // Botón de práctica
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Text("Estas partidas no se registran en el Podium.")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Divider()
                        
                        Button(action: {
                            isPresented = false
                            viewModel.initializePlayer(with: geometry.size)
                            viewModel.startPracticeGame(fromLevel: 5)
                        }) {
                            Label("Empezar desde nivel 5", systemImage: "5.circle")
                        }
                        
                        Button(action: {
                            isPresented = false
                            viewModel.initializePlayer(with: geometry.size)
                            viewModel.startPracticeGame(fromLevel: 10)
                        }) {
                            Label("Empezar desde nivel 10", systemImage: "10.circle")
                        }
                        
                        Button(action: {
                            isPresented = false
                            viewModel.initializePlayer(with: geometry.size)
                            viewModel.startPracticeGame(fromLevel: 15)
                        }) {
                            Label("Empezar desde nivel 15", systemImage: "15.circle")
                        }
                        
                        Button(action: {
                            isPresented = false
                            viewModel.initializePlayer(with: geometry.size)
                            viewModel.startPracticeGame(fromLevel: 20)
                        }) {
                            Label("Empezar desde nivel 20", systemImage: "20.circle")
                        }
                    } label: {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .indigo]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.trailing, -4)
                }
                
                // Botón del podium
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showHighScores = true }) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .indigo]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 80, height: 32)
                            .overlay(
                                Text("Podium")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
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
                // Consejo 1: Láser
                InfoCard(
                    icon: "deathstar",
                    title: "Cuidado con el láser mortal",
                    description: "El láser cambia de verde a rojo antes de activarse.\nMantente alejado de las líneas naranjas laterales.",
                    useCustomImage: true
                )
                
                // Consejo 2: Meteoritos
                InfoCard(
                    icon: "meteor",
                    title: "Tipos de meteoritos",
                    description: "Más progreses, más meteoritos aparecerán.\nLos meteoritos grandes valen más puntos.",
                    useCustomImage: true
                )
                
                // Consejo 3: Naves
                InfoCard(
                    icon: "starship3",
                    title: "Elige tu nave",
                    description: "Cada nave espacial tiene un tamaño diferente.\nExperimenta para encontrar la que mejor te funcione.",
                    useCustomImage: true
                )
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .navigationTitle("Consejos para jugar")
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
            // Imagen grande centrada
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
            
            // Título y descripción
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
            // Sombra de fondo que cambia de color
            Rectangle()
                .fill(redLine.laserColor.opacity(0.15))
                .frame(width: 20, height: geometry.size.height)
                .position(x: redLine.center.x, y: geometry.size.height / 2)
                .opacity(redLine.opacity * 0.8)
                .blur(radius: redLine.glowRadius * 2)
            
            // Líneas naranjas laterales (posición fija)
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
            
            // Línea roja central
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
