//
//  CategoryTheme.swift
//  DetiZhivotnieApp
//
//  Per-category color palette matching Figma section "1.1 Categories content"
//  (node 1:8009). Six categories in this exact order:
//      Pets · Farm · Forest · Savannah · Pond · Jungle
//
//  Token colours taken from the Figma Tokens page (0:2137) — see
//  `Sources/DesignSystem/Colors.swift`.
//

import SwiftUI

struct CategoryTheme {
    let background: Color          // Page background base
    let backgroundLight: Color     // Top of gradient (lighter)
    let tileBackground: Color      // Animal tile bg (slightly lighter)
    let tileBackgroundLocked: Color
    let label: Color               // Headline title / animal name
    let tabBar: Color              // Tab bar pill fill
    let tabBarOutline: Color       // Tab bar outline stroke
    let icon: Color                // Default (locked) tab icon tint
    let presaleBG: Color
    let presaleBlur: Color

    // MARK: - Pets — light blue (Figma Category tokens)
    static let pets = CategoryTheme(
        background:          DS.Palette.LightBlue.c500,
        backgroundLight:     DS.Palette.LightBlue.c400,
        tileBackground:      DS.Palette.LightBlue.c400,
        tileBackgroundLocked: Color(hex: 0x90C8FF, alpha: 0.55),
        label:               DS.Palette.Neutral.n0,
        tabBar:              DS.Palette.LightBlue.c600,
        tabBarOutline:       DS.Palette.LightBlue.c700,
        icon:                DS.Palette.LightBlue.c600,
        presaleBG:           DS.Palette.LightBlue.c500,
        presaleBlur:         DS.Palette.LightBlue.c300
    )

    // MARK: - Farm — warm orange
    static let farm = CategoryTheme(
        background:          DS.Palette.Orange.c500,
        backgroundLight:     DS.Palette.Orange.c400,
        tileBackground:      DS.Palette.Orange.c400,
        tileBackgroundLocked: Color(hex: 0xFFC76D, alpha: 0.55),
        label:               DS.Palette.Neutral.n0,
        tabBar:              DS.Palette.Orange.c600,
        tabBarOutline:       DS.Palette.Orange.c700,
        icon:                DS.Palette.Orange.c600,
        presaleBG:           DS.Palette.Orange.c500,
        presaleBlur:         DS.Palette.Orange.c300
    )

    // MARK: - Forest — mid green
    static let forest = CategoryTheme(
        background:          DS.Palette.Green.c500,
        backgroundLight:     DS.Palette.Green.c400,
        tileBackground:      DS.Palette.Green.c400,
        tileBackgroundLocked: Color(hex: 0x7DC15A, alpha: 0.55),
        label:               DS.Palette.Neutral.n0,
        tabBar:              DS.Palette.Green.c600,
        tabBarOutline:       DS.Palette.Green.c700,
        icon:                DS.Palette.Green.c600,
        presaleBG:           DS.Palette.Green.c500,
        presaleBlur:         DS.Palette.Green.c300
    )

    // MARK: - Savannah — warm yellow ochre
    static let savannah = CategoryTheme(
        background:          DS.Palette.Yellow.c500,
        backgroundLight:     DS.Palette.Yellow.c400,
        tileBackground:      DS.Palette.Yellow.c400,
        tileBackgroundLocked: Color(hex: 0xFFE6A6, alpha: 0.55),
        label:               DS.Palette.Neutral.n0,
        tabBar:              DS.Palette.Yellow.c600,
        tabBarOutline:       DS.Palette.Yellow.c700,
        icon:                DS.Palette.Yellow.c600,
        presaleBG:           DS.Palette.Yellow.c500,
        presaleBlur:         DS.Palette.Yellow.c300
    )

    // MARK: - Pond — cool turquoise
    static let pond = CategoryTheme(
        background:          DS.Palette.Turquoise.c500,
        backgroundLight:     DS.Palette.Turquoise.c400,
        tileBackground:      DS.Palette.Turquoise.c400,
        tileBackgroundLocked: Color(hex: 0x80CEC9, alpha: 0.55),
        label:               DS.Palette.Neutral.n0,
        tabBar:              DS.Palette.Turquoise.c600,
        tabBarOutline:       DS.Palette.Turquoise.c700,
        icon:                DS.Palette.Turquoise.c600,
        presaleBG:           DS.Palette.Turquoise.c500,
        presaleBlur:         DS.Palette.Turquoise.c300
    )

    // MARK: - Jungle — deeper green, distinct from Forest
    static let jungle = CategoryTheme(
        background:          DS.Palette.Green.c600,
        backgroundLight:     DS.Palette.Green.c500,
        tileBackground:      DS.Palette.Green.c500,
        tileBackgroundLocked: Color(hex: 0x49832E, alpha: 0.55),
        label:               DS.Palette.Neutral.n0,
        tabBar:              DS.Palette.Green.c700,
        tabBarOutline:       DS.Palette.Green.c800,
        icon:                DS.Palette.Green.c700,
        presaleBG:           DS.Palette.Green.c600,
        presaleBlur:         DS.Palette.Green.c400
    )

    /// Map a category.id to its theme. Unknown ids fall back to Pets.
    static func theme(for categoryId: String) -> CategoryTheme {
        switch categoryId {
        case "pets":     return .pets
        case "farm":     return .farm
        case "forest":   return .forest
        case "savannah": return .savannah
        case "pond":     return .pond
        case "jungle":   return .jungle
        default:         return .pets
        }
    }
}
