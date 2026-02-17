import Foundation
import FirebaseFunctions

class AnalyticsService {
    private let functions = Functions.functions()
    
    func logEvent(
        eventType: String,
        categoryId: String? = nil,
        animalId: String? = nil,
        productId: String? = nil
    ) async {
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
