//
//  AnimalTile.swift
//  DetiZhivotnieApp
//
//  Figma: Animal board cells — rounded squares with a light tinted background
//  and an animal photo. Replaces legacy `AnimalCard` (2-col grid) with the
//  4-col board layout.
//

import SwiftUI

struct AnimalTile: View {
    let animal: Animal
    let theme: CategoryTheme
    var isLocked: Bool = false

    @StateObject private var assetService = AssetService()
    @State private var previewImage: UIImage?
    @State private var hasAttemptedLoad = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.Radius.l)
                .fill(isLocked ? theme.tileBackgroundLocked : theme.tileBackground)

            if let image = previewImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(4)
            } else if hasAttemptedLoad || animal.previewAssetPath.isEmpty {
                // Fallback once we know we won't get a remote image.
                Image(systemName: animalFallbackSymbol)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white, theme.label.opacity(0.3))
                    .symbolRenderingMode(.hierarchical)
            } else {
                ProgressView()
                    .tint(theme.label.opacity(0.8))
            }

            if isLocked {
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
        defer { hasAttemptedLoad = true }
        guard !animal.previewAssetPath.isEmpty else { return }
        previewImage = try? await assetService.loadImage(from: animal.previewAssetPath)
    }

    // MARK: - SF Symbol mapping for demo content
    private var animalFallbackSymbol: String {
        switch animal.id {
        // Pets
        case "cat":           return "cat.fill"
        case "dog":           return "dog.fill"
        case "rabbit":        return "hare.fill"
        case "frog", "turtle":return "tortoise.fill"
        case "hamster", "mouse", "chinchilla", "guineapig":
                              return "mouse.fill"
        case "snail":         return "ant.fill"
        case "ferret":        return "pawprint.fill"
        case "parrot":        return "bird.fill"
        // Farm
        case "cow", "sheep", "pig", "goat", "horse":
                              return "pawprint.fill"
        case "chicken", "rooster", "duck":
                              return "bird.fill"
        // Forest
        case "bear":          return "pawprint.fill"
        case "wolf", "fox":   return "dog.fill"
        case "owl", "woodpecker": return "bird.fill"
        case "squirrel":      return "hare.fill"
        case "hedgehog":      return "ant.fill"
        case "deer":          return "pawprint.fill"
        // Sea
        case "dolphin", "whale", "shark", "fish":
                              return "fish.fill"
        case "octopus", "seahorse", "jellyfish":
                              return "fish.fill"
        case "crab":          return "ant.fill"
        // Dream
        case "unicorn", "pegasus": return "sparkles"
        case "dragon", "phoenix":  return "flame.fill"
        default:              return "pawprint.fill"
        }
    }
}
