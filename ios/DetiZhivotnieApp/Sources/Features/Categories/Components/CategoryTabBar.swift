//
//  CategoryTabBar.swift
//  DetiZhivotnieApp
//
//  Figma: `1:6654` — NavBar (h = 120 at y=690..810).
//  A translucent pill floating above content with horizontally-scrolling
//  category icons. Active = solid white circle with tinted icon.
//  Locked = translucent disc with a tiny lock badge.
//

import SwiftUI

struct CategoryTabBar: View {
    let categories: [Category]
    @Binding var selectedCategoryId: String?
    let purchasedProductIds: Set<String>
    let themeForSelected: CategoryTheme
    var onTapLocked: (Category) -> Void = { _ in }

    @StateObject private var assetService = AssetService()

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Gap.gap300) {
                ForEach(categories) { category in
                    CategoryTabIcon(
                        category: category,
                        isSelected: selectedCategoryId == category.id,
                        isLocked: isLocked(category),
                        theme: themeForSelected
                    ) {
                        if isLocked(category) {
                            onTapLocked(category)
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedCategoryId = category.id
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, DS.Gap.gap500)
        }
        .padding(.vertical, DS.Gap.gap300)
        .background(
            Capsule()
                .fill(themeForSelected.tabBar.opacity(0.75))
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Capsule()
                        .stroke(themeForSelected.tabBarOutline.opacity(0.6), lineWidth: 1)
                )
        )
        .padding(.horizontal, DS.Gap.gap400)
    }

    private func isLocked(_ category: Category) -> Bool {
        guard category.isPaid else { return false }
        if let iap = category.iapProductId {
            return !purchasedProductIds.contains(iap)
        }
        return true
    }
}

// MARK: - Individual tab icon

private struct CategoryTabIcon: View {
    let category: Category
    let isSelected: Bool
    let isLocked: Bool
    let theme: CategoryTheme
    var onTap: () -> Void

    @StateObject private var assetService = AssetService()
    @State private var iconImage: UIImage?

    private let diameter: CGFloat = 56

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(backgroundFill)

                Group {
                    if let image = iconImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        // Placeholder emoji-style fallback
                        Image(systemName: iconFallback)
                            .font(.system(size: 24, weight: .medium))
                    }
                }
                .foregroundColor(iconTint)
                .padding(10)

                if isLocked {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(theme.label)
                                .padding(4)
                                .background(Circle().fill(theme.tabBarOutline))
                        }
                    }
                    .frame(width: diameter, height: diameter)
                }
            }
            .frame(width: diameter, height: diameter)
        }
        .buttonStyle(.plain)
        .task { await loadIcon() }
    }

    private var backgroundFill: Color {
        if isSelected { return DS.Palette.Neutral.n0 }
        if isLocked   { return theme.tabBar.opacity(0.5) }
        return theme.tabBar.opacity(0.7)
    }

    private var iconTint: Color {
        isSelected ? theme.tabBar : theme.label
    }

    private var iconFallback: String {
        switch category.id {
        case "pets":         return "house.fill"
        case "farm", "barn": return "tray.fill"
        case "forest":       return "tree.fill"
        case "sea":          return "water.waves"
        default:             return "pawprint.fill"
        }
    }

    private func loadIcon() async {
        do {
            iconImage = try await assetService.loadImage(from: category.tabIconAssetPath)
        } catch {
            // Keep system fallback
        }
    }
}
