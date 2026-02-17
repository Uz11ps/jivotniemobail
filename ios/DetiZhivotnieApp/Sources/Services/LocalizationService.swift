import Foundation

class LocalizationService: ObservableObject {
    @Published var currentLanguage: Language = .ru
    
    enum Language: String, CaseIterable {
        case ru = "ru"
        case en = "en"
        
        var displayName: String {
            switch self {
            case .ru: return "Русский"
            case .en: return "English"
            }
        }
    }
    
    func localized(_ string: Category.LocalizedString) -> String {
        switch currentLanguage {
        case .ru: return string.ru
        case .en: return string.en
        }
    }
    
    func localized(_ string: Animal.LocalizedString) -> String {
        switch currentLanguage {
        case .ru: return string.ru
        case .en: return string.en
        }
    }
}
