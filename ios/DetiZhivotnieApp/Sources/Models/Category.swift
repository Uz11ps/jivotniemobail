import Foundation

struct Category: Identifiable, Codable {
    var id: String
    var order: Int
    var isVisible: Bool
    var isPaid: Bool
    var iapProductId: String?
    var title: LocalizedString
    var tabIconAssetPath: String
    var gridCardStyle: GridCardStyle?
    
    struct LocalizedString: Codable {
        var ru: String
        var en: String
    }
    
    struct GridCardStyle: Codable {
        var backgroundColor: String?
        var cornerRadius: Double?
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case order
        case isVisible
        case isPaid
        case iapProductId
        case title
        case tabIconAssetPath
        case gridCardStyle
    }
    
    init(id: String, order: Int, isVisible: Bool, isPaid: Bool, iapProductId: String?, title: LocalizedString, tabIconAssetPath: String, gridCardStyle: GridCardStyle?) {
        self.id = id
        self.order = order
        self.isVisible = isVisible
        self.isPaid = isPaid
        self.iapProductId = iapProductId
        self.title = title
        self.tabIconAssetPath = tabIconAssetPath
        self.gridCardStyle = gridCardStyle
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        order = try container.decode(Int.self, forKey: .order)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        isPaid = try container.decode(Bool.self, forKey: .isPaid)
        iapProductId = try container.decodeIfPresent(String.self, forKey: .iapProductId)
        title = try container.decode(LocalizedString.self, forKey: .title)
        tabIconAssetPath = try container.decode(String.self, forKey: .tabIconAssetPath)
        gridCardStyle = try container.decodeIfPresent(GridCardStyle.self, forKey: .gridCardStyle)
    }
}
