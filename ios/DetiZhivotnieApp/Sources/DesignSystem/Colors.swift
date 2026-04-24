//
//  Colors.swift
//  DetiZhivotnieApp
//
//  Design tokens — generated from Figma (file: VcYnAfAMMhLuhxOyzTg162, node: 0:2137).
//  Do not edit by hand — if Figma tokens change, regenerate.
//
//  Naming follows Figma: DS.Color.<semantic>.<variant>
//  Primitive palettes: DS.Palette.<hue>.<shade>
//

import SwiftUI

public enum DS {}

// MARK: - Primitive palettes

public extension DS {
    enum Palette {
        // Neutrals (0 = white, 900 = black)
        public enum Neutral {
            public static let n0   = SwiftUI.Color(hex: 0xFFFFFF)
            public static let n50  = SwiftUI.Color(hex: 0xF2F2F7)
            public static let n100 = SwiftUI.Color(hex: 0xE5E5EA)
            public static let n200 = SwiftUI.Color(hex: 0xD1D1D6)
            public static let n300 = SwiftUI.Color(hex: 0xC7C7CC)
            public static let n400 = SwiftUI.Color(hex: 0xAEAEB2)
            public static let n500 = SwiftUI.Color(hex: 0x8E8E93)
            public static let n600 = SwiftUI.Color(hex: 0x65656B)
            public static let n700 = SwiftUI.Color(hex: 0x3C3C43)
            public static let n800 = SwiftUI.Color(hex: 0x1E1E21)
            public static let n900 = SwiftUI.Color(hex: 0x000000)
        }

        public enum Green {
            public static let c50  = SwiftUI.Color(hex: 0xF1F7ED)
            public static let c100 = SwiftUI.Color(hex: 0xE3F0DB)
            public static let c200 = SwiftUI.Color(hex: 0xC1E0B0)
            public static let c300 = SwiftUI.Color(hex: 0x9FD185)
            public static let c400 = SwiftUI.Color(hex: 0x7DC15A)
            public static let c500 = SwiftUI.Color(hex: 0x49832E)
            public static let c600 = SwiftUI.Color(hex: 0x3A6925)
            public static let c700 = SwiftUI.Color(hex: 0x2C4F1C)
            public static let c800 = SwiftUI.Color(hex: 0x1D3512)
            public static let c900 = SwiftUI.Color(hex: 0x0E1A09)
        }

        public enum Blue {
            public static let c50  = SwiftUI.Color(hex: 0xF2F8FF)
            public static let c100 = SwiftUI.Color(hex: 0xE6F2FF)
            public static let c200 = SwiftUI.Color(hex: 0xB3D7FF)
            public static let c300 = SwiftUI.Color(hex: 0x80BDFF)
            public static let c400 = SwiftUI.Color(hex: 0x4DA2FF)
            public static let c500 = SwiftUI.Color(hex: 0x007AFF)   // iOS system blue
            public static let c600 = SwiftUI.Color(hex: 0x0062CC)
            public static let c700 = SwiftUI.Color(hex: 0x004999)
            public static let c800 = SwiftUI.Color(hex: 0x003166)
            public static let c900 = SwiftUI.Color(hex: 0x001833)
        }

        public enum LightBlue {
            public static let c50  = SwiftUI.Color(hex: 0xF7FBFF)
            public static let c100 = SwiftUI.Color(hex: 0xEFF7FF)
            public static let c200 = SwiftUI.Color(hex: 0xD0E7FF)
            public static let c300 = SwiftUI.Color(hex: 0xB0D8FF)
            public static let c400 = SwiftUI.Color(hex: 0x90C8FF)
            public static let c500 = SwiftUI.Color(hex: 0x61B0FF)
            public static let c600 = SwiftUI.Color(hex: 0x4E8DCC)
            public static let c700 = SwiftUI.Color(hex: 0x3A6A99)
            public static let c800 = SwiftUI.Color(hex: 0x274666)
            public static let c900 = SwiftUI.Color(hex: 0x132333)
        }

        public enum Turquoise {
            public static let c50  = SwiftUI.Color(hex: 0xF6FCFB)
            public static let c100 = SwiftUI.Color(hex: 0xEDF8F7)
            public static let c200 = SwiftUI.Color(hex: 0xC9EAE8)
            public static let c300 = SwiftUI.Color(hex: 0xA5DCD9)
            public static let c400 = SwiftUI.Color(hex: 0x80CEC9)
            public static let c500 = SwiftUI.Color(hex: 0x4AB9B2)
            public static let c600 = SwiftUI.Color(hex: 0x3B948E)
            public static let c700 = SwiftUI.Color(hex: 0x2C6F6B)
            public static let c800 = SwiftUI.Color(hex: 0x1E4A47)
            public static let c900 = SwiftUI.Color(hex: 0x0F2524)
        }

        public enum Yellow {
            public static let c50  = SwiftUI.Color(hex: 0xFFFCF6)
            public static let c100 = SwiftUI.Color(hex: 0xFFFAED)
            public static let c200 = SwiftUI.Color(hex: 0xFFF0CA)
            public static let c300 = SwiftUI.Color(hex: 0xFFE6A6)
            public static let c400 = SwiftUI.Color(hex: 0xFEDB82)
            public static let c500 = SwiftUI.Color(hex: 0xFECC4D)
            public static let c600 = SwiftUI.Color(hex: 0xCBA33E)
            public static let c700 = SwiftUI.Color(hex: 0x987A2E)
            public static let c800 = SwiftUI.Color(hex: 0x66521F)
            public static let c900 = SwiftUI.Color(hex: 0x33290F)
        }

