//
//  SpecialOfferView.swift
//  DetiZhivotnieApp
//
//  Figma: `1:7006` — 1.1 Special offer (pink 390×844).
//  Pink background, "SPECIAL OFFER" bubble illustration, three animal heads,
//  white title, 2 selection rows (all-categories vs single pack), blue CTA.
//

import SwiftUI
import StoreKit

struct SpecialOfferView: View {
    let offer: Offer
    @StateObject private var iapService = IAPService()
    @StateObject private var assetService = AssetService()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationService: LocalizationService

    @State private var showParentalGate = false
    @State private var showConfetti = false
    @State private var heroImages: [UIImage] = []
    @State private var selectedProductId: String?

    var primaryProduct: Product? {
        iapService.products.first { $0.id == offer.primaryProductId }
    }

    var body: some View {
        ZStack {
            DS.Color.Background.sales.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Gap.gap500) {
                    // "SPECIAL OFFER" bubble text + discount badge
                    ZStack(alignment: .topTrailing) {
                        if UIImage(named: "special_offer_logo") != nil {
                            Image("special_offer_logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 120)
                                .padding(.horizontal, DS.Gap.gap600)
                        } else {
                            SpecialOfferTitleArt()
                                .frame(height: 120)
                                .padding(.horizontal, DS.Gap.gap600)
                        }

                        Text(discountBadgeText)
                            .dsStyle(.headlineSemi)
                            .foregroundColor(DS.Palette.Neutral.n0)
                            .padding(.horizontal, DS.Gap.gap300)
                            .padding(.vertical, DS.Gap.gap200)
                            .background(Capsule().fill(DS.Color.Fill.accentPrimary))
                            .offset(x: -16, y: -8)
                    }
                    .padding(.top, DS.Gap.gap200)

                    // Three animal heads — prefer bundled Figma composition,
                    // then Firebase-loaded per-offer heroAssets, then SF Symbols.
                    Group {
                        if UIImage(named: "special_offer_heads") != nil {
                            Image("special_offer_heads")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            HeroHeadsRow(images: heroImages)
                        }
                    }
                    .frame(height: 140)

                    // Title
                    Text(localizedTitle)
                        .dsStyle(.title2Bold)
                        .foregroundColor(DS.Palette.Neutral.n0)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Gap.gap600)

                    // Selection rows
                    VStack(spacing: DS.Gap.gap200) {
                        ForEach(offer.items, id: \.productId) { item in
                            OfferSelectionRow(
                                item: item,
                                isSelected: selectedProductId == item.productId,
                                priceText: priceText(for: item.productId)
                            )
                            .onTapGesture { selectedProductId = item.productId }
                        }
                    }
                    .padding(.horizontal, DS.Gap.gap400)

                    // CTA
                    Button(action: { showParentalGate = true }) {
                        Text("Buy for \(priceText(for: selectedProductId ?? offer.primaryProductId))")
                            .dsStyle(.bodySemi)
                            .foregroundColor(DS.Palette.Neutral.n0)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Capsule().fill(DS.Color.Fill.accentPrimary))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, DS.Gap.gap400)
                    .padding(.top, DS.Gap.gap300)

                    Spacer(minLength: DS.Gap.gap600)
                }
            }

            // Back button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: DS.Gap.gap100) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .dsStyle(.subheadlineSemi)
                        }
                        .foregroundColor(DS.Palette.Neutral.n900)
                        .padding(.horizontal, DS.Gap.gap300)
                        .padding(.vertical, DS.Gap.gap200)
                        .background(Capsule().fill(DS.Palette.Neutral.n0.opacity(0.7)))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, DS.Gap.gap400)
                .padding(.top, DS.Gap.gap300)
                Spacer()
            }

            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showParentalGate) {
            ParentalGateView(
                onSuccess: {
                    showParentalGate = false
                    Task { await performPurchase() }
                },
                onCancel: { showParentalGate = false }
            )
        }
        .task {
            await loadAssets()
            await iapService.requestProducts()
            if selectedProductId == nil { selectedProductId = offer.primaryProductId }
        }
    }

    private var localizedTitle: String {
        localizationService.currentLanguage == .ru ? offer.title.ru : offer.title.en
    }

    private var discountBadgeText: String {
        // "-20%" etc. Take the first offer item's badge as a rough proxy,
        // falling back to "-20%".
        if let badge = offer.items.first?.badge {
            return localizationService.currentLanguage == .ru ? badge.ru : badge.en
        }
        return "-20%"
    }

    private func priceText(for productId: String) -> String {
        guard let product = iapService.products.first(where: { $0.id == productId }) else {
            return ""
        }
        return product.displayPrice
    }

    private func loadAssets() async {
        heroImages = []
        for path in offer.heroAssets {
            if let image = try? await assetService.loadImage(from: path) {
                heroImages.append(image)
            }
        }
    }

    private func performPurchase() async {
        let productId = selectedProductId ?? offer.primaryProductId
        guard let product = iapService.products.first(where: { $0.id == productId }) else { return }
        do {
            if try await iapService.purchase(product) {
                showConfetti = true
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    showConfetti = false
                    dismiss()
                }
            }
        } catch {
            // TODO: surface error via alert
        }
    }
}

