//
//  CategoryTheme.swift
//  DetiZhivotnieApp
//
//  Per-category color palette. Source: Figma tokens
//  `Category/Background`, `Category/Label`, `Category/Tab bar`, …
//
//  In Figma only the Pets theme is exposed as category-scoped variables.
//  Other categories use hue-shifted palettes (Green/Yellow/Orange/Pink/Turquoise).
//  We map category.id → palette here; unknown categories fall back to Pets.
//

import SwiftUI

struct CategoryTheme {
    let background: Color          // Hero + page background base
    let backgroundLight: Color     // Top of gradient (lighter)
    let tileBackground: Color      // Animal tile bg (slightly lighter than bg)
    let tileBackgroundLocked: Color // Locked tile bg (more transparent)
    let label: Color               // Headline title / animal name
    let tabBar: Color              // Tab bar pill fill
    let tabBarOutline: Color       // Tab bar outline stroke
    let icon: Color                // Default (locked) tab icon tint
    let presaleBG: Color           // "Presale" CTA background
    let presaleBlur: Color         // CTA blur/shadow wash

    static let pets = CategoryTheme(
        background:          DS.Palette.LightBlue.c500,  // #61B0FF
        backgroundLight:     DS.Palette.LightBlue.c400,  // #90C8FF
        tileBackground:      DS.Palette.LightBlue.c400,  // #90C8FF
        tileBackgroundLocked: Color(hex: 0x90C8FF, alpha: 0.55),
        label:               DS.Palette.Neutral.n0,       // white
        tabBar:              DS.Palette.LightBlue.c600,   // #4E8DCC
        tabBarOutline:       DS.Palette.LightBlue.c700,   // #3A6A99
        icon:                DS.Palette.LightBlue.c600,
        presaleBG:           DS.Palette.LightBlue.c500,
        presaleBlur:         DS.Palette.LightBlue.c300
    )

    // Farm / Barn — yellow/orange ochre theme (educated guess until Figma confirms)
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

    // Forest
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

    // Sea / Island
    static let sea = CategoryTheme(
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

    // Pink / special
    static let pink = CategoryTheme(
        background:          DS.Palette.Pink.c500,
        backgroundLight:     DS.Palette.Pink.c400,
        tileBackground:      DS.Palette.Pink.c400,
        tileBackgroundLocked: Color(hex: 0xFF90CB, alpha: 0.55),
        label:               DS.Palette.Neutral.n0,
        tabBar:              DS.Palette.Pink.c600,
        tabBarOutline:       DS.Palette.Pink.c700,
        icon:                DS.Palette.Pink.c600,
        presaleBG:           DS.Palette.Pink.c500,
        presaleBlur:         DS.Palette.Pink.c300
    )

    /// Map a category.id (or fallback on order) to a theme.
    static func theme(for categoryId: String) -> CategoryTheme {
        switch categoryId {
        case "pets":                    return .pets
        case "farm", "barn":            return .farm
        case "forest", "wild":          return .forest
        case "sea", "ocean", "island":  return .sea
        case "dream", "fantasy":        return .pink
        default:                        return .pets
        }
    }
}
