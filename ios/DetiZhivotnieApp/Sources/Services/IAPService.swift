import Foundation
import StoreKit

@MainActor
class IAPService: ObservableObject {
    @Published var purchasedProductIds: Set<String> = []
    @Published var products: [Product] = []
    
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await requestProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func requestProducts() async {
        do {
            let productIds = ["com.app.category.insects", "com.app.category.transport"] // Загружать из Firestore
            products = try await Product.products(for: productIds)
        } catch {
            print("Ошибка загрузки продуктов: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }
    
    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }
    
    private func updatePurchasedProducts() async {
        var purchasedIds: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if let productId = transaction.productID as String? {
                    purchasedIds.insert(productId)
                }
            } catch {
                print("Ошибка проверки транзакции: \(error)")
            }
        }
        
        purchasedProductIds = purchasedIds
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                } catch {
                    print("Ошибка транзакции: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw IAPError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    enum IAPError: Error {
        case failedVerification
    }
}
