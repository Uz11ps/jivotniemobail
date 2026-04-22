//
//  PresaleButton.swift
//  DetiZhivotnieApp
//
//  Figma: `1:6770` (Presale button, Main screen overlay at y=630, h=60).
//  A floating pill CTA shown just above the tab bar when the user is viewing
//  a locked category. Label: "Unlock <price>". Tint uses the per-category
//  theme's presale colors.
//

import SwiftUI

struct PresaleButton: View {
    let priceText: String
    let theme: CategoryTheme
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("Unlock \(priceText)")
                    .dsStyle(.bodySemi)
            }
            .foregroundColor(DS.Palette.Neutral.n0)
            .padding(.horizontal, DS.Gap.gap500)
            .frame(height: 50)
            .background(
                Capsule()
                    .fill(theme.presaleBG)
                    .background(
                        Capsule()
                            .fill(theme.presaleBlur.opacity(0.3))
                            .blur(radius: 12)
                            .scaleEffect(1.1)
                    )
            )
            .overlay(
                Capsule()
                    .stroke(theme.tabBarOutline.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: theme.tabBarOutline.opacity(0.35), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}
