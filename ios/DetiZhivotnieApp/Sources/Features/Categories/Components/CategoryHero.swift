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
    @State private var hasAttemptedLoad = false

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
            } else if hasAttemptedLoad || (imagePath?.isEmpty ?? true) {
                // Playful SF Symbol placeholder sized for the 219pt hero slot.
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 110, weight: .regular))
                    .foregroundStyle(.white, theme.label.opacity(0.3))
                    .symbolRenderingMode(.hierarchical)
                    .shadow(color: theme.tabBarOutline.opacity(0.2), radius: 10, y: 4)
            } else {
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
        defer { hasAttemptedLoad = true }
        guard let path = imagePath, !path.isEmpty else { return }
        heroImage = try? await assetService.loadImage(from: path)
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
