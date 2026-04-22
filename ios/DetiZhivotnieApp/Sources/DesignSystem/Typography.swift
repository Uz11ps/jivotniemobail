//
//  Typography.swift
//  DetiZhivotnieApp
//
//  Typography tokens — generated from Figma (file: VcYnAfAMMhLuhxOyzTg162).
//  All styles use the iOS-native "SF Pro Rounded" via .fontDesign(.rounded) —
//  no TTF bundling required.
//
//  Usage:
//      Text("Hello").dsStyle(.title1Bold)
//
//  Or manually:
//      Text("Hello")
//          .font(DS.Font.title1Bold.font)
//          .tracking(DS.Font.title1Bold.tracking)
//          .lineSpacing(DS.Font.title1Bold.lineSpacing)
//

import SwiftUI

public extension DS {
    enum Font {
        // MARK: - Style definition
        public struct Style {
            public let name: Name
            public let weight: SwiftUI.Font.Weight
            public let size: CGFloat
            public let lineHeight: CGFloat
            public let tracking: CGFloat

            /// Native iOS system font with `.rounded` design — renders as SF Pro Rounded.
            public var font: SwiftUI.Font {
                SwiftUI.Font.system(size: size, weight: weight, design: .rounded)
            }

            /// SwiftUI's lineSpacing is ADDED to the font's natural line height, so we compute the delta.
            public var lineSpacing: CGFloat {
                max(0, lineHeight - size)
            }
        }

        public enum Name: String, CaseIterable {
            case padTitle, largeTitle, largeTitleBold
            case title1, title1Bold, title2, title2Bold, title3, title3Semi
            case headlineSemi
            case body, bodySemi, callout, calloutSemi, subheadline, subheadlineSemi
            case footnote, footnoteSemi, caption1, caption1Medium, caption2, caption2Medium
        }

        // MARK: - Large Title
        public static let padTitle        = Style(name: .padTitle,       weight: .bold,     size: 64, lineHeight: 68, tracking: 0.68)
        public static let largeTitle      = Style(name: .largeTitle,     weight: .regular,  size: 34, lineHeight: 41, tracking: 0.40)
        public static let largeTitleBold  = Style(name: .largeTitleBold, weight: .bold,     size: 34, lineHeight: 41, tracking: 0.40)

        // MARK: - Titles
        public static let title1          = Style(name: .title1,         weight: .regular,  size: 28, lineHeight: 34, tracking: 0.38)
        public static let title1Bold      = Style(name: .title1Bold,     weight: .bold,     size: 28, lineHeight: 34, tracking: 0.38)
        public static let title2          = Style(name: .title2,         weight: .regular,  size: 22, lineHeight: 28, tracking: -0.26)
        public static let title2Bold      = Style(name: .title2Bold,     weight: .bold,     size: 22, lineHeight: 28, tracking: -0.26)
        public static let title3          = Style(name: .title3,         weight: .regular,  size: 20, lineHeight: 25, tracking: -0.45)
        public static let title3Semi      = Style(name: .title3Semi,     weight: .semibold, size: 20, lineHeight: 25, tracking: -0.45)

        // MARK: - Headline
        public static let headlineSemi    = Style(name: .headlineSemi,   weight: .semibold, size: 17, lineHeight: 22, tracking: -0.43)

        // MARK: - Body & Subheadlines
        public static let body            = Style(name: .body,           weight: .regular,  size: 17, lineHeight: 22, tracking: -0.43)
        public static let bodySemi        = Style(name: .bodySemi,       weight: .semibold, size: 17, lineHeight: 22, tracking: -0.43)
        public static let callout         = Style(name: .callout,        weight: .regular,  size: 16, lineHeight: 21, tracking: -0.31)
        public static let calloutSemi     = Style(name: .calloutSemi,    weight: .semibold, size: 16, lineHeight: 21, tracking: -0.31)
        public static let subheadline     = Style(name: .subheadline,    weight: .regular,  size: 15, lineHeight: 20, tracking: -0.23)
        public static let subheadlineSemi = Style(name: .subheadlineSemi,weight: .semibold, size: 15, lineHeight: 20, tracking: -0.23)

        // MARK: - Footnote & Caption
        public static let footnote        = Style(name: .footnote,       weight: .regular,  size: 13, lineHeight: 18, tracking: -0.08)
        public static let footnoteSemi    = Style(name: .footnoteSemi,   weight: .semibold, size: 13, lineHeight: 18, tracking: -0.08)
        public static let caption1        = Style(name: .caption1,       weight: .regular,  size: 12, lineHeight: 16, tracking: 0)
        public static let caption1Medium  = Style(name: .caption1Medium, weight: .medium,   size: 12, lineHeight: 16, tracking: 0)
        public static let caption2        = Style(name: .caption2,       weight: .regular,  size: 11, lineHeight: 13, tracking: 0.06)
        public static let caption2Medium  = Style(name: .caption2Medium, weight: .medium,   size: 11, lineHeight: 13, tracking: 0.06)

        // MARK: - Registry for helper modifier
        static func style(_ name: Name) -> Style {
            switch name {
            case .padTitle:        return padTitle
            case .largeTitle:      return largeTitle
            case .largeTitleBold:  return largeTitleBold
            case .title1:          return title1
            case .title1Bold:      return title1Bold
            case .title2:          return title2
            case .title2Bold:      return title2Bold
            case .title3:          return title3
            case .title3Semi:      return title3Semi
            case .headlineSemi:    return headlineSemi
            case .body:            return body
            case .bodySemi:        return bodySemi
            case .callout:         return callout
            case .calloutSemi:     return calloutSemi
            case .subheadline:     return subheadline
            case .subheadlineSemi: return subheadlineSemi
            case .footnote:        return footnote
            case .footnoteSemi:    return footnoteSemi
            case .caption1:        return caption1
            case .caption1Medium:  return caption1Medium
            case .caption2:        return caption2
            case .caption2Medium:  return caption2Medium
            }
        }
    }
}

// MARK: - Convenience modifier

public extension View {
    /// Apply a Figma text style in one call: font + tracking + line height.
    func dsStyle(_ name: DS.Font.Name) -> some View {
        let s = DS.Font.style(name)
        return self
            .font(s.font)
            .tracking(s.tracking)
            .lineSpacing(s.lineSpacing)
    }
}