        public enum Orange {
            public static let c50  = SwiftUI.Color(hex: 0xFFFBF5)
            public static let c100 = SwiftUI.Color(hex: 0xFFF7EA)
            public static let c200 = SwiftUI.Color(hex: 0xFFE7C0)
            public static let c300 = SwiftUI.Color(hex: 0xFFD797)
            public static let c400 = SwiftUI.Color(hex: 0xFFC76D)
            public static let c500 = SwiftUI.Color(hex: 0xFFAF2E)
            public static let c600 = SwiftUI.Color(hex: 0xCC8C25)
            public static let c700 = SwiftUI.Color(hex: 0x99691C)
            public static let c800 = SwiftUI.Color(hex: 0x664612)
            public static let c900 = SwiftUI.Color(hex: 0x332309)
        }

        public enum Pink {
            public static let c50  = SwiftUI.Color(hex: 0xFFF7FB)
            public static let c100 = SwiftUI.Color(hex: 0xFFEFF8)
            public static let c200 = SwiftUI.Color(hex: 0xFFD0E9)
            public static let c300 = SwiftUI.Color(hex: 0xFFB0DA)
            public static let c400 = SwiftUI.Color(hex: 0xFF90CB)
            public static let c500 = SwiftUI.Color(hex: 0xFF61B5)
            public static let c600 = SwiftUI.Color(hex: 0xCC4E91)
            public static let c700 = SwiftUI.Color(hex: 0x993A6D)
            public static let c800 = SwiftUI.Color(hex: 0x662748)
            public static let c900 = SwiftUI.Color(hex: 0x331324)
        }
    }
}

// MARK: - Semantic tokens

public extension DS {
    enum Color {
        // Fill
        public enum Fill {
            public static let primary          = SwiftUI.Color(hex: 0xFFFFFF)
            public static let secondary        = SwiftUI.Color(hex: 0x65656B, alpha: 0.40)
            public static let tertiary         = SwiftUI.Color(hex: 0x65656B, alpha: 0.20)
            public static let quaternary       = SwiftUI.Color(hex: 0x65656B, alpha: 0.12)
            public static let accentPrimary    = SwiftUI.Color(hex: 0x007AFF)
            public static let accentSecondary  = SwiftUI.Color(hex: 0x007AFF, alpha: 0.20)
        }

        // Label (text)
        public enum Label {
            public static let primary    = SwiftUI.Color(hex: 0x000000)
            public static let secondary  = SwiftUI.Color(hex: 0x3C3C43, alpha: 0.60)
            public static let tertiary   = SwiftUI.Color(hex: 0x3C3C43, alpha: 0.30)
            public static let quaternary = SwiftUI.Color(hex: 0x3C3C43, alpha: 0.18)
            public static let accent     = SwiftUI.Color(hex: 0x007AFF)
            public static let error      = SwiftUI.Color(hex: 0xFF61B5)
        }

        // Icons
        public enum Icon {
            public static let primary    = SwiftUI.Color(hex: 0x000000)
            public static let secondary  = SwiftUI.Color(hex: 0x3C3C43, alpha: 0.60)
            public static let tertiary   = SwiftUI.Color(hex: 0x3C3C43, alpha: 0.30)
            public static let quaternary = SwiftUI.Color(hex: 0x3C3C43, alpha: 0.18)
            public static let accent     = SwiftUI.Color(hex: 0x007AFF)
        }

        // Buttons
        public enum Button {
            public static let primary         = SwiftUI.Color(hex: 0xFFFFFF)
            public static let secondary       = SwiftUI.Color(hex: 0x65656B, alpha: 0.40)
            public static let tertiary        = SwiftUI.Color(hex: 0x65656B, alpha: 0.20)
            public static let quaternary      = SwiftUI.Color(hex: 0x65656B, alpha: 0.12)
            public static let accent          = SwiftUI.Color(hex: 0x007AFF)
            public static let accentSecondary = SwiftUI.Color(hex: 0x007AFF, alpha: 0.20)
        }

        // Backgrounds
        public enum Background {
            public static let primary         = SwiftUI.Color(hex: 0xF2F2F7)
            public static let primaryGhost    = SwiftUI.Color(hex: 0xF2F2F7, alpha: 0.85)
            public static let primaryElevated = SwiftUI.Color(hex: 0xFFFFFF)
            public static let sales           = SwiftUI.Color(hex: 0xFF61B5)
        }

        // Outline
        public enum Outline {
            public static let accent = SwiftUI.Color(hex: 0x007AFF)
        }

        // Overlays
        public enum Overlay {
            public static let disabled       = SwiftUI.Color(hex: 0x000000, alpha: 0.40)
            public static let disabledLevel2 = SwiftUI.Color(hex: 0x000000, alpha: 0.72)
        }

        // Separator
        public static let separator = SwiftUI.Color(hex: 0x000000, alpha: 0.12)

        // Category-specific (used on category cards and tabs)
        public enum Category {
            public static let background      = SwiftUI.Color(hex: 0x61B0FF)
            public static let label           = SwiftUI.Color(hex: 0xFFFFFF)
            public static let tabBar          = SwiftUI.Color(hex: 0x4E8DCC)
            public static let tabBarOutline   = SwiftUI.Color(hex: 0x3A6A99)
            public static let icon            = SwiftUI.Color(hex: 0x4E8DCC)
            public static let presaleButtonBG = SwiftUI.Color(hex: 0x61B0FF)
            public static let presaleButtonBlur = SwiftUI.Color(hex: 0xB0D8FF)
        }
    }
}

// MARK: - Hex initializer
//
// Extending `SwiftUI.Color` explicitly — a bare `extension Color` would be
// ambiguous with our `DS.Color` enum in the same module and the compiler
// would try to extend `DS.Color` (which has no cases and fails).

extension SwiftUI.Color {
    /// Initialise from a 0xRRGGBB integer with optional alpha (0...1).
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self = SwiftUI.Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
