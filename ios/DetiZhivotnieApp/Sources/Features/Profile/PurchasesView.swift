import SwiftUI

struct PurchasesView: View {
    @StateObject private var iapService = IAPService()
    
    var body: some View {
        List {
            if iapService.purchasedProductIds.isEmpty {
                VStack(spacing: 20) {
                    Text("🎁")
                        .font(.system(size: 80))
                    
                    Text("Еще ничего не купили")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Купите дополнительные паки и киндер будет кайфовать")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        // Переход к экрану покупок
                    }) {
                        Text("Купить паки")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ForEach(Array(iapService.purchasedProductIds), id: \.self) { productId in
                    Text(productId)
                }
            }
        }
        .navigationTitle("Мои покупки")
        .task {
            await iapService.restorePurchases()
        }
    }
}
