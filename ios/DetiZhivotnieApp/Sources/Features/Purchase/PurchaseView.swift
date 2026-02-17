import SwiftUI
import StoreKit

struct PurchaseView: View {
    let category: Category
    @StateObject private var iapService = IAPService()
    @Environment(\.dismiss) var dismiss
    @State private var showParentalGate = false
    @State private var showConfetti = false
    @State private var isPurchasing = false
    
    var product: Product? {
        iapService.products.first { $0.id == category.iapProductId }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Разблокировать категорию")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(localizedTitle)
                .font(.headline)
            
            if let product = product {
                Text(product.displayPrice)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Button(action: {
                showParentalGate = true
            }) {
                Text("Купить за \(product?.displayPrice ?? "")")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(isPurchasing || product == nil)
            
            Button(action: {
                Task {
                    await iapService.restorePurchases()
                    dismiss()
                }
            }) {
                Text("Восстановить покупки")
                    .foregroundColor(.secondary)
            }
            
            Button(action: { dismiss() }) {
                Text("Отмена")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
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
            await iapService.requestProducts()
        }
    }
    
    private var localizedTitle: String {
        // Используем локализацию из категории
        category.title.ru
    }
    
    private func performPurchase() async {
        guard let product = product else { return }
        
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let success = try await iapService.purchase(product)
            if success {
                await AnalyticsService().logEvent(eventType: "purchase_success", productId: product.id)
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
