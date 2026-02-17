import Foundation
import AVFoundation
import AVFAudio

class AudioService: NSObject, ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var currentVoice: AVSpeechSynthesisVoice?
    
    @Published var isPlaying = false
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Ошибка настройки аудио сессии: \(error)")
        }
    }
    
    func playVoice(text: String, language: String = "ru") async {
        // Выбираем голос для языка
        let voiceIdentifier = language == "ru" ? "ru-RU" : "en-US"
        let voices = AVSpeechSynthesisVoice.speechVoices()
        currentVoice = voices.first { $0.language == voiceIdentifier } ?? voices.first
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = currentVoice
        utterance.rate = 0.5
        
        await MainActor.run {
            speechSynthesizer.speak(utterance)
        }
    }
    
    func playSound(from data: Data) async throws {
        await stop()
        
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.delegate = self
        audioPlayer?.play()
        
        await MainActor.run {
            isPlaying = true
        }
    }
    
    func stop() async {
        audioPlayer?.stop()
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        await MainActor.run {
            isPlaying = false
        }
    }
}

extension AudioService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
        }
    }
}
