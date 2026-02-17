import SwiftUI
import Lottie

struct AnimalDetailView: View {
    let animal: Animal
    let categoryId: String
    @StateObject private var assetService = AssetService()
    @StateObject private var audioService = AudioService()
    @StateObject private var contentService = ContentService()
    @StateObject private var analyticsService = AnalyticsService()
    @EnvironmentObject var localizationService: LocalizationService
    
    @State private var bgImage: UIImage?
    @State private var animationView: LottieAnimationView?
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            if let bg = bgImage {
                Image(uiImage: bg)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            } else {
                Color.gray.opacity(0.3)
            }
            
            VStack(spacing: 30) {
                Spacer()
                
                // Анимация или превью
                if let animationView = animationView {
                    LottieView(animationView: animationView)
                        .frame(width: 200, height: 200)
                }
                
                // Название
                Text(localizationService.localized(animal.name))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 5)
                
                // Инструкция
                Text("Нажмите на животное, чтобы услышать его голос")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .shadow(color: .black.opacity(0.5), radius: 5)
                
                Spacer()
            }
        }
        .onTapGesture {
            Task {
                await playAnimalSound()
            }
        }
        .task {
            await loadAssets()
        }
    }
    
    private func loadAssets() async {
        // Загружаем фон
        do {
            bgImage = try await assetService.loadImage(from: animal.bgAssetPath)
        } catch {
            print("Ошибка загрузки фона: \(error)")
        }
        
        // Загружаем анимацию
        if let animationPath = animal.animationAssetPath {
            // Загрузка Lottie анимации
            // Реализация зависит от библиотеки Lottie
        } else if let videoPath = animal.animationVideoAssetPath {
            // Загрузка видео анимации
        }
    }
    
    private func playAnimalSound() async {
        let animalName = localizationService.localized(animal.name)
        
        // Проигрываем голос (если есть) или TTS
        if let voicePath = animal.voiceAssetPath,
           let voiceUrl = localizationService.currentLanguage == .ru ? voicePath.ru : voicePath.en,
           !voiceUrl.isEmpty {
            // Загружаем и проигрываем аудио файл
            do {
                let data = try await assetService.loadAudioData(from: voiceUrl)
                try await audioService.playSound(from: data)
            } catch {
                // Fallback на TTS
                await audioService.playVoice(text: "Это \(animalName)", language: localizationService.currentLanguage.rawValue)
            }
        } else {
            await audioService.playVoice(text: "Это \(animalName)", language: localizationService.currentLanguage.rawValue)
        }
        
        // После голоса проигрываем звук животного
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда
        
        do {
            let soundData = try await assetService.loadAudioData(from: animal.soundAssetPath)
            try await audioService.playSound(from: soundData)
            await analyticsService.logEvent(eventType: "animal_sound_play", categoryId: categoryId, animalId: animal.id)
        } catch {
            print("Ошибка проигрывания звука: \(error)")
        }
    }
}

// Временная заглушка для LottieView
struct LottieView: UIViewRepresentable {
    let animationView: LottieAnimationView
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
