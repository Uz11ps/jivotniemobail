import SwiftUI

struct MainTabView: View {
    @StateObject private var contentService = ContentService()
    @StateObject private var localizationService = LocalizationService()
    @State private var selectedCategoryId: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                if let categoryId = selectedCategoryId {
                    CategoryGridView(categoryId: categoryId)
                } else if let firstCategory = contentService.categories.first {
                    CategoryGridView(categoryId: firstCategory.id)
                } else {
                    ProgressView()
                }
                
                VStack {
                    Spacer()
                    BottomCategoryBar(
                        categories: contentService.categories,
                        selectedCategoryId: $selectedCategoryId
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .task {
                try? await contentService.loadCategories()
                if selectedCategoryId == nil, let first = contentService.categories.first {
                    selectedCategoryId = first.id
                }
            }
        }
        .environmentObject(localizationService)
    }
}
