//
//  TelegramCTAButton.swift
//  DetiZhivotnieApp
//
//  Figma: "Write to us in Telegram" CTA button at the bottom of Parent Cabinet.
//  Turquoise-tinted pill with a message bubble icon and centred label.
//

import SwiftUI

struct TelegramCTAButton: View {
    var title: String = "Write to us in Telegram"
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DS.Gap.gap200) {
                Image(systemName: "message.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .dsStyle(.bodySemi)
            }
            .foregroundColor(DS.Color.Label.accent)
            .padding(.horizontal, DS.Gap.gap500)
            .frame(height: 50)
            .background(
                Capsule()
                    .fill(DS.Palette.Turquoise.c200)
            )
        }
        .buttonStyle(.plain)
    }
}
