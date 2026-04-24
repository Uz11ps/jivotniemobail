//
//  ParentCabinetView.swift
//  DetiZhivotnieApp
//
//  Figma: `1:7076` — Parent Cabinet (390×1204, scrollable).
//  Sections:
//    • Favorite categories (horizontal scroll, usage %)
//    • Top 10 favorite animals (horizontal scroll, usage %)
//    • Settings (Sections sequence, Language, Notifications toggle,
//                Music on background toggle)
//    • Additional (My purchases, Rate the app, Share app)
//    • Telegram CTA button
//    • Version + Terms/Privacy link
//

import SwiftUI
import StoreKit

struct ParentCabinetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationService: LocalizationService
    @StateObject private var contentService = ContentService()

    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("musicInBackgroundEnabled") private var musicInBackgroundEnabled = true

    @State private var showLanguagePicker = false
    @State private var showCategoryOrder = false
    @State private var showPurchases = false

    // MARK: - URLs (configure per build)
    private let telegramURL = URL(string: "https://t.me/DetiZhivotnieApp")!
    private let termsURL = URL(string: "https://example.com/terms")!
    private let appStoreShareURL = URL(string: "https://apps.apple.com/app/id123456789")!

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return v
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.Background.primary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DS.Gap.gap500) {
                        favoriteCategoriesCard
                        favoriteAnimalsCard
                        settingsSection
                        additionalSection
                        telegramCTA
                        footer
                    }
                    .padding(.horizontal, DS.Gap.gap400)
                    .padding(.top, DS.Gap.gap300)
                    .padding(.bottom, DS.Gap.gap600)
                }
            }
            .navigationTitle("Parent Cabinet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(DS.Color.Icon.primary)
                    }
                }
            }
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerView().environmentObject(localizationService)
            }
            .sheet(isPresented: $showCategoryOrder) {
                CategoryOrderView().environmentObject(localizationService)
            }
            .sheet(isPresented: $showPurchases) {
                PurchasesView().environmentObject(localizationService)
            }
            .task {
                try? await contentService.loadCategories()
            }
        }
    }

    // MARK: - Favorite categories

    private var favoriteCategoriesCard: some View {
        // TODO: wire to AnalyticsService aggregated usage rollup.
        let items: [FavoriteItem] = contentService.categories.prefix(8).map { cat in
            FavoriteItem(
                id: cat.id,
                title: localizationService.localized(cat.title),
                percent: 0,
                assetPath: cat.tabIconAssetPath,
                tint: CategoryTheme.theme(for: cat.id).tabBar
            )
        }
        return FavoritesCard(title: "Favorite categories", items: items) { item in
            CategoryIconAsync(item: item)
        }
    }

    // MARK: - Favorite animals

    private var favoriteAnimalsCard: some View {
        // TODO: aggregate from analytics; placeholder uses category 0.
        let animals = contentService.categories.first.flatMap { contentService.animals[$0.id] } ?? []
        let items: [FavoriteItem] = animals.prefix(10).map { a in
            FavoriteItem(
                id: a.id,
                title: localizationService.localized(a.name),
                percent: 0,
                assetPath: a.previewAssetPath,
                tint: DS.Palette.Pink.c400
            )
        }
        return FavoritesCard(title: "Top 10 favorite animals", items: items) { item in
            AnimalIconAsync(item: item)
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: DS.Gap.gap200) {
            Text("Settings")
                .dsStyle(.title3Semi)
                .foregroundColor(DS.Color.Label.primary)
                .padding(.leading, DS.Gap.gap100)

            SettingsCard(rows: [
                AnyView(SettingsRow(
                    iconSystemName: "list.number",
                    iconTint: DS.Palette.Pink.c500,
                    title: "Sections sequence",
                    onTap: { showCategoryOrder = true }
                )),
                AnyView(SettingsRow(
                    iconSystemName: "globe",
                    iconTint: DS.Palette.Turquoise.c500,
                    title: "Language",
                    onTap: { showLanguagePicker = true }
                ) {
                    ValueChevronTrailing(value: localizationService.currentLanguage.displayName)
                }),
                AnyView(SettingsRow(
                    iconSystemName: "bell.fill",
                    iconTint: DS.Palette.Yellow.c500,
                    title: "Notifications"
                ) {
                    Toggle("", isOn: $notificationsEnabled)
                        .labelsHidden()
                        .tint(DS.Color.Fill.accentPrimary)
                }),
                AnyView(SettingsRow(
                    iconSystemName: "speaker.wave.2.fill",
                    iconTint: DS.Palette.Blue.c500,
                    title: "Music on background"
                ) {
                    Toggle("", isOn: $musicInBackgroundEnabled)
                        .labelsHidden()
                        .tint(DS.Color.Fill.accentPrimary)
                })
            ])
        }
    }

    // MARK: - Additional

    private var additionalSection: some View {
        VStack(alignment: .leading, spacing: DS.Gap.gap200) {
            Text("Additional")
                .dsStyle(.title3Semi)
                .foregroundColor(DS.Color.Label.primary)
                .padding(.leading, DS.Gap.gap100)

            SettingsCard(rows: [
                AnyView(SettingsRow(
                    iconSystemName: "cart.fill",
                    iconTint: DS.Palette.Green.c500,
                    title: "My purchases",
                    onTap: { showPurchases = true }
                )),
                AnyView(SettingsRow(
                    iconSystemName: "star.fill",
                    iconTint: DS.Palette.Orange.c500,
                    title: "Rate the app",
                    onTap: {
                        if let scene = UIApplication.shared.connectedScenes
                            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                            SKStoreReviewController.requestReview(in: scene)
                        }
                    }
                )),
                AnyView(SettingsRow(
                    iconSystemName: "square.and.arrow.up",
                    iconTint: DS.Palette.Turquoise.c500,
                    title: "Share app"
                ) {
                    ShareLink(item: appStoreShareURL) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(DS.Color.Icon.accent)
                    }
                })
            ])
        }
    }

    // MARK: - Telegram CTA

    private var telegramCTA: some View {
        HStack {
            Spacer()
            TelegramCTAButton {
                UIApplication.shared.open(telegramURL)
            }
            Spacer()
        }
        .padding(.top, DS.Gap.gap300)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: DS.Gap.gap100) {
            Text("Application version \(appVersion)")
                .dsStyle(.footnote)
                .foregroundColor(DS.Color.Label.secondary)

            Link(destination: termsURL) {
                Text("Terms of Use and Privacy Policy")
                    .dsStyle(.footnote)
                    .foregroundColor(DS.Color.Label.accent)
                    .underline()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DS.Gap.gap200)
    }
}

// MARK: - Async icons

private struct CategoryIconAsync: View {
    let item: FavoriteItem
    @StateObject private var assetService = AssetService()
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // Tinted SF Symbol fallback while the asset loads.
                Image(systemName: fallbackSymbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(item.tint)
            }
        }
        .task {
            guard let path = item.assetPath else { return }
            image = try? await assetService.loadImage(from: path)
        }
    }

    private var fallbackSymbol: String {
        switch item.id {
        case "pets":                    return "house.fill"
        case "farm":     return "tray.fill"
        case "forest":   return "tree.fill"
        case "savannah": return "sun.max.fill"
        case "pond":     return "water.waves"
        case "jungle":   return "leaf.fill"
        default:                        return "pawprint.fill"
        }
    }
}

private struct AnimalIconAsync: View {
    let item: FavoriteItem
    @StateObject private var assetService = AssetService()
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(item.tint)
            }
        }
        .task {
            guard let path = item.assetPath else { return }
            image = try? await assetService.loadImage(from: path)
        }
    }
}
