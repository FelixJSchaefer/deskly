import AVFAudio

@MainActor
final class AlarmPlayer {
    static let shared = AlarmPlayer()
    private var player: AVAudioPlayer?

    func start() {
        stop()
        guard let url = Bundle.main.url(forResource: "Knock", withExtension: "wav") else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.82
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            player = nil
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
