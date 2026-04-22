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
    @State private var showPurchaseSheet = false
    @State private var lockedCategoryForSheet: Category?

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

                // ── Floating tab bar ──
                VStack {
                    Spacer()
                    CategoryTabBar(
                        categories: contentService.categories,
                        selectedCategoryId: $selectedCategoryId,
                        purchasedProductIds: iapService.purchasedProductIds,
                        themeForSelected: theme,
                        onTapLocked: { category in
                            lockedCategoryForSheet = category
                            showPurchaseSheet = true
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
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environmentObject(localizationService)
            }
            .sheet(isPresented: $showPurchaseSheet) {
                if let cat = lockedCategoryForSheet {
                    PurchaseView(category: cat)
                        .environmentObject(localizationService)
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
}
