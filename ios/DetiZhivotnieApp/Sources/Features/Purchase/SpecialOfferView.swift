import SwiftUI
import StoreKit

struct SpecialOfferView: View {
    let offer: Offer
    @StateObject private var iapService = IAPService()
    @StateObject private var assetService = AssetService()
    @Environment(\.dismiss) var dismiss
    @State private var showParentalGate = false
    @State private var showConfetti = false
    @State private var heroImages: [UIImage] = []
    @EnvironmentObject var localizationService: LocalizationService
    
    var primaryProduct: Product? {
        iapService.products.first { $0.id == offer.primaryProductId }
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    Text(localizedTitle)
                        .font(.system(size: 48, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 20) {
                        ForEach(heroImages.indices, id: \.self) { index in
                            if let image = heroImages[safe: index] {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                            }
                        }
                    }
                    
                    ForEach(offer.items, id: \.productId) { item in
                        OfferItemView(item: item)
                    }
                    
                    if let product = primaryProduct {
                        Button(action: {
                            showParentalGate = true
                        }) {
                            Text("Купить за \(product.displayPrice)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Назад") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showParentalGate) {
            ParentalGateView(
                onSuccess: {
                    showParentalGate = false
                    Task {
                        await performPurchase()
                    }
                },
                onCancel: {
                    showParentalGate = false
                }
            )
        }
        .overlay {
            if showConfetti {
                ConfettiView()
            }
        }
        .task {
            await loadAssets()
            await iapService.requestProducts()
        }
    }
    
    private var localizedTitle: String {
        localizationService.currentLanguage == .ru ? offer.title.ru : offer.title.en
    }
    
    private func loadAssets() async {
        for path in offer.heroAssets {
            do {
                let image = try await assetService.loadImage(from: path)
                heroImages.append(image)
            } catch {
                print("Ошибка загрузки hero asset: \(error)")
            }
        }
    }
    
    private func performPurchase() async {
        guard let product = primaryProduct else { return }
        
        do {
            let success = try await iapService.purchase(product)
            if success {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showConfetti = false
                    dismiss()
                }
            }
        } catch {
            print("Ошибка покупки: \(error)")
        }
    }
}

struct OfferItemView: View {
    let item: Offer.OfferItem
    @EnvironmentObject var localizationService: LocalizationService
    
    var body: some View {
        HStack {
            Text(localizedLabel)
            Spacer()
            if let badge = item.badge {
                Text(localizedBadge(badge))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var localizedLabel: String {
        localizationService.currentLanguage == .ru ? item.label.ru : item.label.en
    }
    
    private func localizedBadge(_ badge: Offer.LocalizedString) -> String {
        localizationService.currentLanguage == .ru ? badge.ru : badge.en
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
