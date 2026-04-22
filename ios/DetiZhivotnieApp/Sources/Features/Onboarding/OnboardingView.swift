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
            .init(
                titleRu: "Добро пожаловать",
                titleEn: "Welcome",
                subtitleRu: "Изучайте животных вместе с нами",
                subtitleEn: "Explore animals with us",
                systemIcon: "pawprint.fill",
                tint: DS.Palette.LightBlue.c500
            ),
            .init(
                titleRu: "Анимации и звуки",
                titleEn: "Animations and sounds",
                subtitleRu: "Слушайте голоса животных и смотрите анимации",
                subtitleEn: "Hear animal sounds and watch animations",
                systemIcon: "waveform",
                tint: DS.Palette.Pink.c500
            ),
            .init(
                titleRu: "Начните прямо сейчас",
                titleEn: "Let's get started",
                subtitleRu: "Выберите категорию и начните изучение",
                subtitleEn: "Pick a category and start exploring",
                systemIcon: "sparkles",
                tint: DS.Palette.Yellow.c500
            )
        ].map { .init(
            title: isRu ? $0.titleRu : $0.titleEn,
            subtitle: isRu ? $0.subtitleRu : $0.subtitleEn,
            systemIcon: $0.systemIcon,
            tint: $0.tint
        )}
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

        // Localised fallbacks used by OnboardingView to build pages.
        init(
            title: String, subtitle: String,
            systemIcon: String, tint: Color
        ) {
            self.title = title
            self.subtitle = subtitle
            self.systemIcon = systemIcon
            self.tint = tint
        }

        init(
            titleRu: String, titleEn: String,
            subtitleRu: String, subtitleEn: String,
            systemIcon: String, tint: Color
        ) {
            self.title = titleEn
            self.subtitle = subtitleEn
            self.systemIcon = systemIcon
            self.tint = tint
        }
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
