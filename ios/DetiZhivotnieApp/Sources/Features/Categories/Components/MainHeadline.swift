//
//  MainHeadline.swift
//  DetiZhivotnieApp
//
//  Figma: `1:6653` — Main Headline (h = 64 from y=59 to y=123).
//  Layout: [home icon] [category title, centered] [profile circle, right].
//

import SwiftUI

struct MainHeadline: View {
    let title: String
    let theme: CategoryTheme
    var onProfileTap: () -> Void = {}

    var body: some View {
        ZStack {
            // Centered: icon + title
            HStack(spacing: DS.Gap.gap200) {
                Image(systemName: "house.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(theme.label)
                Text(title)
                    .dsStyle(.title2Bold)
                    .foregroundColor(theme.label)
            }

            // Trailing profile button
            HStack {
                Spacer()
                Button(action: onProfileTap) {
                    Circle()
                        .fill(DS.Palette.Neutral.n0)
                        .frame(width: DS.IconSize.xl, height: DS.IconSize.xl)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(theme.tabBar)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, DS.Gap.gap400)
        }
        .frame(height: 64)
        .padding(.horizontal, DS.Gap.gap400)
    }
}

#Preview {
    ZStack {
        CategoryTheme.pets.background.ignoresSafeArea()
        VStack {
            MainHeadline(title: "Pets", theme: .pets)
            Spacer()
        }
    }
}
