import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            OnboardingPage(
                title: "Добро пожаловать",
                subtitle: "Изучайте животных вместе с нами",
                illustration: "🐾"
            )
            .tag(0)
            
            OnboardingPage(
                title: "Анимации и звуки",
                subtitle: "Слушайте голоса животных и смотрите анимации",
                illustration: "🎵"
            )
            .tag(1)
            
            OnboardingPage(
                title: "Начните сейчас",
                subtitle: "Выберите категорию и начните изучение",
                illustration: "🚀"
            )
            .tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .overlay(alignment: .bottom) {
            if currentPage == 2 {
                Button(action: {
                    hasCompletedOnboarding = true
                }) {
                    Text("Продолжить")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let illustration: String
    
    var body: some View {
        VStack(spacing: 30) {
            Text(illustration)
                .font(.system(size: 100))
            
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
