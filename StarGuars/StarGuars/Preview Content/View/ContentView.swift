import SwiftUI

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

struct ContentView: View {
    @EnvironmentObject var viewModel: ViewModel
    @State private var showStartSheet = true // Controla la visibilidad de la sheet
    @State private var levelChanged = false // Para controlar la animación del nivel
    @State private var isPauseSheet = false // Para distinguir entre inicio y pausa
    @State private var showGoldenEffect = false // Para controlar el efecto dorado
    @State private var showHighScores = false // Para mostrar las puntuaciones más altas
    @State private var selectedShip: String = "starship"
    @ObservedObject private var soundManager = SoundManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("space")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack {
                        // Puntuación
                        HStack(spacing: 0) {
                            Text("Puntuación: ")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.white)
                            NumericText(value: viewModel.score)
                                .font(.headline)
                                .bold()
                                .foregroundColor(.white)
                            Text("/\(viewModel.level * 30)")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.6))
                        )
                        
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
                        
                        Spacer()
                        
                        // Nivel con efecto dorado
                        HStack(spacing: 0) {
                            Text("Nivel ")
                                .font(.headline)
                                .bold()
                                .foregroundColor(showGoldenEffect ? Color(red: 1.0, green: 0.84, blue: 0.0) : .white)
                            NumericText(value: viewModel.level)
                                .font(.headline)
                                .bold()
                                .foregroundColor(showGoldenEffect ? Color(red: 1.0, green: 0.84, blue: 0.0) : .white)
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
                    }
                    .padding(.top, 60)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                
                if !showStartSheet {  // Solo mostramos los obstáculos si el juego ha comenzado
                    ForEach(viewModel.obstacles) { obstacle in
                        Image(obstacle.imageName ?? (obstacle.isZigzag ? "meteor2" : (obstacle.isBig ? "deathstar" : (viewModel.level >= 10 ? "meteor3" : "meteor"))))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: obstacle.isBig ? 100 : (obstacle.isZigzag ? 60 : 80), 
                                   height: obstacle.isBig ? 100 : (obstacle.isZigzag ? 60 : 80))
                            .rotationEffect(.degrees(obstacle.rotation))
                            .scaleEffect(obstacle.isSpecial ? 1.2 : 1.0)
                            .opacity(obstacle.isZigzag ? 0.9 : 1.0)
                            .position(obstacle.center)
                            .animation(
                                obstacle.isSpecial ? 
                                    .linear(duration: 0.2) :
                                    (obstacle.isBig ?
                                        .linear(duration: 0.5) :
                                        .linear(duration: 0.3)),
                                value: obstacle.rotation
                            )
                    }
                    
                    // Líneas rojas
                    ForEach(viewModel.redLines.indices, id: \.self) { index in
                        let redLine = viewModel.redLines[index]
                        // Líneas naranjas laterales
                        Rectangle()
                            .fill(redLine.sideLineColor)
                            .frame(width: 6, height: geometry.size.height)
                            .position(x: redLine.xPosition - (redLine.isBeaming ? (redLine.beamWidth/2 + 3) : redLine.beamWidth/2), y: geometry.size.height / 2)
                            .opacity(redLine.leftLineOpacity)
                            .shadow(color: redLine.sideLineColor.opacity(redLine.orangeLineShadowOpacity), radius: 10, x: 0, y: 0)
                        
                        Rectangle()
                            .fill(redLine.sideLineColor)
                            .frame(width: 6, height: geometry.size.height)
                            .position(x: redLine.xPosition + (redLine.isBeaming ? (redLine.beamWidth/2 + 3) : redLine.beamWidth/2), y: geometry.size.height / 2)
                            .opacity(redLine.rightLineOpacity)
                            .shadow(color: redLine.sideLineColor.opacity(redLine.orangeLineShadowOpacity), radius: 10, x: 0, y: 0)
                        
                        // Línea roja central
                        Rectangle()
                            .fill(redLine.laserColor)
                            .frame(width: 4, height: geometry.size.height)
                            .position(x: redLine.xPosition, y: geometry.size.height / 2)
                            .opacity(redLine.opacity)
                            .shadow(color: redLine.laserColor.opacity(redLine.shadowOpacity), radius: 10, x: 0, y: 0)
                    }
                    
                    if let player = viewModel.player {
                        Image(viewModel.selectedShipImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: viewModel.selectedShipImage == "starship3" || viewModel.selectedShipImage == "starship4" ? player.width * 0.8 : player.width, 
                                   height: viewModel.selectedShipImage == "starship3" || viewModel.selectedShipImage == "starship4" ? player.height * 0.8 : player.height)
                            .position(player.center)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        viewModel.movePlayer(to: value.location)
                                    }
                            )
                    }
                }
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

// Vista para la sheet inicial/pausa
struct StartView: View {
    @Binding var isPresented: Bool
    let geometry: GeometryProxy
    let lastScore: Int?
    let isPaused: Bool // Nuevo parámetro para saber si estamos en pausa
    @EnvironmentObject var viewModel: ViewModel
    @State private var selectedShip: String = "starship"
    @State private var showHighScores: Bool = false // Para mostrar las puntuaciones
    @State private var showInfo: Bool = false // Para mostrar la vista de información
    @ObservedObject private var soundManager = SoundManager.shared
    
    let shipOptions = ["starship", "starship2", "starship3", "starship4", "starship5"]
    
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
                    
                    Text("Rápido rebelde... ¡escoge tu nave!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(shipOptions, id: \.self) { ship in
                                Button(action: {
                                    // Añadir feedback háptico al seleccionar una nave
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.prepare()
                                    impactFeedback.impactOccurred()
                                    
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedShip = ship
                                        viewModel.selectedShipImage = ship
                                    }
                                }) {
                                    ZStack {
                                        // Fondo del botón
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedShip == ship ? 
                                                Color.indigo.opacity(0.2) :
                                                Color.gray.opacity(0.1))
                                            .frame(width: 90, height: 90)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.white.opacity(0.05))
                                                    .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                                            )
                                        
                                        // Imagen de la nave
                                        Image(ship)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: ship == "starship" || ship == "starship2" || ship == "starship5" ? 70 : 60,
                                                   height: ship == "starship" || ship == "starship2" || ship == "starship5" ? 70 : 60)
                                            .scaleEffect(selectedShip == ship ? 1.1 : 1.0)
                                    }
                                    .frame(width: 90, height: 90)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
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
                // Al aparecer la sheet, actualizamos el selectedShip
                selectedShip = viewModel.selectedShipImage
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
                        Text("Estas partidas no se registran en el Podium")
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
                                Image(systemName: "star.fill")
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

// Nueva vista de información
struct InfoView: View {
    @Binding var isPresented: Bool
    
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

// Componente reutilizable para las tarjetas de información
struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    let useCustomImage: Bool
    
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

// Añadir este struct al final del archivo, justo antes del último cierre de llave
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}
