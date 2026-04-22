//
//  AnimalTile.swift
//  DetiZhivotnieApp
//
//  Figma: Animal board cells — rounded squares with a light tinted background
//  and an animal photo that overflows the bottom slightly for a playful look.
//  Replaces legacy `AnimalCard` (2-col grid) with the 4-col board layout.
//

import SwiftUI

struct AnimalTile: View {
    let animal: Animal
    let theme: CategoryTheme
    var isLocked: Bool = false

    @StateObject private var assetService = AssetService()
    @State private var previewImage: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.Radius.l)
                .fill(isLocked ? theme.tileBackgroundLocked : theme.tileBackground)

            if let image = previewImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(4)
            } else {
                ProgressView()
                    .tint(theme.label.opacity(0.8))
            }

            if isLocked {
                // Subtle lock badge in corner
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(theme.label)
                            .padding(6)
                            .background(Circle().fill(theme.tabBar))
                            .padding(4)
                    }
                    Spacer()
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .task {
            await loadPreview()
        }
    }

    private func loadPreview() async {
        do {
            previewImage = try await assetService.loadImage(from: animal.previewAssetPath)
        } catch {
            // Keep placeholder
        }
    }
}
