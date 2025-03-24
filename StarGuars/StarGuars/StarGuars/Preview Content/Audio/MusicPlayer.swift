import AVFoundation
import Foundation

// MARK: - Protocol Definition
protocol MusicPlayerDelegate: AnyObject {
    func musicTrackDidFinishPlaying()
}

// MARK: - MusicPlayer Class
class MusicPlayer: NSObject {
    // MARK: - Singleton
    static let shared = MusicPlayer()
    
    // MARK: - Configuration Constants
    private let MUSIC_VOLUME: Float = 0.15
    private let musicTracks = ["music1", "music2", "music3", "music4"]
    private var currentTrackIndex = 0
    
    // MARK: - Private Properties
    private var player: AVAudioPlayer?
    private(set) var isPlaying = false
    private(set) var isEnabled = false
    private var hasInitializedMusic = false
    
    // MARK: - Delegate
    weak var delegate: MusicPlayerDelegate?
    
    // MARK: - Initialization
    override private init() {
        super.init()
        currentTrackIndex = Int.random(in: 0..<musicTracks.count)
        
        // Configurar para manejar interrupciones
        AudioSessionManager.shared.onInterruptionBegan = { [weak self] in
            self?.handleInterruptionBegan()
        }
        
        AudioSessionManager.shared.onInterruptionEnded = { [weak self] in
            self?.handleInterruptionEnded()
        }
    }
    
    // MARK: - Public Methods
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        
        if enabled {
            if !hasInitializedMusic {
                hasInitializedMusic = true
                play()
            } else {
                resume()
            }
        } else {
            pause()
        }
    }
    
    func play() {
        guard isEnabled else { return }
        
        if player == nil {
            playRandomTrack()
        } else {
            resume()
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }
    
    func togglePlayback() {
        setEnabled(!isEnabled)
    }
    
    // MARK: - Private Methods
    private func resume() {
        player?.play()
        isPlaying = true
    }
    
    private func playRandomTrack() {
        var newIndex: Int
        repeat {
            newIndex = Int.random(in: 0..<musicTracks.count)
        } while newIndex == currentTrackIndex && musicTracks.count > 1
        
        currentTrackIndex = newIndex
        playCurrentTrack()
    }
    
    private func playCurrentTrack() {
        guard isEnabled else { return }
        
        let trackName = musicTracks[currentTrackIndex]
        
        if let url = Bundle.main.url(forResource: trackName, withExtension: "mp3") {
            do {
                let newPlayer = try AVAudioPlayer(contentsOf: url)
                newPlayer.volume = MUSIC_VOLUME
                newPlayer.delegate = self
                newPlayer.numberOfLoops = 0
                newPlayer.prepareToPlay()
                newPlayer.play()
                
                // Detenemos el reproductor anterior
                player?.stop()
                player = newPlayer
                isPlaying = true
                
                print("Started playing track: \(trackName)")
            } catch {
                print("Could not play track \(trackName): \(error)")
            }
        } else {
            print("Could not find track: \(trackName)")
        }
    }
    
    private func handleInterruptionBegan() {
        if isPlaying {
            pause()
        }
    }
    
    private func handleInterruptionEnded() {
        if isEnabled {
            resume()
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension MusicPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player === self.player && isEnabled {
            print("Music track finished playing, starting next track")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.playRandomTrack()
                self.delegate?.musicTrackDidFinishPlaying()
            }
        }
    }
} 