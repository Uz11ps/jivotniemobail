//
//  PurchaseView.swift
//  DetiZhivotnieApp
//
//  Figma: Single-category paywall — shown when a deep link lands on a
//  specific locked category. The primary paywall pattern is the in-context
//  PresaleButton inside MainTabView; this view is a full-screen fallback
//  that mirrors the same visuals (category theme gradient + price CTA).
//

import SwiftUI
import StoreKit

struct PurchaseView: View {
    let category: Category

    @StateObject private var iapService = IAPService()
    @StateObject private var assetService = AssetService()
    @EnvironmentObject var localizationService: LocalizationService
    @Environment(\.dismiss) private var dismiss

    @State private var showParentalGate = false
    @State private var showConfetti = false
    @State private var isPurchasing = false
    @State private var heroImage: UIImage?

    var product: Product? {
        iapService.products.first { $0.id == category.iapProductId }
    }

    private var theme: CategoryTheme {
        CategoryTheme.theme(for: category.id)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [theme.backgroundLight, theme.background],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: DS.Gap.gap500) {
                Spacer()

                // Category hero
                Group {
                    if let image = heroImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "pawprint.circle.fill")
                            .font(.system(size: 140))
                            .foregroundStyle(theme.label, theme.tabBar)
                    }
                }
                .frame(height: 240)
                .padding(.horizontal, DS.Gap.gap600)

                Text(localizationService.localized(category.title))
                    .dsStyle(.largeTitleBold)
                    .foregroundColor(theme.label)

                Text("Unlock this pack and enjoy all animals inside")
                    .dsStyle(.body)
                    .foregroundColor(theme.label.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Gap.gap600)

                Spacer()

                Button(action: { showParentalGate = true }) {
                    HStack {
                        Image(systemName: "lock.open.fill")
                        Text("Unlock \(product?.displayPrice ?? "")")
                    }
                    .dsStyle(.bodySemi)
                    .foregroundColor(DS.Palette.Neutral.n0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Capsule().fill(DS.Color.Fill.accentPrimary))
                }
                .buttonStyle(.plain)
                .disabled(isPurchasing || product == nil)
                .padding(.horizontal, DS.Gap.gap400)

                Button(action: {
                    Task {
                        await iapService.restorePurchases()
                        dismiss()
                    }
                }) {
                    Text("Restore purchases")
                        .dsStyle(.footnoteSemi)
                        .foregroundColor(theme.label.opacity(0.85))
                }
                .padding(.bottom, DS.Gap.gap500)
            }

            // Back
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
                        .background(Capsule().fill(DS.Palette.Neutral.n0.opacity(0.8)))
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
            await iapService.requestProducts()
            heroImage = try? await assetService.loadImage(from: category.tabIconAssetPath)
        }
    }

    private func performPurchase() async {
        guard let product = product else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            if try await iapService.purchase(product) {
                await AnalyticsService().logEvent(
                    eventType: "purchase_success",
                    categoryId: category.id,
                    productId: product.id
                )
                showConfetti = true
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    showConfetti = false
                    dismiss()
                }
            }
        } catch {
            // TODO: surface error via alert.
        }
    }
}
