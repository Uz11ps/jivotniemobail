//
//  AnimalBoard.swift
//  DetiZhivotnieApp
//
//  Figma: `1:6656` — Animal board (390×348 at y=342..690).
//  4-column grid of animal tiles. Scrolls vertically if more than 12 animals.
//

import SwiftUI

struct AnimalBoard: View {
    let animals: [Animal]
    let theme: CategoryTheme
    let categoryIsLocked: Bool
    var onTapAnimal: (Animal) -> Void = { _ in }

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: DS.Gap.gap300),
        count: 4
    )

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: DS.Gap.gap300) {
                ForEach(animals) { animal in
                    Button {
                        onTapAnimal(animal)
                    } label: {
                        AnimalTile(
                            animal: animal,
                            theme: theme,
                            isLocked: categoryIsLocked
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DS.Gap.gap400)
            .padding(.top, DS.Gap.gap200)
            // Leave room for the pill tab bar floating at the bottom.
            .padding(.bottom, 120)
        }
    }
}
