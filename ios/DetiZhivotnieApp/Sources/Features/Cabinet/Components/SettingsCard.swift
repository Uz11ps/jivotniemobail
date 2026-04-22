//
//  SettingsCard.swift
//  DetiZhivotnieApp
//
//  Figma: White rounded container that wraps rows inside a Cabinet section.
//  Inserts a hairline separator between rows (indented past the icon).
//

import SwiftUI

struct SettingsCard: View {
    /// Heterogeneous rows (different Trailing generic types) erased to AnyView.
    let rows: [AnyView]

    init(rows: [AnyView]) {
        self.rows = rows
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rows.count, id: \.self) { idx in
                rows[idx]
                if idx < rows.count - 1 {
                    Rectangle()
                        .fill(DS.Color.separator)
                        .frame(height: 1)
                        .padding(.leading, DS.Gap.gap400 + 32 + DS.Gap.gap300)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.l)
                .fill(DS.Color.Background.primaryElevated)
        )
    }
}
