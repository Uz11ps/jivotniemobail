//
//  CategoryHero.swift
//  DetiZhivotnieApp
//
//  Figma: `1:6655` — Category Video (h = 219 at y=123..342).
//  Large illustration/video of the currently selected category.
//  Falls back to a soft placeholder while the asset loads.
//

import SwiftUI
import AVKit

struct CategoryHero: View {
    let imagePath: String?     // Still image (Firebase Storage path)
    let videoPath: String?     // Optional looping video
    let theme: CategoryTheme

    @StateObject private var assetService = AssetService()
    @State private var heroImage: UIImage?

    var body: some View {
        ZStack {
            // Soft vignette wash so the hero blends with page bg
            LinearGradient(
                colors: [theme.backgroundLight.opacity(0.0), theme.background.opacity(0.25)],
                startPoint: .top, endPoint: .bottom
            )

            if let image = heroImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 219)
            } else {
                // Placeholder — subtle shape
                RoundedRectangle(cornerRadius: DS.Radius.xxl)
                    .fill(theme.backgroundLight.opacity(0.3))
                    .padding(.horizontal, DS.Gap.gap800)
                    .overlay(ProgressView().tint(theme.label))
            }
        }
        .frame(height: 219)
        .task {
            await loadHero()
        }
    }

    private func loadHero() async {
        guard let path = imagePath else { return }
        do {
            heroImage = try await assetService.loadImage(from: path)
        } catch {
            // Keep placeholder
        }
    }
}

#Preview {
    ZStack {
        CategoryTheme.pets.background.ignoresSafeArea()
        VStack {
            CategoryHero(imagePath: nil, videoPath: nil, theme: .pets)
            Spacer()
        }
    }
}
