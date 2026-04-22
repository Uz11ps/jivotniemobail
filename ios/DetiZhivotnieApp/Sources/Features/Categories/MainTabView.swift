//
//  MainTabView.swift
//  DetiZhivotnieApp
//
//  Root of the main app experience, rebuilt to match Figma `1:6650`.
//  Layout budgets from Figma (iPhone 14 / 15 — 390×844):
//    • Status bar   (0..59)    — system
//    • MainHeadline (59..123)  — h=64, home icon + title + profile
//    • CategoryHero (123..342) — h=219, category illustration
//    • AnimalBoard  (342..690) — h=348, 4-col grid
//    • CategoryTabBar (690..810) — h=120, floating pill
//    • Home indicator (810..844) — system
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var contentService = ContentService()
    @StateObject private var localizationService = LocalizationService()
    @StateObject private var iapService = IAPService()
    @State private var selectedCategoryId: String?
    @State private var selectedAnimalForNavigation: Animal?
    @State private var showProfile = false
    @State private var showPurchaseGate = false      // Parent gate for paywall
    @State private var isPerformingPurchase = false

    var body: some View {
        NavigationStack {
            ZStack {
                // ── Page background (category-themed gradient) ──
                LinearGradient(
                    colors: [theme.backgroundLight, theme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // ── Main content ──
                if contentService.categories.isEmpty {
                    ProgressView()
                        .tint(theme.label)
                } else {
                    VStack(spacing: 0) {
                        MainHeadline(
                            title: categoryTitle,
                            theme: theme,
                            onProfileTap: { showProfile = true }
                        )

                        CategoryHero(
                            imagePath: selectedCategory?.tabIconAssetPath,
                            videoPath: nil,
                            theme: theme
                        )

                        AnimalBoard(
                            animals: animals,
                            theme: theme,
                            categoryIsLocked: isSelectedLocked
                        ) { animal in
                            // Navigation handled by NavigationLink wrapper below
                            selectedAnimalForNavigation = animal
                        }
                    }
                }

                // ── Presale button (shown only when viewing a locked category) ──
                if isSelectedLocked {
                    VStack {
                        Spacer()
                        PresaleButton(
                            priceText: priceText,
                            theme: theme,
                            onTap: { showPurchaseGate = true }
                        )
                        .padding(.bottom, 120 + DS.Gap.gap400)   // above tab bar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isSelectedLocked)
                }

                // ── Floating tab bar ──
                VStack {
                    Spacer()
                    CategoryTabBar(
                        categories: contentService.categories,
                        selectedCategoryId: $selectedCategoryId,
                        purchasedProductIds: iapService.purchasedProductIds,
                        themeForSelected: theme,
                        onTapLocked: { category in
                            // Per Figma: tapping a locked tab still switches to
                            // the category (so user sees its hero + muted grid)
                            // and surfaces the presale button.
                            selectedCategoryId = category.id
                        }
                    )
                    .padding(.bottom, DS.Gap.gap400)
                }

            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedAnimalForNavigation) { animal in
                if let catId = selectedCategoryId {
                    AnimalDetailView(animal: animal, categoryId: catId)
                        .environmentObject(localizationService)
                }
            }
            .task {
                try? await contentService.loadCategories()
                if selectedCategoryId == nil {
                    selectedCategoryId = contentService.categories.first?.id
                }
            }
            .task(id: selectedCategoryId) {
                guard let id = selectedCategoryId else { return }
                try? await contentService.loadAnimals(for: id)
                await AnalyticsService().logEvent(eventType: "category_open", categoryId: id)
            }
            .fullScreenCover(isPresented: $showProfile) {
                CabinetEntryFlow()
                    .environmentObject(localizationService)
            }
            .fullScreenCover(isPresented: $showPurchaseGate) {
                if let category = selectedCategory {
                    ParentalGateView(
                        onSuccess: {
                            showPurchaseGate = false
                            Task { await attemptPurchase(for: category) }
                        },
                        onCancel: { showPurchaseGate = false }
                    )
                }
            }
        }
        .environmentObject(localizationService)
    }

    // MARK: - Derived state

    private var selectedCategory: Category? {
        guard let id = selectedCategoryId else { return nil }
        return contentService.categories.first { $0.id == id }
    }

    private var categoryTitle: String {
        guard let category = selectedCategory else { return "" }
        return localizationService.localized(category.title)
    }

    private var theme: CategoryTheme {
        CategoryTheme.theme(for: selectedCategoryId ?? "pets")
    }

    private var animals: [Animal] {
        guard let id = selectedCategoryId else { return [] }
        return contentService.animals[id] ?? []
    }

    private var isSelectedLocked: Bool {
        guard let category = selectedCategory, category.isPaid else { return false }
        if let iap = category.iapProductId {
            return !iapService.purchasedProductIds.contains(iap)
        }
        return true
    }

    private var priceText: String {
        guard let category = selectedCategory,
              let productId = category.iapProductId,
              let product = iapService.products.first(where: { $0.id == productId }) else {
            return "—"
        }
        return product.displayPrice
    }

    // MARK: - Purchase flow

    private func attemptPurchase(for category: Category) async {
        guard !isPerformingPurchase,
              let productId = category.iapProductId,
              let product = iapService.products.first(where: { $0.id == productId }) else { return }
        isPerformingPurchase = true
        defer { isPerformingPurchase = false }
        do {
            if try await iapService.purchase(product) {
                await AnalyticsService().logEvent(
                    eventType: "purchase_success",
                    productId: product.id,
                    categoryId: category.id
                )
            }
        } catch {
            // Silent — user can re-trigger via the presale button.
        }
    }
}
