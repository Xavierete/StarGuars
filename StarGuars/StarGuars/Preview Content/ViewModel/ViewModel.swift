import SwiftUI
import QuartzCore  // Para CADisplayLink
import SwiftData   // Añadimos SwiftData para usar el modelo Item
import UIKit       // Para UIImpactFeedbackGenerator

class ViewModel: ObservableObject {
    @Published var player: Player?
    @Published var obstacles: [Obstacle] = []  // Array de obstáculos
    @Published var dragOffset: CGFloat = 0  // Añadimos esta propiedad para el drag gesture
    @Published var score: Int = 0  // Nueva propiedad para la puntuación
    @Published var level: Int = 1  // Nueva propiedad para el nivel
    @Published var pointsToNextLevel: Int = 30 // Nueva propiedad para mostrar puntos necesarios
    @Published var isLevelTransition: Bool = false // Para controlar la transición de nivel
    @Published var isGameOver: Bool = false  // Hacemos público isGameOver
    @Published var lastScore: Int? = nil     // Añadimos lastScore para guardar la puntuación anterior
    @Published var selectedShipImage: String = "starship" // Nueva propiedad para la imagen de la nave
    @Published var isPaused: Bool = false // Nueva propiedad para controlar la pausa
    @Published var redLines: [RedLine] = [] // Cambiar de una sola línea a un array de líneas
    @Published var isMeteorPaused: Bool = false // Añadir nueva propiedad para controlar la pausa de meteoritos
    private var canGenerateLaser: Bool = true // Nueva propiedad para controlar la generación de láseres
    
    private var displayLink: CADisplayLink?
    private var elapsedTime: Double = 0
    private var screenSize: CGSize = .zero
    private var baseObstacleSpeed: CGFloat = 3.0  // Velocidad base de los obstáculos
    private var modelContext: ModelContext? // Añadimos el contexto para SwiftData
    private let soundManager = SoundManager.shared
    
    // Estructura para manejar la línea roja
    struct RedLine {
        var xPosition: CGFloat
        var opacity: Double
        var shadowOpacity: Double
        var isActive: Bool
        var isDeadly: Bool
        var leftLineOpacity: Double
        var rightLineOpacity: Double
        var glowIntensity: Double
        var pulseScale: Double
        var beamWidth: CGFloat
        var isBeaming: Bool
        var orangeLineShadowOpacity: Double
        var glowRadius: CGFloat
        var laserColor: Color // Color del láser central
        var sideLineColor: Color // Color de las líneas laterales
        
        init(xPosition: CGFloat) {
            self.xPosition = xPosition
            self.opacity = 0.5
            self.shadowOpacity = 0.4
            self.isActive = true
            self.isDeadly = false
            self.leftLineOpacity = 0.5
            self.rightLineOpacity = 0.5
            self.glowIntensity = 0.3
            self.pulseScale = 1.0
            self.beamWidth = 24.0
            self.isBeaming = false
            self.orangeLineShadowOpacity = 0.4
            self.glowRadius = 4.0
            self.laserColor = .green
            self.sideLineColor = Color.green.opacity(0.7) // Comienza como verde claro
        }
    }
    
    init() {
        // No iniciamos el displayLink automáticamente
        soundManager.startBackgroundMusic()
    }
    
    private func setupRedLineTimer() {
        // Ya no necesitamos este método
    }
    
