//
//  AnimalDetailView.swift
//  DetiZhivotnieApp
//
//  Figma: `1:6664` — Animal card (390×844).
//  Full-screen modal with a solid themed background, the animal's name as a
//  large white title at top, and the animal illustration/animation centered.
//  Tap anywhere to dismiss and return to Main screen.
//
//  Audio: on appear, plays narrator voice ("This is <name>") then the
//  animal's own sound. Narrator uses bundled voice asset → falls back to TTS.
//

import SwiftUI
import Lottie

struct AnimalDetailView: View {
    let animal: Animal
    let categoryId: String

    @StateObject private var assetService = AssetService()
    @StateObject private var audioService = AudioService()
    @StateObject private var analyticsService = AnalyticsService()
    @EnvironmentObject var localizationService: LocalizationService
    @Environment(\.dismiss) private var dismiss

    @State private var previewImage: UIImage?
    @State private var hasStartedPlayback = false
    @State private var tapHintVisible = true

    private var theme: CategoryTheme {
        CategoryTheme.theme(for: categoryId)
    }

    var body: some View {
        ZStack {
            // Solid themed background (matches Main screen category theme)
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title
                Text(localizationService.localized(animal.name))
                    .dsStyle(.largeTitleBold)
                    .foregroundColor(theme.label)
                    .padding(.top, DS.Gap.gap1000)    // 40pt from safe area
                    .padding(.horizontal, DS.Gap.gap500)

                Spacer()

                // Animal visual (photo for now; Lottie/video wire-up follows)
                Group {
                    if let image = previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        ProgressView().tint(theme.label)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DS.Gap.gap600)

                Spacer()
            }

            // Tap hint — fades out after first tap
            if tapHintVisible {
                TapHintHand()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .padding(.trailing, DS.Gap.gap600)
                    .padding(.top, 180)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Per Figma flow: tap anywhere dismisses and returns to Main.
            dismiss()
        }
        .task {
            await loadAssets()
            // Auto-play narrator + animal sound once on appear.
            if !hasStartedPlayback {
                hasStartedPlayback = true
                await playAnimalScenario()
            }
        }
    }

    // MARK: - Assets

    private func loadAssets() async {
        do {
            previewImage = try await assetService.loadImage(from: animal.previewAssetPath)
        } catch {
            // Keep placeholder
        }
    }

    // MARK: - Audio scenario

    private func playAnimalScenario() async {
        let animalName = localizationService.localized(animal.name)

        // 1. Narrator voice ("Это <name>" / "This is <name>")
        if let voiceAssets = animal.voiceAssetPath,
           let voicePath = (localizationService.currentLanguage == .ru ? voiceAssets.ru : voiceAssets.en),
           !voicePath.isEmpty {
            do {
                let data = try await assetService.loadAudioData(from: voicePath)
                try await audioService.playSound(from: data)
            } catch {
                await audioService.playVoice(
                    text: localizationService.currentLanguage == .ru ? "Это \(animalName)" : "This is a \(animalName)",
                    language: localizationService.currentLanguage.rawValue
                )
            }
        } else {
            await audioService.playVoice(
                text: localizationService.currentLanguage == .ru ? "Это \(animalName)" : "This is a \(animalName)",
                language: localizationService.currentLanguage.rawValue
            )
        }

        // Brief pause between narrator and animal sound
        try? await Task.sleep(nanoseconds: 500_000_000)

        // 2. Animal's own sound
        do {
            let soundData = try await assetService.loadAudioData(from: animal.soundAssetPath)
            try await audioService.playSound(from: soundData)
            await analyticsService.logEvent(
                eventType: "animal_sound_play",
                categoryId: categoryId,
                animalId: animal.id
            )
        } catch {
            // Silent fail — analytics will show this as "loaded but no sound"
        }
    }
}

// MARK: - Tap hint

private struct TapHintHand: View {
    @State private var pulse = false
    var body: some View {
        Image(systemName: "hand.point.up.fill")
            .font(.system(size: 60, weight: .regular))
            .foregroundStyle(DS.Palette.Neutral.n0.opacity(0.35))
            .scaleEffect(pulse ? 1.1 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

// MARK: - Lottie wrapper (kept for future animation wire-up)

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
