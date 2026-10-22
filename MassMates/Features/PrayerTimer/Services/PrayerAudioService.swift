import AVFoundation
import AudioToolbox
import Foundation

@MainActor
protocol PrayerAudioPlaying: AnyObject {
    var isPlayingAmbient: Bool { get }
    func playChime()
    func playAmbientSound(_ option: AmbientSoundOption)
    func stopAmbientSound()
}

@MainActor
final class DefaultPrayerAudioService: PrayerAudioPlaying {
    // MARK: - Dependencies & State
    private var ambientPlayer: AVAudioPlayer?
    private(set) var isPlayingAmbient = false
    private let chimeSoundID: SystemSoundID

    // MARK: - Init
    init(chimeSoundID: SystemSoundID = 1013) {
        self.chimeSoundID = chimeSoundID
    }

    // MARK: - Body / Public API
    func playChime() {
        AudioServicesPlaySystemSound(chimeSoundID)
    }

    func playAmbientSound(_ option: AmbientSoundOption) {
        stopAmbientSound()
        guard option != .pureSilence else { return }

        configureAudioSession()
        if let player = createAmbientPlayer(for: option) {
            ambientPlayer = player
            player.numberOfLoops = -1
            player.play()
            isPlayingAmbient = true
        } else {
            AudioServicesPlaySystemSound(option == .monasteryChimes ? chimeSoundID : 1057)
            isPlayingAmbient = true
        }
    }

    func stopAmbientSound() {
        ambientPlayer?.stop()
        ambientPlayer = nil
        isPlayingAmbient = false
    }

    // MARK: - Subviews / Private Helpers
    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: .mixWithOthers)
        try? session.setActive(true)
        #endif
    }

    private func createAmbientPlayer(for option: AmbientSoundOption) -> AVAudioPlayer? {
        if let url = Bundle.main.url(forResource: option.rawValue, withExtension: "m4a") {
            return try? AVAudioPlayer(contentsOf: url)
        }
        guard let pcmData = synthesizedAudioData(for: option) else { return nil }
        return try? AVAudioPlayer(data: pcmData)
    }

    private func synthesizedAudioData(for option: AmbientSoundOption) -> Data? {
        let sampleRate: Double = 8000
        let sampleCount = Int(sampleRate)
        var samples = [Int16]()
        samples.reserveCapacity(sampleCount)

        for index in 0..<sampleCount {
            samples.append(generateSample(for: option, index: index, sampleRate: sampleRate))
        }
        return makeWavData(samples: samples, sampleRate: Int(sampleRate))
    }

    private func generateSample(for option: AmbientSoundOption, index: Int, sampleRate: Double) -> Int16 {
        let time = Double(index) / sampleRate
        switch option {
        case .monasteryChimes:
            let envelope = max(0.0, 1.0 - time)
            return Int16(sin(2.0 * .pi * 528.0 * time) * envelope * 1200.0)
        case .gentleRain:
            return Int16(Double.random(in: -1.0...1.0) * 350.0)
        case .pureSilence:
            return 0
        }
    }

    private func makeWavData(samples: [Int16], sampleRate: Int) -> Data {
        let subchunk2Size = samples.count * 2
        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        appendUInt32(UInt32(36 + subchunk2Size), to: &data)
        data.append(contentsOf: "WAVEfmt ".utf8)
        appendUInt32(16, to: &data)
        appendUInt16(1, to: &data)
        appendUInt16(1, to: &data)
        appendUInt32(UInt32(sampleRate), to: &data)
        appendUInt32(UInt32(sampleRate * 2), to: &data)
        appendUInt16(2, to: &data)
        appendUInt16(16, to: &data)
        data.append(contentsOf: "data".utf8)
        appendUInt32(UInt32(subchunk2Size), to: &data)
        samples.withUnsafeBytes { data.append(contentsOf: $0) }
        return data
    }

    private func appendUInt32(_ value: UInt32, to data: inout Data) {
        var le = value.littleEndian
        Swift.withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
    }

    private func appendUInt16(_ value: UInt16, to data: inout Data) {
        var le = value.littleEndian
        Swift.withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
    }
}
