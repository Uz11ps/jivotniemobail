//
//  OnboardingView.swift
//  DetiZhivotnieApp
//
//  First-launch swipe carousel. Not explicitly designed in Figma main flow;
//  we reuse the Pets theme gradient and DS tokens to stay visually cohesive
//  with the rest of the app.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var localizationService = LocalizationService()
    @State private var currentPage = 0

    private var pages: [OnboardingPage.Model] {
        let isRu = localizationService.currentLanguage == .ru
        return [
            OnboardingPage.Model(
                title: isRu ? "Добро пожаловать" : "Welcome",
                subtitle: isRu
                    ? "Изучайте животных вместе с нами"
                    : "Explore animals with us",
                systemIcon: "pawprint.fill",
                tint: DS.Palette.LightBlue.c500
            ),
            OnboardingPage.Model(
                title: isRu ? "Анимации и звуки" : "Animations and sounds",
                subtitle: isRu
                    ? "Слушайте голоса животных и смотрите анимации"
                    : "Hear animal sounds and watch animations",
                systemIcon: "waveform",
                tint: DS.Palette.Pink.c500
            ),
            OnboardingPage.Model(
                title: isRu ? "Начните прямо сейчас" : "Let's get started",
                subtitle: isRu
                    ? "Выберите категорию и начните изучение"
                    : "Pick a category and start exploring",
                systemIcon: "sparkles",
                tint: DS.Palette.Yellow.c500
            )
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [CategoryTheme.pets.backgroundLight, CategoryTheme.pets.background],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPage(model: page).tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        hasCompletedOnboarding = true
                    }
                }) {
                    Text(ctaText)
                        .dsStyle(.bodySemi)
                        .foregroundColor(DS.Palette.Neutral.n0)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Capsule().fill(DS.Color.Fill.accentPrimary))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, DS.Gap.gap400)
                .padding(.bottom, DS.Gap.gap1000)
                .opacity(currentPage == pages.count - 1 ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }

    private var ctaText: String {
        localizationService.currentLanguage == .ru ? "Продолжить" : "Get started"
    }
}

// MARK: - Page

struct OnboardingPage: View {
    struct Model {
        let title: String
        let subtitle: String
        let systemIcon: String
        let tint: Color
    }

    let model: Model

    var body: some View {
        VStack(spacing: DS.Gap.gap600) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DS.Palette.Neutral.n0.opacity(0.15))
                    .frame(width: 200, height: 200)
                Image(systemName: model.systemIcon)
                    .font(.system(size: 90, weight: .semibold))
                    .foregroundColor(DS.Palette.Neutral.n0)
            }

            Text(model.title)
                .dsStyle(.largeTitleBold)
                .foregroundColor(DS.Palette.Neutral.n0)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Gap.gap500)

            Text(model.subtitle)
                .dsStyle(.body)
                .foregroundColor(DS.Palette.Neutral.n0.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Gap.gap600)

            Spacer()
            Spacer()
        }
    }
}