// MARK: - Components

private struct SpecialOfferTitleArt: View {
    var body: some View {
        // Bubble-lettering placeholder — each letter in a candy palette.
        let letters = Array("SPECIAL OFFER")
        let colors: [Color] = [
            DS.Palette.Orange.c500, DS.Palette.Pink.c400, DS.Palette.Yellow.c500,
            DS.Palette.Green.c400,  DS.Palette.Blue.c400,  DS.Palette.Turquoise.c500,
            DS.Palette.Orange.c400, DS.Palette.Pink.c500,  DS.Palette.Yellow.c400,
            DS.Palette.Green.c500,  DS.Palette.Blue.c500,  DS.Palette.Turquoise.c400
        ]
        return VStack(spacing: -8) {
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    if letters[safe: i] != nil, letters[i] != " " {
                        Text(String(letters[i]))
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundColor(colors[i % colors.count])
                            .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                    }
                }
            }
            HStack(spacing: 0) {
                ForEach(7..<letters.count, id: \.self) { i in
                    if letters[i] != " " {
                        Text(String(letters[i]))
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundColor(colors[i % colors.count])
                            .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                    }
                }
            }
        }
    }
}

private struct HeroHeadsRow: View {
    let images: [UIImage]
    var body: some View {
        HStack(spacing: -10) {
            ForEach(0..<max(3, images.count), id: \.self) { idx in
                if let img = images[safe: idx] {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: fallback(for: idx))
                        .font(.system(size: 80, weight: .regular))
                        .foregroundStyle(
                            Color.white,
                            DS.Palette.Orange.c400
                        )
                }
            }
        }
    }

    private func fallback(for idx: Int) -> String {
        switch idx {
        case 0:  return "bird.fill"
        case 1:  return "pawprint.fill"
        default: return "fish.fill"
        }
    }
}

private struct OfferSelectionRow: View {
    let item: Offer.OfferItem
    let isSelected: Bool
    let priceText: String
    @EnvironmentObject var localizationService: LocalizationService

    var body: some View {
        HStack(alignment: .center, spacing: DS.Gap.gap300) {
            VStack(alignment: .leading, spacing: 2) {
                Text(localizedLabel)
                    .dsStyle(.bodySemi)
                    .foregroundColor(isSelected ? DS.Color.Label.accent : DS.Palette.Neutral.n0)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            if let badge = item.badge {
                Text(localizedString(badge))
                    .dsStyle(.footnoteSemi)
                    .foregroundColor(DS.Palette.Neutral.n0)
                    .padding(.horizontal, DS.Gap.gap200)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(DS.Color.Fill.accentPrimary))
            }
            if !priceText.isEmpty {
                Text(priceText)
                    .dsStyle(.bodySemi)
                    .foregroundColor(isSelected ? DS.Color.Label.accent : DS.Palette.Neutral.n0)
            }
        }
        .padding(.horizontal, DS.Gap.gap400)
        .frame(height: 66)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.l)
                .fill(isSelected ? DS.Palette.Neutral.n0 : DS.Palette.Neutral.n0.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.l)
                .strokeBorder(isSelected ? DS.Color.Outline.accent : Color.clear, lineWidth: 2)
        )
    }

    private var localizedLabel: String {
        localizedString(item.label)
    }

    private func localizedString(_ ls: Offer.LocalizedString) -> String {
        localizationService.currentLanguage == .ru ? ls.ru : ls.en
    }
}

// MARK: - Array safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
