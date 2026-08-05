import Foundation
import AVFoundation
import Combine

public class AudioPlayerManager: ObservableObject {
    public static let shared = AudioPlayerManager()
    
    @Published public var currentTrack: Track? = nil
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: Double = 0
    @Published public var duration: Double = 0
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
        } catch {
            print("Ошибка настройки фонового аудиосеанса: \(error)")
        }
    }
    
    public func play(track: Track) {
        if currentTrack?.id == track.id {
            togglePlayPause()
            return
        }
        
        self.currentTrack = track
        self.isPlaying = true
        
        if let url = URL(string: track.audioUrl) {
            let playerItem = AVPlayerItem(url: url)
            player = AVPlayer(playerItem: playerItem)
            player?.play()
            setupTimeObserver()
        }
    }
    
    public func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    public func seek(to timeSeconds: Double) {
        let cmTime = CMTime(seconds: timeSeconds, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }
    
    private func setupTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let currentItem = self.player?.currentItem else { return }
            self.currentTime = time.seconds
            self.duration = currentItem.duration.seconds.isNaN ? Double(self.currentTrack?.durationSeconds ?? 0) : currentItem.duration.seconds
        }
    }
}
