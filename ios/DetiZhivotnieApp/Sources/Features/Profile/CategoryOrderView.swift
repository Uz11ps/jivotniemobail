//
//  CategoryOrderView.swift
//  DetiZhivotnieApp
//
//  Figma: `1:7304` (2.2.1 Sections sequence).
//  Header: "< Sections sequence" + "Change the order of categories" subtitle.
//  Top row: horizontal preview of category tab icons (blue circles).
//  Below: draggable list — each row shows tinted category icon tile, name,
//         and a drag-handle (⋮⋮). Editing is always on.
//

import SwiftUI

struct CategoryOrderView: View {
    @StateObject private var contentService = ContentService()
    @StateObject private var iapService = IAPService()
    @EnvironmentObject var localizationService: LocalizationService
    @Environment(\.dismiss) private var dismiss
    @State private var categories: [Category] = []

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.Background.primary.ignoresSafeArea()

                VStack(spacing: DS.Gap.gap500) {
                    // Preview strip
                    previewStrip
                        .padding(.top, DS.Gap.gap300)

                    // Draggable list card
                    List {
                        ForEach(categories) { category in
                            HStack(spacing: DS.Gap.gap300) {
                                RoundedRectangle(cornerRadius: DS.Radius.xs)
                                    .fill(CategoryTheme.theme(for: category.id).tabBar)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: fallbackSymbol(for: category.id))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    )

                                Text(localizationService.localized(category.title))
                                    .dsStyle(.body)
                                    .foregroundColor(DS.Color.Label.primary)

                                Spacer()

                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(DS.Color.Icon.tertiary)
                            }
                            .padding(.vertical, DS.Gap.gap100)
                            .listRowBackground(DS.Color.Background.primaryElevated)
                        }
                        .onMove(perform: move)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .environment(\.editMode, .constant(.active))
                }
            }
            .navigationTitle("Sections sequence")
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
            .task { await loadCategories() }
        }
    }

    private var previewStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Gap.gap300) {
                ForEach(categories) { category in
                    let theme = CategoryTheme.theme(for: category.id)
                    ZStack {
                        Circle()
                            .fill(theme.tabBar.opacity(0.85))
                        Image(systemName: fallbackSymbol(for: category.id))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 56, height: 56)
                }
            }
            .padding(.horizontal, DS.Gap.gap400)
        }
    }

    private func loadCategories() async {
        try? await contentService.loadCategories()
        categories = contentService.categories.filter {
            !$0.isPaid || iapService.purchasedProductIds.contains($0.iapProductId ?? "")
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        // TODO: persist new order (UserDefaults/Firestore).
    }

    private func fallbackSymbol(for id: String) -> String {
        switch id {
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
