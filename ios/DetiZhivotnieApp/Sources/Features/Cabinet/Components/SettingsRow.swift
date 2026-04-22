//
//  SettingsRow.swift
//  DetiZhivotnieApp
//
//  Figma: Cabinet list rows (Settings + Additional sections).
//  Layout: [colored square icon 32pt] · title · [trailing content] · [chevron?]
//

import SwiftUI

struct SettingsRow<Trailing: View>: View {
    let iconSystemName: String
    let iconTint: Color
    let title: String
    @ViewBuilder let trailing: () -> Trailing
    var onTap: (() -> Void)?

    init(
        iconSystemName: String,
        iconTint: Color,
        title: String,
        onTap: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.iconSystemName = iconSystemName
        self.iconTint = iconTint
        self.title = title
        self.onTap = onTap
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: DS.Gap.gap300) {
            // Colored icon tile — rounded square with SF Symbol in white
            RoundedRectangle(cornerRadius: DS.Radius.xs)
                .fill(iconTint)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: iconSystemName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DS.Palette.Neutral.n0)
                )

            Text(title)
                .dsStyle(.body)
                .foregroundColor(DS.Color.Label.primary)

            Spacer(minLength: DS.Gap.gap200)

            trailing()
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .frame(height: 52)
        .padding(.horizontal, DS.Gap.gap400)
    }
}

// MARK: - Trailing helpers

extension SettingsRow where Trailing == ChevronTrailing {
    init(iconSystemName: String, iconTint: Color, title: String, onTap: (() -> Void)? = nil) {
        self.init(
            iconSystemName: iconSystemName,
            iconTint: iconTint,
            title: title,
            onTap: onTap,
            trailing: { ChevronTrailing() }
        )
    }
}

struct ChevronTrailing: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(DS.Color.Icon.accent)
    }
}

struct ValueChevronTrailing: View {
    let value: String
    var body: some View {
        HStack(spacing: DS.Gap.gap100) {
            Text(value)
                .dsStyle(.body)
                .foregroundColor(DS.Color.Label.secondary)
            ChevronTrailing()
        }
    }
}
