import SwiftUI

struct BottomCategoryBar: View {
    let categories: [Category]
    @Binding var selectedCategoryId: String?
    @StateObject private var assetService = AssetService()
    @StateObject private var iapService = IAPService()
    @EnvironmentObject var localizationService: LocalizationService
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories) { category in
                    CategoryTabButton(
                        category: category,
                        isSelected: selectedCategoryId == category.id,
                        isPurchased: iapService.purchasedProductIds.contains(category.iapProductId ?? ""),
                        onTap: {
                            if !category.isPaid || iapService.purchasedProductIds.contains(category.iapProductId ?? "") {
                                selectedCategoryId = category.id
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color.white.shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2))
    }
}

struct CategoryTabButton: View {
    let category: Category
    let isSelected: Bool
    let isPurchased: Bool
    let onTap: () -> Void
    @StateObject private var assetService = AssetService()
    @State private var iconImage: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let image = iconImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                } else {
                    ProgressView()
                        .frame(width: 50, height: 50)
                }
                
                if !isPurchased && category.isPaid {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.black)
                        .font(.system(size: 12))
                        .offset(x: 18, y: -18)
                }
            }
            .frame(width: 60, height: 60)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .task {
            await loadIcon()
        }
    }
    
    private func loadIcon() async {
        do {
            iconImage = try await assetService.loadImage(from: category.tabIconAssetPath)
        } catch {
            print("Ошибка загрузки иконки: \(error)")
        }
    }
}
