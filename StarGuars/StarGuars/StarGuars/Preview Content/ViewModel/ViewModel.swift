import SwiftUI
import Combine
import SwiftData

// MARK: - ViewModel Class
class ViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var player: Player?
    @Published var obstacles: [Meteorito] = []
    @Published var redLines: [RedLine] = []
    @Published var score: Int = 0
    @Published var level: Int = 1
    @Published var isGameOver: Bool = false
    @Published var isPaused: Bool = false
    @Published var lastScore: Int?
    @Published var selectedShipImage: String = "starship3"
    
    // MARK: - Private Properties
    private var timer: CADisplayLink?
    private var lastUpdateTime: CFTimeInterval = 0
    private var lastObstacleSpawnTime: CFTimeInterval = 0
    private var lastRedLineSpawnTime: CFTimeInterval = 0
    private var gameSize: CGSize?
    private var isPracticeMode: Bool = false
    private var practiceStartLevel: Int = 1
    private var canGenerateLaser: Bool = true
    private var modelContext: ModelContext?
    
    // Constantes para optimización
    private enum GameConstants {
        static let baseSpawnInterval: Double = 1.2    // Aumentado de 0.8 para dar más espacio entre meteoritos
        static let levelIncrease: Double = 0.04      // Ajustado para mantener la progresión
        static let maxSpawnInterval: Double = 1.8     // Aumentado de 1.5 para más tiempo en niveles bajos
        static let minSpawnInterval: Double = 0.7     // Aumentado de 0.5 para evitar spawns demasiado rápidos
        static let baseMeteorites: Int = 3
        static let maxMeteorites: Int = 10
        static let pointsPerLevel: Int = 30
        static let bonusPointsPerLevel: Int = 10
    }
    
    // MARK: - Initialization & Setup
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func initializePlayer(with size: CGSize) {
        gameSize = size
        player = Player.initialize(with: size)
        player?.updateShipImage(selectedShipImage)
    }
    
    // MARK: - Game State Management
    
    func startGame() {
        resetGame()
        isPracticeMode = false
        startGameLoop()
    }
    
    func startPracticeGame(fromLevel level: Int) {
        resetGame()
        isPracticeMode = true
        practiceStartLevel = level
        self.level = level
        self.score = (level - 1) * GameConstants.pointsPerLevel
        startGameLoop()
    }
    
    private func resetGame() {
        // Optimizar limpieza de arrays
        obstacles = []
        redLines = []
        
        // Resetear estados
        score = 0
        level = 1
        isGameOver = false
        isPaused = false
        canGenerateLaser = true
        
        // Resetear tiempos
        lastUpdateTime = 0
        lastObstacleSpawnTime = 0
        lastRedLineSpawnTime = 0
        
        // Reiniciar jugador si hay tamaño disponible
        if let size = gameSize {
            player = Player.initialize(with: size)
            player?.updateShipImage(selectedShipImage)
        }
    }
    
    // MARK: - Game Loop
    
    private func startGameLoop() {
        timer?.invalidate()
        timer = CADisplayLink(target: self, selector: #selector(gameLoop))
        timer?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
        timer?.add(to: .main, forMode: .common)
    }
    
    @objc private func gameLoop(displayLink: CADisplayLink) {
        guard !isPaused else { return }
        
        let currentTime = displayLink.timestamp
        
        // Inicialización del primer frame
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            lastObstacleSpawnTime = currentTime
            lastRedLineSpawnTime = currentTime
            return
        }
        
        // Actualizar tiempo delta
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Calcular intervalo de spawn
        let spawnInterval = calculateSpawnInterval()
        
        // Actualizar spawns
        if currentTime - lastObstacleSpawnTime >= spawnInterval {
            spawnObstacle()
            lastObstacleSpawnTime = currentTime
        }
        
        if currentTime - lastRedLineSpawnTime >= 2.0 {
            spawnRedLine()
            lastRedLineSpawnTime = currentTime
        }
        
        updateGame(deltaTime: deltaTime)
    }
    
    // MARK: - Game Logic
    
    private func calculateSpawnInterval() -> Double {
        // Calcula el intervalo base más el incremento por nivel
        let interval = GameConstants.baseSpawnInterval - (Double(level - 1) * GameConstants.levelIncrease)
        
        // Asegura que el intervalo esté entre el mínimo y máximo permitido
        return min(max(interval, GameConstants.minSpawnInterval), GameConstants.maxSpawnInterval)
    }
    
    private func updateGame(deltaTime: CFTimeInterval) {
        // Optimizar actualización de obstáculos usando removeAll con closure inline
        obstacles.removeAll { meteorito in
            if let puntos = meteorito.move(), puntos > 0 {
                score += puntos
                checkLevelUp()
                return true
            }
            return false
        }
        
        // Verificar colisiones solo si el jugador existe y el juego está activo
        guard let player = player, !isGameOver else { return }
        
        // Optimizar verificación de colisiones usando first(where:)
        if obstacles.first(where: { $0.checkCollisionWith(player.frame) }) != nil ||
           redLines.first(where: { $0.isBeaming && $0.checkCollisionWith(player.frame) }) != nil {
            gameOver()
            return
        }
        
        // Actualizar láseres solo si están activos
        redLines.forEach { redLine in
            if redLine.isActive {
                redLine.update()
            }
        }
    }
    
    private func checkLevelUp() {
        let shouldBeLevelByScore = (score / GameConstants.pointsPerLevel) + 1
        if shouldBeLevelByScore > level {
            levelUp()
        }
    }
    
    // MARK: - Player Controls
    
    func movePlayer(to point: CGPoint) {
        player?.moveToPoint(point)
    }
    
    func pauseGame() {
        isPaused = true
        timer?.isPaused = true
        player?.setPaused(true)
        obstacles.forEach { $0.setPaused(true) }
        redLines.forEach { $0.setPaused(true) }
    }
    
    func resumeGame() {
        isPaused = false
        timer?.isPaused = false
        player?.setPaused(false)
        obstacles.forEach { $0.setPaused(false) }
        redLines.forEach { $0.setPaused(false) }
    }
    
    // MARK: - Spawn Management
    
    private func spawnObstacle() {
        guard let size = gameSize else { return }
        
        let maxMeteorites = calculateMaxMeteorites()
        let spawnProbability = calculateSpawnProbability()
        
        if obstacles.count < maxMeteorites && Double.random(in: 0...1) < spawnProbability {
            // Usar la nueva lógica de generación de meteoritos
            let newMeteorites = Meteorito.generateMeteoritosForLevel(
                in: size,
                currentLevel: level,
                isEarlyLevel: true  // Permitir la generación de meteoritos dobles en niveles iniciales
            )
            
            // Añadir los nuevos meteoritos si hay espacio
            let availableSpace = maxMeteorites - obstacles.count
            let meteoritesToAdd = Array(newMeteorites.prefix(availableSpace))
            obstacles.append(contentsOf: meteoritesToAdd)
        }
    }
    
    private func calculateMaxMeteorites() -> Int {
        let baseMax: Int
        if level >= 10 {
            baseMax = GameConstants.baseMeteorites + ((level - 10) / 3)
        } else {
            baseMax = GameConstants.baseMeteorites + (level / 2)
        }
        return min(baseMax, GameConstants.maxMeteorites)
    }
    
    private func calculateSpawnProbability() -> Double {
        if level >= 10 {
            return min(0.35 + (Double(level - 10) * 0.03), 0.7)  // Reducida la probabilidad para espaciar más
        } else {
            return min(0.4 + (Double(level) * 0.05), 0.8)  // Ajustada la probabilidad inicial
        }
    }
    
    private func spawnRedLine() {
        guard let size = gameSize, canGenerateLaser else { return }
        
        if RedLine.shouldGenerateLaser(forLevel: level) {
            canGenerateLaser = false
            let redLine = RedLine(screenWidth: size.width)
            redLines.append(redLine)
            
            let cooldown = RedLine.getCooldownDuration(forLevel: level)
            DispatchQueue.main.asyncAfter(deadline: .now() + cooldown) { [weak self] in
                self?.canGenerateLaser = true
            }
        }
    }
    
    // MARK: - Level Management
    
    private func levelUp() {
        level += 1
        score += GameConstants.bonusPointsPerLevel
        
        redLines.removeAll()
        
        if let size = gameSize {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                if let levelUpLaser = RedLine.generateLevelUpLaser(screenWidth: size.width, level: self.level) {
                    self.redLines.append(levelUpLaser)
                    
                    let cooldown = RedLine.getCooldownDuration(forLevel: self.level)
                    DispatchQueue.main.asyncAfter(deadline: .now() + cooldown) {
                        self.canGenerateLaser = true
                    }
                }
            }
        }
        
        SoundManager.shared.playLevelUpSound()
        
        lastObstacleSpawnTime = lastUpdateTime
        lastRedLineSpawnTime = lastUpdateTime
    }
    
    // MARK: - Game Over Handling
    
    private func gameOver() {
        isGameOver = true
        timer?.invalidate()
        timer = nil
        
        redLines.forEach { $0.deactivate() }
        
        if !isPracticeMode {
            saveScore()
        }
    }
    
    // MARK: - Score Management
    
    private func saveScore() {
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
    
    // MARK: - Cleanup
    
    deinit {
        timer?.invalidate()
    }
}
