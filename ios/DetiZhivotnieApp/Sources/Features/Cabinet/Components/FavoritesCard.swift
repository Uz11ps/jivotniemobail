//
//  FavoritesCard.swift
//  DetiZhivotnieApp
//
//  Figma: "Favorite categories" and "Top 10 favorite animals" cards.
//  White rounded card with a bold title and a horizontally scrolling row of
//  items. Each item: icon / photo + name + usage percentage in accent blue.
//

import SwiftUI

struct FavoritesCard<ItemIcon: View>: View {
    let title: String
    let items: [FavoriteItem]
    @ViewBuilder let iconFor: (FavoriteItem) -> ItemIcon

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Gap.gap300) {
            Text(title)
                .dsStyle(.headlineSemi)
                .foregroundColor(DS.Color.Label.primary)
                .padding(.horizontal, DS.Gap.gap400)
                .padding(.top, DS.Gap.gap400)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: DS.Gap.gap500) {
                    ForEach(items) { item in
                        VStack(spacing: DS.Gap.gap200) {
                            iconFor(item)
                                .frame(width: 44, height: 44)
                            Text(item.title)
                                .dsStyle(.footnote)
                                .foregroundColor(DS.Color.Label.primary)
                            Text("\(item.percent)%")
                                .dsStyle(.footnoteSemi)
                                .foregroundColor(DS.Color.Label.accent)
                        }
                        .frame(width: 60)
                    }
                }
                .padding(.horizontal, DS.Gap.gap400)
                .padding(.bottom, DS.Gap.gap400)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.l)
                .fill(DS.Color.Background.primaryElevated)
        )
    }
}

struct FavoriteItem: Identifiable {
    let id: String
    let title: String
    let percent: Int
    /// Optional asset path (Firebase Storage); when nil, the iconFor closure
    /// is expected to render a fallback (e.g. a tinted SF Symbol).
    let assetPath: String?
    /// Optional tint colour for SF-symbol fallbacks (category theme).
    let tint: Color
}
