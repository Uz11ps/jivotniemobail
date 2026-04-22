//
//  Radius.swift
//  DetiZhivotnieApp
//
//  Corner-radius tokens — generated from Figma (file: VcYnAfAMMhLuhxOyzTg162).
//
//  Usage:
//      .clipShape(RoundedRectangle(cornerRadius: DS.Radius.m))
//      .cornerRadius(DS.Radius.pill)  // fully rounded
//

import CoreGraphics

public extension DS {
    enum Radius {
        public static let xxs: CGFloat = 4
        public static let xs:  CGFloat = 8
        public static let s:   CGFloat = 12
        public static let m:   CGFloat = 16
        public static let l:   CGFloat = 20
        public static let xl:  CGFloat = 24
        public static let xxl: CGFloat = 28
        public static let xxxl: CGFloat = 32
        /// Figma calls this "Exterminatus" — use for pill/capsule shapes.
        public static let pill: CGFloat = 1000
    }

    enum IconSize {
        public static let s:  CGFloat = 16
        public static let m:  CGFloat = 24
        public static let l:  CGFloat = 32
        public static let xl: CGFloat = 44
    }
}
