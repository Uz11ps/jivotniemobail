import Foundation

struct Offer: Identifiable, Codable {
    var id: String
    var isActive: Bool
    var title: LocalizedString
    var heroAssets: [String]
    var items: [OfferItem]
    var primaryProductId: String
    
    struct LocalizedString: Codable {
        var ru: String
        var en: String
    }
    
    struct OfferItem: Codable {
        var label: LocalizedString
        var productId: String
        var badge: LocalizedString?
    }
}
