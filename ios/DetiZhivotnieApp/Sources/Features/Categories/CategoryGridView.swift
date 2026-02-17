import SwiftUI

struct CategoryGridView: View {
    let categoryId: String
    @StateObject private var contentService = ContentService()
    @StateObject private var assetService = AssetService()
    @StateObject private var iapService = IAPService()
    @EnvironmentObject var localizationService: LocalizationService
    @State private var animals: [Animal] = []
    @State private var category: Category?
    @State private var showPurchaseView = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(animals) { animal in
                    NavigationLink(destination: AnimalDetailView(animal: animal, categoryId: categoryId)) {
                        AnimalCard(animal: animal)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(category.map { localizationService.localized($0.title) } ?? "")
        .task {
            await loadData()
            await AnalyticsService().logEvent(eventType: "category_open", categoryId: categoryId)
        }
    }
    
    private func loadData() async {
        // Загружаем категорию
        if let cat = contentService.categories.first(where: { $0.id == categoryId }) {
            category = cat
        }
        
        // Загружаем животных
        try? await contentService.loadAnimals(for: categoryId)
        animals = contentService.animals[categoryId] ?? []
    }
}

struct AnimalCard: View {
    let animal: Animal
    @StateObject private var assetService = AssetService()
    @State private var previewImage: UIImage?
    @EnvironmentObject var localizationService: LocalizationService
    
    var body: some View {
        VStack {
            if let image = previewImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
            } else {
                ProgressView()
                    .frame(height: 120)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#F5E6D3"))
        .cornerRadius(20)
        .task {
            await loadPreview()
        }
    }
    
    private func loadPreview() async {
        do {
            previewImage = try await assetService.loadImage(from: animal.previewAssetPath)
        } catch {
            print("Ошибка загрузки превью: \(error)")
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
