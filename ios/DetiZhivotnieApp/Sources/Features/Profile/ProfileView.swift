import SwiftUI

struct ProfileView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
    @StateObject private var localizationService = LocalizationService()
    @State private var showLanguagePicker = false
    @State private var showCategoryOrder = false
    @State private var showPurchases = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Любимые категории") {
                    Text("Пока нет данных. Играйте в приложение и они появятся.")
                        .foregroundColor(.secondary)
                }
                
                Section("Любимые слова") {
                    Text("Пока нет данных. Играйте в приложение и они появятся.")
                        .foregroundColor(.secondary)
                }
                
                Section("Настройки") {
                    NavigationLink(destination: CategoryOrderView()) {
                        Label("Порядок категорий", systemImage: "list.number")
                    }
                    
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Уведомления", systemImage: "bell")
                    }
                    
                    Toggle(isOn: $soundEffectsEnabled) {
                        Label("Звуковые эффекты", systemImage: "speaker.wave.2")
                    }
                    
                    Button(action: { showLanguagePicker = true }) {
                        HStack {
                            Label("Выбор языка", systemImage: "globe")
                            Spacer()
                            Text(localizationService.currentLanguage.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Дополнительно") {
                    NavigationLink(destination: PurchasesView()) {
                        Label("Мои покупки", systemImage: "bag")
                    }
                    
                    Button(action: {
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            SKStoreReviewController.requestReview(in: scene)
                        }
                    }) {
                        Label("Оценить приложение", systemImage: "star")
                    }
                    
                    ShareLink(item: URL(string: "https://apps.apple.com/app/id123456789")!) {
                        Label("Поделиться", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Профиль")
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerView()
            }
        }
    }
}

import StoreKit
