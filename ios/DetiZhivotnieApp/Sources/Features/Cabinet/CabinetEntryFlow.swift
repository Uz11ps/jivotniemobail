//
//  CabinetEntryFlow.swift
//  DetiZhivotnieApp
//
//  Figma: "2. Cabinet" flow — tapping the profile avatar on Main opens the
//  Parent Control math gate; a correct answer transitions into the Parent
//  Cabinet. Cancel (tap outside card) returns to Main.
//

import SwiftUI

struct CabinetEntryFlow: View {
    @Environment(\.dismiss) private var dismiss
    @State private var stage: Stage = .gate
    @EnvironmentObject var localizationService: LocalizationService

    private enum Stage {
        case gate
        case cabinet
    }

    var body: some View {
        ZStack {
            switch stage {
            case .gate:
                // Transparent backdrop — Main screen keeps rendering underneath
                // via the fullScreenCover presentation.
                ParentalGateView(
                    onSuccess: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            stage = .cabinet
                        }
                    },
                    onCancel: { dismiss() }
                )
            case .cabinet:
                ParentCabinetView()
                    .environmentObject(localizationService)
            }
        }
    }
}
