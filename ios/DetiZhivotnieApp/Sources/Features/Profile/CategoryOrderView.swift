import SwiftUI

struct CategoryOrderView: View {
    @StateObject private var contentService = ContentService()
    @StateObject private var iapService = IAPService()
    @EnvironmentObject var localizationService: LocalizationService
    @State private var categories: [Category] = []
    
    var body: some View {
        List {
            ForEach(categories) { category in
                HStack {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.gray)
                    
                    Text(localizationService.localized(category.title))
                    
                    Spacer()
                    
                    if category.isPaid && !iapService.purchasedProductIds.contains(category.iapProductId ?? "") {
                        HStack {
                            Text("59 ₽")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                            
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .onMove(perform: move)
        }
        .navigationTitle("Порядок")
        .toolbar {
            EditButton()
        }
        .task {
            await loadCategories()
        }
    }
    
    private func loadCategories() async {
        try? await contentService.loadCategories()
        categories = contentService.categories.filter { 
            !$0.isPaid || iapService.purchasedProductIds.contains($0.iapProductId ?? "")
        }
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        // Сохранить порядок локально
    }
}
