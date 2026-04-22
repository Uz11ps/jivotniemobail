//
//  PurchasesView.swift
//  DetiZhivotnieApp
//
//  Figma: `1:7571` (2.4.1 newbie) + `1:7707` (2.4.2 profi user).
//  Newbie: centered tiger illustration, "no purchases" text, "Go shopping!" CTA.
//  Profi: list of purchase cards with id, copy button, date/time/price/card.
//

import SwiftUI
import StoreKit

struct PurchasesView: View {
    @StateObject private var iapService = IAPService()
    @StateObject private var contentService = ContentService()
    @EnvironmentObject var localizationService: LocalizationService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.Background.primary.ignoresSafeArea()

                Group {
                    if iapService.purchasedProductIds.isEmpty {
                        newbieState
                    } else {
                        profiState
                    }
                }
            }
            .navigationTitle("My purchases")
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
            .task {
                await iapService.restorePurchases()
                try? await contentService.loadCategories()
            }
        }
    }

    // MARK: - Newbie

    private var newbieState: some View {
        VStack(spacing: DS.Gap.gap500) {
            Spacer()

            // Tiger / animal hero (SF Symbol fallback until bundled asset lands)
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 160, weight: .regular))
                .foregroundStyle(DS.Palette.Orange.c500, DS.Palette.Orange.c100)
                .shadow(color: DS.Palette.Orange.c600.opacity(0.3), radius: 20, y: 8)

            Text("You haven't made any purchases yet.\nMaybe we should buy some?")
                .dsStyle(.body)
                .foregroundColor(DS.Color.Label.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Gap.gap600)

            Button {
                dismiss()
                // TODO: navigate Main → Paywall. For now, just closes sheet.
            } label: {
                Text("Go shopping!")
                    .dsStyle(.bodySemi)
                    .foregroundColor(.white)
                    .padding(.horizontal, DS.Gap.gap600)
                    .frame(height: 44)
                    .background(Capsule().fill(DS.Color.Fill.accentPrimary))
            }
            .buttonStyle(.plain)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Profi

    private var profiState: some View {
        ScrollView {
            VStack(spacing: DS.Gap.gap400) {
                ForEach(Array(iapService.purchasedProductIds), id: \.self) { productId in
                    PurchaseCard(
                        productId: productId,
                        category: contentService.categories.first(where: { $0.iapProductId == productId }),
                        localizationService: localizationService
                    )
                }
            }
            .padding(.horizontal, DS.Gap.gap400)
            .padding(.top, DS.Gap.gap300)
            .padding(.bottom, DS.Gap.gap600)
        }
    }
}

// MARK: - Purchase card (profi flow)

private struct PurchaseCard: View {
    let productId: String
    let category: Category?
    let localizationService: LocalizationService

    @State private var didCopy = false

    /// Placeholder receipt info. TODO: fetch from App Store receipt/transaction.
    private let dateString = "23.03.26"
    private let timeString = "12:05"
    private let priceString = "$2.00"
    private let cardString = "* 3384"

    private var packTitle: String {
        if let category = category {
            return "\(localizationService.localized(category.title)) pack"
        }
        return productId
    }

    private var theme: CategoryTheme {
        CategoryTheme.theme(for: category?.id ?? "pets")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: DS.Gap.gap300) {
                RoundedRectangle(cornerRadius: DS.Radius.xs)
                    .fill(theme.tabBar)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    )

                Text(packTitle)
                    .dsStyle(.bodySemi)
                    .foregroundColor(DS.Color.Label.primary)

                Text("#\(productId.suffix(7))")
                    .dsStyle(.footnote)
                    .foregroundColor(DS.Color.Label.secondary)

                Spacer()

                Button {
                    UIPasteboard.general.string = productId
                    didCopy = true
                    Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        await MainActor.run { didCopy = false }
                    }
                } label: {
                    Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(DS.Color.Icon.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(DS.Gap.gap400)

            Rectangle().fill(DS.Color.separator).frame(height: 1)

            // Detail rows
            VStack(spacing: 0) {
                detailRow("Date and time of purchase", value: dateString)
                detailRow("Time of puchare", value: timeString)
                detailRow("Purchase price", value: priceString)
                detailRow("Card number", value: cardString)
            }
            .padding(.horizontal, DS.Gap.gap400)
            .padding(.vertical, DS.Gap.gap200)
        }
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.l)
                .fill(DS.Color.Background.primaryElevated)
        )
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .dsStyle(.subheadline)
                .foregroundColor(DS.Color.Label.secondary)
            Spacer()
            Text(value)
                .dsStyle(.subheadline)
                .foregroundColor(DS.Color.Label.primary)
        }
        .frame(height: 36)
    }
}
