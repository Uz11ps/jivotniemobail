//
//  Spacing.swift
//  DetiZhivotnieApp
//
//  Gap tokens — generated from Figma (file: VcYnAfAMMhLuhxOyzTg162).
//  Use these instead of magic numbers for padding, VStack/HStack spacing, etc.
//
//  Usage:
//      VStack(spacing: DS.Gap.gap400) { ... }
//      .padding(.horizontal, DS.Gap.gap500)
//

import CoreGraphics

public extension DS {
    enum Gap {
        public static let gap050: CGFloat = 2
        public static let gap100: CGFloat = 4
        public static let gap200: CGFloat = 8
        public static let gap300: CGFloat = 12
        public static let gap400: CGFloat = 16
        public static let gap500: CGFloat = 20
        public static let gap600: CGFloat = 24
        public static let gap700: CGFloat = 28
        public static let gap800: CGFloat = 32
        public static let gap900: CGFloat = 36
        public static let gap1000: CGFloat = 40
        public static let gap1400: CGFloat = 56
    }

    /// Convenience named aliases (semantic, not in Figma — keep in sync).
    enum Spacing {
        /// 2pt — hairline separation between tightly coupled elements.
        public static let xxs = Gap.gap050
        /// 4pt — icon↔text in dense rows.
        public static let xs  = Gap.gap100
        /// 8pt — default intra-component.
        public static let sm  = Gap.gap200
        /// 12pt — list row content inset.
        public static let md  = Gap.gap300
        /// 16pt — screen content-to-edge padding.
        public static let lg  = Gap.gap400
        /// 20pt — section gutter.
        public static let xl  = Gap.gap500
        /// 24pt — large card padding.
        public static let xxl = Gap.gap600
        /// 32pt — block separation.
        public static let xxxl = Gap.gap800
    }
}