    private func createRedLine(at xPosition: CGFloat) {
        guard !isPaused && !isGameOver else { return }
        
        let newLine = RedLine(xPosition: xPosition)
        redLines.append(newLine)
        let lineIndex = redLines.count - 1
        
        // Ajustar el tamaño base del láser según el nivel
        let baseBeamWidth: CGFloat = level >= 10 ? 36.0 : 24.0
        let firingBeamWidth: CGFloat = level >= 10 ? 72.0 : 48.0
        let baseGlowRadius: CGFloat = level >= 10 ? 9.0 : 6.0
        let firingGlowRadius: CGFloat = level >= 10 ? 18.0 : 12.0
        
        redLines[lineIndex].beamWidth = baseBeamWidth
        redLines[lineIndex].glowRadius = baseGlowRadius
        
        // Animar la aparición durante 3 segundos con efectos adicionales
        withAnimation(.easeInOut(duration: 3.0)) {
            redLines[lineIndex].opacity = 0.8
            redLines[lineIndex].shadowOpacity = 0.8
            redLines[lineIndex].leftLineOpacity = 0.8
            redLines[lineIndex].rightLineOpacity = 0.8
            redLines[lineIndex].glowIntensity = 0.6
            redLines[lineIndex].orangeLineShadowOpacity = 0.6
            redLines[lineIndex].glowRadius = baseGlowRadius
            redLines[lineIndex].laserColor = .red // Cambia a rojo durante la animación
            redLines[lineIndex].sideLineColor = .orange // Cambia a naranja durante la animación
        }
        
        // Añadir animación de pulso continua
        withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
            redLines[lineIndex].pulseScale = 1.1
            redLines[lineIndex].glowRadius = level >= 10 ? baseGlowRadius * 1.5 : baseGlowRadius * 1.33
        }
        
