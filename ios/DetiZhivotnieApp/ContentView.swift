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

    var body: some View {
        ZStack {
            if !splashFinished {
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
}
