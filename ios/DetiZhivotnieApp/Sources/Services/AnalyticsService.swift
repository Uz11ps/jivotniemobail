import Foundation
import FirebaseCore
import FirebaseFunctions

class AnalyticsService: ObservableObject {
    // Lazy — resolves only after Firebase has been configured.
    private var functions: Functions? {
        guard FirebaseApp.app() != nil else { return nil }
        return Functions.functions()
    }

    func logEvent(
        eventType: String,
        categoryId: String? = nil,
        animalId: String? = nil,
        productId: String? = nil
    ) async {
        guard let functions else { return }   // No Firebase → no-op analytics.

        let data: [String: Any] = [
            "eventType": eventType,
            "categoryId": categoryId as Any,
            "animalId": animalId as Any,
            "productId": productId as Any,
            "timestamp": Date().timeIntervalSince1970
        ]

        do {
            let logFunction = functions.httpsCallable("logAnalyticsEvent")
            _ = try await logFunction.call(data)
        } catch {
            print("Ошибка логирования аналитики: \(error)")
        }
    }
}
