import Foundation

struct Animal: Identifiable, Codable {
    var id: String
    var order: Int
    var isVisible: Bool
    var name: LocalizedString
    var bgAssetPath: String
    var previewAssetPath: String
    var voiceAssetPath: VoiceAssets?
    var soundAssetPath: String
    var animationAssetPath: String?
    var animationVideoAssetPath: String?
    
    struct LocalizedString: Codable {
        var ru: String
        var en: String
    }
    
    struct VoiceAssets: Codable {
        var ru: String?
        var en: String?
    }
}
