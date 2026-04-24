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
            // Figma: corners/xxl = 28pt, fill/secondary translucent neutral.
            RoundedRectangle(cornerRadius: DS.Radius.xxl)
                .fill(isLocked ? theme.tileBackgroundLocked : theme.tileBackground)

            // Figma: animal picture inset 10% top/bottom from the tile edges.
            GeometryReader { geo in
                Group {
                    if let image = previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if UIImage(named: animal.previewAssetPath) != nil {
                        Image(animal.previewAssetPath)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if hasAttemptedLoad || animal.previewAssetPath.isEmpty {
                        Image(systemName: animalFallbackSymbol)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white, theme.label.opacity(0.3))
                            .symbolRenderingMode(.hierarchical)
                    } else {
                        ProgressView()
                            .tint(theme.label.opacity(0.8))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height * 0.8)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
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
        // Bundled asset takes precedence — don't hit Firebase.
        guard !animal.previewAssetPath.isEmpty,
              UIImage(named: animal.previewAssetPath) == nil,
              animal.previewAssetPath.hasPrefix("gs://")
                || animal.previewAssetPath.hasPrefix("https://")
        else { return }
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