        // Reproducir sonido láser un segundo antes de que sea mortal
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            if self?.soundManager.isSoundEffectsEnabled == true {
                self?.soundManager.playLaserSound()
            }
        }
        
        // Activar el estado mortal y el disparo después de la animación
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            if lineIndex < self.redLines.count {
                self.redLines[lineIndex].isDeadly = true
                
                // Iniciar el efecto de disparo con separación de líneas laterales
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.redLines[lineIndex].beamWidth = firingBeamWidth
                    self.redLines[lineIndex].isBeaming = true
                    self.redLines[lineIndex].glowRadius = firingGlowRadius
                    self.redLines[lineIndex].glowIntensity = 0.8
                }
            }
        }
        
        // Mantener el disparo por 2 segundos y luego iniciar la desaparición
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            if lineIndex < self.redLines.count {
                // Primero, reducir el ancho del rayo y desactivar el estado mortal
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.redLines[lineIndex].beamWidth = baseBeamWidth
                    self.redLines[lineIndex].isBeaming = false
                    self.redLines[lineIndex].isDeadly = false
                    self.redLines[lineIndex].glowRadius = baseGlowRadius
                    self.redLines[lineIndex].glowIntensity = 0.6
                }
                
                // Luego, iniciar la desaparición gradual
                withAnimation(.easeOut(duration: 2.0)) {
                    self.redLines[lineIndex].opacity = 0.0
                    self.redLines[lineIndex].leftLineOpacity = 0.0
                    self.redLines[lineIndex].rightLineOpacity = 0.0
                    self.redLines[lineIndex].glowIntensity = 0.0
                    self.redLines[lineIndex].shadowOpacity = 0.0
                    self.redLines[lineIndex].orangeLineShadowOpacity = 0.0
                    self.redLines[lineIndex].glowRadius = 0.0
                }
                
                // Finalmente, eliminar la línea y permitir la generación de un nuevo láser después de 2 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if lineIndex < self.redLines.count {
                        self.redLines.remove(at: lineIndex)
                        // Esperar 2 segundos adicionales antes de permitir un nuevo láser
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.canGenerateLaser = true
                        }
                    }
                }
            }
        }
    }
    
    private func setupDisplayLink() {
        // Primero invalidamos cualquier displayLink existente
        displayLink?.invalidate()
        displayLink = nil
        
        // Luego creamos uno nuevo con preferencia por la fluidez
        displayLink = CADisplayLink(target: self, selector: #selector(gameLoop))
        displayLink?.preferredFramesPerSecond = 60 // Asegurar 60 FPS
        displayLink?.add(to: .current, forMode: .common) // Usar .common para mejor rendimiento
    }
    
    @objc private func gameLoop() {
        guard !isGameOver && !isPaused else { return }
        
        elapsedTime += 1.0 / 60.0  // Aproximadamente 60 FPS
        
        // Generar láseres aleatorios a partir del nivel 9
        if level >= 9 && !isMeteorPaused && !isLevelTransition && canGenerateLaser && redLines.isEmpty {
            // 0.5% de probabilidad cada frame (aproximadamente cada 2-3 segundos)
            if Double.random(in: 0...1) < 0.005 {
                // Generar un solo láser en una posición aleatoria
                let randomX = CGFloat.random(in: 60..<(screenSize.width - 60))
                canGenerateLaser = false // Desactivar la generación de nuevos láseres
                createRedLine(at: randomX)
            }
        }
        
        // Comprobar colisión con todas las líneas rojas activas
        if let player = player {
            for redLine in redLines where redLine.isActive {
                let lineWidth = redLine.isBeaming ? redLine.beamWidth : 48.0
                
                // Ajustar el ancho de colisión según el nivel
                let collisionWidth: CGFloat = level >= 10 ? lineWidth : lineWidth - 1.0
                
                // Línea roja central
                let redLineRect = CGRect(x: redLine.xPosition - collisionWidth/2, y: 0, width: collisionWidth, height: screenSize.height)
                // Línea naranja izquierda
                let orangeLineWidth: CGFloat = level >= 10 ? 6.0 : 4.0
                let orangeCollisionWidth: CGFloat = level >= 10 ? orangeLineWidth : orangeLineWidth - 1.0
                let leftOrangeRect = CGRect(x: redLine.xPosition - (collisionWidth/2 + orangeCollisionWidth), y: 0, width: orangeCollisionWidth, height: screenSize.height)
                // Línea naranja derecha
                let rightOrangeRect = CGRect(x: redLine.xPosition + (collisionWidth/2), y: 0, width: orangeCollisionWidth, height: screenSize.height)
                
                // Solo comprobar colisión si la línea es mortal o está disparando
                if (redLine.isDeadly || redLine.isBeaming) && 
                   (player.frame.intersects(redLineRect) || 
                    player.frame.intersects(leftOrangeRect) || 
                    player.frame.intersects(rightOrangeRect)) {
                    
                    // Generar feedback háptico más intenso
                    let collisionFeedback = UIImpactFeedbackGenerator(style: .rigid)
                    collisionFeedback.prepare()
                    collisionFeedback.impactOccurred(intensity: 1.0)
                    
                    // Segundo feedback para enfatizar
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        let secondFeedback = UIImpactFeedbackGenerator(style: .heavy)
                        secondFeedback.impactOccurred(intensity: 0.8)
                    }
                    
                    // Reproducir sonido de impacto
                    if soundManager.isSoundEffectsEnabled {
                        soundManager.playImpactSound()
                    }
                    
                    // Pequeña pausa para que se escuche el sonido antes de terminar
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.endGame()
                    }
                    return
                }
            }
        }
        
        // Crear nuevo obstáculo cada 2 segundos
        if elapsedTime >= 2.0 {
            createObstacle()
            elapsedTime = 0  // Reiniciar el contador
        }
        
        // Mover y comprobar obstáculos existentes
        obstacles.removeAll { obstacle in
            obstacle.move()
            
            // Comprobar colisión con el jugador
            if let player = player, obstacle.checkCollisionWith(player.frame) {
                // Generar feedback háptico fuerte al colisionar
                let collisionFeedback = UIImpactFeedbackGenerator(style: .heavy)
                collisionFeedback.prepare()
                collisionFeedback.impactOccurred(intensity: 1.0)
                
                // Añadir un segundo feedback de tipo notificación para enfatizar
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
                
                // Reproducir sonido de impacto antes de terminar el juego
                if soundManager.isSoundEffectsEnabled {
                    soundManager.playImpactSound()
                }
                
                // Pequeña pausa para que se escuche el sonido antes de terminar
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.endGame()
                }
                return true
            }
            
            // Si el meteorito sale de la pantalla, aumentamos la puntuación
            if obstacle.checkScreenCollision() {
                // Calcular puntos basados en el tipo de meteorito
                var points = 1
                
                if obstacle.isSpecial {
                    points = 2
                } else if obstacle.isBig {
                    points = 4  // Cambiado de 5 a 4 para deathstar
                } else if obstacle.isZigzag {
                    points = 1  // Cambiado de 3 a 1 para zigzag
                }
                
                // Actualizar la puntuación y comprobar nivel
                updateScore(points: points)
                
                return true
            }
            return false
        }
        
        objectWillChange.send()
    }
    
    private func createObstacle() {
        // No crear obstáculos si los meteoritos están pausados
        guard !isMeteorPaused else { return }
        
        // 15% de probabilidad de crear una fila doble con un hueco
        if Double.random(in: 0...1) < 0.15 {
            createDoubleRowWithGap()
        } else {
            // Crear obstáculos normales como antes
            let minDistanceBetweenMeteors: CGFloat = 100 // Distancia mínima entre meteoritos
            var randomX: CGFloat
            var attempts = 0
            let maxAttempts = 5 // Número máximo de intentos para encontrar una posición válida
            
            repeat {
                randomX = CGFloat.random(in: 50..<(screenSize.width - 50))
                // Verificar si hay algún meteorito demasiado cerca
                let isTooClose = obstacles.contains { obstacle in
                    let distance = abs(obstacle.center.x - randomX)
                    return distance < minDistanceBetweenMeteors
                }
                attempts += 1
                
                // Si encontramos una posición válida o agotamos los intentos, salimos del bucle
                if !isTooClose || attempts >= maxAttempts {
                    break
                }
            } while true
            
            // Determinar si creamos un meteorito especial o zigzag
            let isSpecial = Double.random(in: 0...1) < 0.1
            
            // Meteoritos zigzag: nivel 2-8, con diferentes cantidades según el nivel
            let isZigzag = level >= 2 && level <= 8 && Double.random(in: 0...1) < 0.15
            
            // Probabilidad de meteoritos grandes aumentada a partir del nivel 9
            let bigMeteorProbability = level >= 9 ? 0.30 : 0.15  // 30% en nivel 9+, 15% en nivel 4-8
            let isBig = level >= 4 && Double.random(in: 0...1) < bigMeteorProbability
            
            if isZigzag {
                // Crear meteoritos zigzag según el nivel
                createZigzagMeteorPair()
            
                // Crear un meteorito normal
                let obstacle = Obstacle(
                    center: CGPoint(x: randomX, y: 0),
                    width: 30,
                    height: 30,
                    isSpecial: isSpecial,
                    isZigzag: false,
                    isBig: isBig,
                    speedMultiplier: CGFloat(level) * 0.15 + 1.0,
                    currentLevel: level
                )
                obstacles.append(obstacle)
                
                // 30% de probabilidad de crear un segundo obstáculo (si no es zigzag)
                if Double.random(in: 0...1) < 0.3 {
                    var secondX: CGFloat
                    attempts = 0
                    
                    repeat {
                        secondX = CGFloat.random(in: 50..<(screenSize.width - 50))
                        // Verificar distancia con todos los meteoritos existentes
                        let isTooClose = obstacles.contains { obstacle in
                            let distance = abs(obstacle.center.x - secondX)
                            return distance < minDistanceBetweenMeteors
                        }
                        attempts += 1
                        
                        if !isTooClose || attempts >= maxAttempts {
                            break
                        }
                    } while true
                    
                    let secondIsSpecial = Double.random(in: 0...1) < 0.1
                    
                    let secondObstacle = Obstacle(
                        center: CGPoint(x: secondX, y: 0),
                        width: 35,
                        height: 35,
                        isSpecial: secondIsSpecial,
                        isBig: isBig,
                        speedMultiplier: CGFloat(level) * 0.15 + 1.0,
                        currentLevel: level
                    )
                    obstacles.append(secondObstacle)
                }
            } else {
                // Crear un meteorito normal
                let obstacle = Obstacle(
                    center: CGPoint(x: randomX, y: 0),
                    width: 30,
                    height: 30,
                    isSpecial: isSpecial,
                    isZigzag: false,
                    isBig: isBig,
                    speedMultiplier: CGFloat(level) * 0.15 + 1.0,
                    currentLevel: level
                )
                obstacles.append(obstacle)
                
                // 30% de probabilidad de crear un segundo obstáculo (si no es zigzag)
                if Double.random(in: 0...1) < 0.3 {
                    var secondX: CGFloat
                    attempts = 0
                    
                    repeat {
                        secondX = CGFloat.random(in: 50..<(screenSize.width - 50))
                        // Verificar distancia con todos los meteoritos existentes
                        let isTooClose = obstacles.contains { obstacle in
                            let distance = abs(obstacle.center.x - secondX)
                            return distance < minDistanceBetweenMeteors
                        }
                        attempts += 1
                        
                        if !isTooClose || attempts >= maxAttempts {
                            break
                        }
                    } while true
                    
                    let secondIsSpecial = Double.random(in: 0...1) < 0.1
                    
                    let secondObstacle = Obstacle(
                        center: CGPoint(x: secondX, y: 0),
                        width: 35,
                        height: 35,
                        isSpecial: secondIsSpecial,
                        isBig: isBig,
                        speedMultiplier: CGFloat(level) * 0.15 + 1.0,
                        currentLevel: level
                    )
                    obstacles.append(secondObstacle)
                }
            }
        }
    }
    
    // Nuevo método para crear meteoritos zigzag
    private func createZigzagMeteorPair() {
        // Determinar cuántos meteoritos zigzag crear según el nivel
        let meteorCount: Int
        if level >= 5 && level <= 8 {
            meteorCount = 3  // Nivel 5-8: 3 meteoritos
        } else if level >= 3 {
            meteorCount = 2  // Nivel 3-4: 2 meteoritos
        } else {
            meteorCount = 1  // Nivel 2: 1 meteorito
        }
        
        // Reducimos el tamaño de los meteoritos zigzag
        let zigzagMeteorSize: CGFloat = 18
        
        if meteorCount == 1 {
            // Crear un solo meteorito zigzag
            let xPosition = CGFloat.random(in: screenSize.width * 0.25..<screenSize.width * 0.75)
            
            let obstacle = Obstacle(
                center: CGPoint(x: xPosition, y: 0),
                width: zigzagMeteorSize,
                height: zigzagMeteorSize,
                isSpecial: false,
                isZigzag: true,
                speedMultiplier: CGFloat(level) * 0.15 + 1.0,
                currentLevel: level
            )
            obstacles.append(obstacle)
            
        } else if meteorCount == 2 {
            // Crear dos meteoritos zigzag con suficiente separación
            let firstX = CGFloat.random(in: screenSize.width * 0.25..<screenSize.width * 0.4)
            let secondX = CGFloat.random(in: screenSize.width * 0.6..<screenSize.width * 0.75)
            
            let firstObstacle = Obstacle(
                center: CGPoint(x: firstX, y: 0),
                width: zigzagMeteorSize,
                height: zigzagMeteorSize,
                isSpecial: false,
                isZigzag: true,
                speedMultiplier: CGFloat(level) * 0.15 + 1.0,
                currentLevel: level
            )
            obstacles.append(firstObstacle)
            
            let secondObstacle = Obstacle(
                center: CGPoint(x: secondX, y: 0),
                width: zigzagMeteorSize,
                height: zigzagMeteorSize,
                isSpecial: false,
                isZigzag: true,
                speedMultiplier: CGFloat(level) * 0.15 + 1.0,
                currentLevel: level
            )
            obstacles.append(secondObstacle)
            
        } else if meteorCount == 3 {
            // Crear tres meteoritos zigzag distribuidos
            let firstX = CGFloat.random(in: screenSize.width * 0.15..<screenSize.width * 0.25)
            let secondX = CGFloat.random(in: screenSize.width * 0.4..<screenSize.width * 0.6)
            let thirdX = CGFloat.random(in: screenSize.width * 0.75..<screenSize.width * 0.85)
            
            let firstObstacle = Obstacle(
                center: CGPoint(x: firstX, y: 0),
                width: zigzagMeteorSize,
                height: zigzagMeteorSize,
                isSpecial: false,
                isZigzag: true,
                speedMultiplier: CGFloat(level) * 0.15 + 1.0,
                currentLevel: level
            )
            obstacles.append(firstObstacle)
            
            let secondObstacle = Obstacle(
                center: CGPoint(x: secondX, y: 0),
                width: zigzagMeteorSize,
                height: zigzagMeteorSize,
                isSpecial: false,
                isZigzag: true,
                speedMultiplier: CGFloat(level) * 0.15 + 1.0,
                currentLevel: level
            )
            obstacles.append(secondObstacle)
            
            let thirdObstacle = Obstacle(
                center: CGPoint(x: thirdX, y: 0),
                width: zigzagMeteorSize,
                height: zigzagMeteorSize,
                isSpecial: false,
                isZigzag: true,
                speedMultiplier: CGFloat(level) * 0.15 + 1.0,
                currentLevel: level
            )
            obstacles.append(thirdObstacle)
        }
    }
    
    // Método para crear una fila doble de meteoritos con un hueco
    private func createDoubleRowWithGap() {
        // Tamaño del hueco (ajustable según el tamaño de la nave)
        let gapWidth: CGFloat = 150
        
        // Posición aleatoria del hueco
        let gapCenter = CGFloat.random(in: gapWidth/2 + 50..<(screenSize.width - gapWidth/2 - 50))
        
        // Velocidad constante para todos los meteoritos de la fila
        let rowSpeed: CGFloat = baseObstacleSpeed * (1.0 + CGFloat(level) * 0.1)
        
        // Crear la primera fila
        createRowWithGap(yPosition: 0, gapCenter: gapCenter, gapWidth: gapWidth, speed: rowSpeed)
        
        // Crear la segunda fila un poco más arriba
        createRowWithGap(yPosition: -100, gapCenter: gapCenter, gapWidth: gapWidth, speed: rowSpeed)
        
        // Crear la tercera fila aún más arriba
        createRowWithGap(yPosition: -200, gapCenter: gapCenter, gapWidth: gapWidth, speed: rowSpeed)
    }
    
    // Método para crear una fila de meteoritos con un hueco en una posición específica
    private func createRowWithGap(yPosition: CGFloat, gapCenter: CGFloat, gapWidth: CGFloat, speed: CGFloat) {
        // Espacio entre meteoritos
        let meteorSpacing: CGFloat = 80
        let meteorSize: CGFloat = 25  // Reducido a 25
        
        // Calcular cuántos meteoritos caben a la izquierda del hueco
        let leftSideWidth = gapCenter - gapWidth/2
        let leftCount = Int(leftSideWidth / meteorSpacing)
        
        // Calcular cuántos meteoritos caben a la derecha del hueco
        let rightSideWidth = screenSize.width - (gapCenter + gapWidth/2)
        let rightCount = Int(rightSideWidth / meteorSpacing)
        
        // Crear meteoritos a la izquierda del hueco
        for i in 0..<leftCount {
            let x = CGFloat(i) * meteorSpacing + meteorSpacing/2
            let obstacle = Obstacle(
                center: CGPoint(x: x, y: yPosition),
                width: meteorSize,
                height: meteorSize,
                isSpecial: false,
                currentLevel: level
            )
            obstacle.speed = speed
            obstacles.append(obstacle)
        }
        
        // Crear meteoritos a la derecha del hueco
        for i in 0..<rightCount {
            let x = gapCenter + gapWidth/2 + CGFloat(i) * meteorSpacing + meteorSpacing/2
            let obstacle = Obstacle(
                center: CGPoint(x: x, y: yPosition),
                width: meteorSize,
                height: meteorSize,
                isSpecial: false,
                currentLevel: level
            )
            obstacle.speed = speed
            obstacles.append(obstacle)
        }
    }
    
    func initializePlayer(with size: CGSize) {
        self.screenSize = size
        // Aumentamos el tamaño de la nave en el juego
        self.player = Player(center: CGPoint(x: size.width / 2, y: size.height * 0.85), width: 950, height: 950) // Aumentado de 850 a 950
    }
    
    func movePlayer(to point: CGPoint) {
        if let player = player {
            // Cambiamos los límites del movimiento vertical
            // Antes era entre 0.75 y 0.95, ahora será entre 0.65 y 0.95
            let minY = screenSize.height * 0.15  // Cambiado de 0.75 a 0.65 para permitir más movimiento hacia arriba
            let maxY = screenSize.height * 0.90
            let constrainedY = min(max(point.y, minY), maxY)
            
            player.moveToPoint(CGPoint(x: point.x, y: constrainedY))
            objectWillChange.send()
        }
    }
    
    // Añadimos esta función para manejar el drag gesture
    func handleDrag(_ value: DragGesture.Value) {
        if let player = player {
            let newX = value.location.x
            movePlayer(to: CGPoint(x: newX, y: player.center.y))
        }
    }
    
    private func restartGame() {
        isGameOver = false
        player = nil
        obstacles.removeAll()
        score = 0
        level = 1  // Reiniciar el nivel
        baseObstacleSpeed = 3.0  // Reiniciar la velocidad base
        setupDisplayLink() // Esto ahora invalidará el displayLink anterior
        initializePlayer(with: screenSize)
    }
    
    // Método para iniciar el juego
    func startGame() {
        // Primero reiniciamos el juego
        resetGame()
        
        // Configuramos el displayLink
        setupDisplayLink()
        
        // Indicamos que el juego no está pausado
        isPaused = false
    }
    
    // Método para pausar el juego
    func pauseGame() {
        isPaused = true
        // Invalidamos el displayLink para ahorrar recursos
        displayLink?.invalidate()
        displayLink = nil
        
        // Generar feedback háptico suave al pausar
        let pauseFeedback = UIImpactFeedbackGenerator(style: .soft)
        pauseFeedback.prepare()
        pauseFeedback.impactOccurred(intensity: 0.6)
    }
    
    // Método para reanudar el juego
    func resumeGame() {
        isPaused = false
        // Volvemos a configurar el displayLink
        setupDisplayLink()
    }
    
    // Método para guardar la puntuación actual
    func saveScore() {
        guard let modelContext = modelContext else { return }
        
        let newItem = Item(
            timestamp: Date(),
            score: score,
            level: level,
            shipType: selectedShipImage
        )
        
        modelContext.insert(newItem)
        
        do {
            try modelContext.save()
        } catch {
            print("Error al guardar la puntuación: \(error)")
        }
    }
    
    // Método para establecer el contexto del modelo
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // Método para cargar las puntuaciones más altas
    func loadHighScores() -> [Item]? {
        guard let modelContext = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\.score, order: .reverse)]
        )
        
        do {
            let items = try modelContext.fetch(descriptor)
            return items
        } catch {
            print("Error al cargar las puntuaciones: \(error)")
            return nil
        }
    }
    
    // Método para reiniciar el juego
    func resetGame() {
        // Reiniciar variables del juego
        score = 0
        level = 1
        pointsToNextLevel = 30
        isLevelTransition = false
        obstacles.removeAll()
        isGameOver = false
        baseObstacleSpeed = 3.0
        elapsedTime = 0
        redLines.removeAll()
    }
    
    // Modificamos el método de game over para guardar la puntuación
    func endGame() {
        isGameOver = true
        lastScore = score
        saveScore() // Guardamos la puntuación al finalizar el juego
        
        // Invalidamos el displayLink
        displayLink?.invalidate()
        displayLink = nil
    }
    
    func checkCollisions() {
        for asteroid in obstacles {
            if let shipBounds = player?.frame {
                if asteroid.frame.intersects(shipBounds) {
                    if soundManager.isSoundEffectsEnabled {
                        soundManager.playImpactSound()
                    }
                    
                    // Pequeña pausa para que se escuche el sonido antes de terminar
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.endGame()
                    }
                    return
                }
            }
        }
    }
    
    // Añadir nuevo método para generar posiciones seguras de láseres
    private func generateSafeLaserPositions() -> (CGFloat, CGFloat) {
        // Espacio mínimo seguro necesario para la nave (reducido a un tamaño más apropiado)
        let safeZoneWidth: CGFloat = 150 // Reducido de 250 a 150

        // Ancho total de un láser con sus líneas laterales
        let totalLaserWidth: CGFloat = level >= 10 ? 84.0 : 60.0

        // Margen desde los bordes de la pantalla
        let screenMargin: CGFloat = 60 // Reducido para dar más espacio de juego

        // Dividimos la pantalla en tres secciones
        let availableWidth = screenSize.width - (2 * screenMargin)
        let sectionWidth = availableWidth / 3

        // Elegimos aleatoriamente en qué sección estará el espacio seguro
        let safeSection = Int.random(in: 1...3)

        // Variables para las posiciones de los láseres
        var leftLaserX: CGFloat
        var rightLaserX: CGFloat

        switch safeSection {
        case 1: // Espacio seguro en la sección izquierda
            leftLaserX = screenMargin + totalLaserWidth/2
            rightLaserX = screenMargin + sectionWidth + sectionWidth/2
        case 2: // Espacio seguro en la sección central
            leftLaserX = screenMargin + sectionWidth/2
            rightLaserX = screenSize.width - screenMargin - sectionWidth/2
        case 3: // Espacio seguro en la sección derecha
            leftLaserX = screenMargin + sectionWidth + sectionWidth/2
            rightLaserX = screenSize.width - screenMargin - totalLaserWidth/2
        default:
            leftLaserX = screenSize.width * 0.25
            rightLaserX = screenSize.width * 0.75
        }

        // Aseguramos que haya suficiente espacio entre los láseres
        let minSpaceBetweenLasers = safeZoneWidth + totalLaserWidth
        if abs(rightLaserX - leftLaserX) < minSpaceBetweenLasers {
            // Ajustamos las posiciones si están muy cerca
            let center = (leftLaserX + rightLaserX) / 2
            leftLaserX = max(screenMargin + totalLaserWidth/2, center - (minSpaceBetweenLasers / 2))
            rightLaserX = min(screenSize.width - screenMargin - totalLaserWidth/2, center + (minSpaceBetweenLasers / 2))
        }

        // Aseguramos que los láseres no se salgan de la pantalla
        leftLaserX = max(screenMargin + totalLaserWidth/2, min(screenSize.width - screenMargin - totalLaserWidth/2, leftLaserX))
        rightLaserX = max(screenMargin + totalLaserWidth/2, min(screenSize.width - screenMargin - totalLaserWidth/2, rightLaserX))

        return (leftLaserX, rightLaserX)
    }
    
    // Modificar el método updateScore para usar las nuevas posiciones seguras
    private func updateScore(points: Int) {
        let oldScore = score
        score += points
        
        // Calcular si debemos avanzar de nivel
        let oldLevel = (oldScore / 30) + 1
        let newLevel = (score / 30) + 1
        
        if newLevel > oldLevel {
            isLevelTransition = true
            level = newLevel
            
            // Reproducir sonido de nivel primero
            if soundManager.isSoundEffectsEnabled {
                soundManager.playLevelUpSound()
            }
            
            // Feedback háptico al subir de nivel
            let levelUpFeedback = UIImpactFeedbackGenerator(style: .medium)
            levelUpFeedback.prepare()
            levelUpFeedback.impactOccurred()
            
            // Aumentar la velocidad base de los obstáculos
            baseObstacleSpeed += 0.2
            
            // Actualizar puntos necesarios para el siguiente nivel
            pointsToNextLevel = level * 30
            
            // Pausar la generación de meteoritos
            isMeteorPaused = true
            
            // Crear dos líneas rojas después de un breve retraso
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                
                // Generar posiciones seguras para los láseres
                let (leftX, rightX) = self.generateSafeLaserPositions()
                
                // Crear los dos láseres
                self.createRedLine(at: leftX)
                
                // Pequeño retraso entre la creación de los láseres para que no suenen exactamente al mismo tiempo
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.createRedLine(at: rightX)
                }
            }
            
            // Reanudar la generación de meteoritos después de 5 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.isMeteorPaused = false
            }
            
            // Desactivar la transición después de un tiempo
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isLevelTransition = false
            }
        }
    }
    
    // Nuevo método para feedback háptico de los botones de sonido
    func playButtonHapticFeedback() {
        let buttonFeedback = UIImpactFeedbackGenerator(style: .light)
        buttonFeedback.prepare()
        buttonFeedback.impactOccurred(intensity: 0.5)
    }
}
