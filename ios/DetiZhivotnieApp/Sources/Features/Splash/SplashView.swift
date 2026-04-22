//
//  SplashView.swift
//  DetiZhivotnieApp
//
//  Figma: `1:6669` (Splash) + `1:6672` (Splash + Notification alert).
//
//  Behaviour:
//   • Dark forest-green background (outside the palette — splash-specific).
//   • Centered looping video of animals (bear/cow/bird/tiger/cat/rooster/hen).
//     When the video asset isn't bundled yet, falls back to a still collage
//     or a simple SF Symbol placeholder.
//   • Requests notification permission 500ms after appearing (Figma: 1:6672).
//   • Transitions out when:
//       – the content cache has loaded, AND
//       – a minimum display time has elapsed (prevents flicker on fast devices).
//

import SwiftUI
import AVKit
import UserNotifications

struct SplashView: View {
    /// Called once both the cache is ready and the minimum display window
    /// has elapsed. The host view routes to Onboarding or MainTab accordingly.
    var onReady: () -> Void

    @StateObject private var contentService = ContentService()
    @State private var minDisplayElapsed = false
    @State private var cacheReady = false
    @State private var notificationRequested = false

    private let minDisplaySeconds: Double = 1.5
    private let notificationDelaySeconds: Double = 0.5

    /// Dark forest green — splash-only, not in Figma token variables.
    /// Approximates the background shown in Figma 1:6669.
    private let splashBackground = Color(hex: 0x3F6B47)

    var body: some View {
        ZStack {
            splashBackground.ignoresSafeArea()

            // Looping animal video / collage
            AnimalCollageLoop()
                .ignoresSafeArea()
        }
        .task {
            // Start minimum display timer
            try? await Task.sleep(nanoseconds: UInt64(minDisplaySeconds * 1_000_000_000))
            minDisplayElapsed = true
            tryFinish()
        }
        .task {
            // Preload categories into the cache
            try? await contentService.loadCategories()
            cacheReady = true
            tryFinish()
        }
        .task {
            // Request notification permission shortly after appearing (Figma 1:6672)
            try? await Task.sleep(nanoseconds: UInt64(notificationDelaySeconds * 1_000_000_000))
            guard !notificationRequested else { return }
            notificationRequested = true
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        }
    }

    private func tryFinish() {
        guard minDisplayElapsed, cacheReady else { return }
        onReady()
    }
}

// MARK: - Animal collage loop

/// Placeholder for the looping animal video. When a bundled video asset
/// ("splash_animals.mp4") is available it plays looped; otherwise shows a
/// bundled still image "splash_animals" from Assets.xcassets, or finally a
/// gentle SF Symbol fallback.
private struct AnimalCollageLoop: View {
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .disabled(true)
                    .aspectRatio(contentMode: .fill)
            } else if UIImage(named: "splash_animals") != nil {
                Image("splash_animals")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal, DS.Gap.gap400)
            } else {
                // Minimal fallback so the screen isn't empty before assets are bundled.
                VStack(spacing: DS.Gap.gap200) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 72, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("…")
                        .dsStyle(.title2Bold)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .onAppear(perform: setupPlayer)
        .onDisappear { player?.pause() }
    }

    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: "splash_animals", withExtension: "mp4") else {
            return
        }
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer()
        looper = AVPlayerLooper(player: queue, templateItem: item)
        queue.isMuted = true
        queue.play()
        player = queue
    }
}

#Preview {
    SplashView(onReady: {})
}
