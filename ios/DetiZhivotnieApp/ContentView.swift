//
//  ContentView.swift
//  DetiZhivotnieApp
//
//  Root navigator. Implements the Figma "0. Main flow" entry sequence:
//    SplashView  →  OnboardingView (first launch only)  →  MainTabView
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var splashFinished = false

    /// Debug shortcut for visual QA: pass `-startAt cabinet|gate|paywall|specialOffer|errorMistake|errorOffline`
    /// in the scheme arguments to land directly on a screen.
    private var debugStart: String? {
        guard let arg = ProcessInfo.processInfo.arguments.firstIndex(of: "-startAt"),
              ProcessInfo.processInfo.arguments.indices.contains(arg + 1) else { return nil }
        return ProcessInfo.processInfo.arguments[arg + 1]
    }

    var body: some View {
        ZStack {
            if let target = debugStart {
                debugRoot(target: target)
            } else if !splashFinished {
                SplashView(onReady: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        splashFinished = true
                    }
                })
                .transition(.opacity)
            } else if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private func debugRoot(target: String) -> some View {
        let loc = LocalizationService()
        switch target {
        case "cabinet":
            ParentCabinetView()
                .environmentObject(loc)
        case "gate":
            ParentalGateView(onSuccess: {}, onCancel: {})
                .environmentObject(loc)
        case "paywall":
            PurchaseView(category: DemoContent.categories[2])     // Forest
                .environmentObject(loc)
        case "specialOffer":
            // Synthesise a quick offer from the demo categories.
            let offer = Offer(
                id: "demo",
                isActive: true,
                title: .init(ru: "Купи все паки со скидкой!", en: "Get all the packs at a great discount!"),
                heroAssets: [],
                items: [
                    .init(label: .init(ru: "All categories\nFor 5 locked packs", en: "All categories\nFor 5 locked packs"),
                          productId: "com.app.bundle.all", badge: .init(ru: "-20%", en: "-20%")),
                    .init(label: .init(ru: "Only «Forest» Pack\n$1.99", en: "Only «Forest» Pack\n$1.99"),
                          productId: "com.app.category.forest", badge: nil)
                ],
                primaryProductId: "com.app.bundle.all"
            )
            SpecialOfferView(offer: offer)
                .environmentObject(loc)
        case "errorMistake":
            ErrorStateView(variant: .generic, onReload: {}, onBack: {})
        case "errorOffline":
            ErrorStateView(variant: .offline, onReload: {})
        case "onboarding":
            OnboardingView()
        default:
            MainTabView()
                .environmentObject(loc)
        }
    }
}
