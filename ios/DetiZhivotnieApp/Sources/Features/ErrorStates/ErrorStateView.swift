//
//  ErrorStateView.swift
//  DetiZhivotnieApp
//
//  Figma: `1:7192` — "3. Error states".
//  Two variants:
//    • Generic error  — "Some kind of mistake", mouse-at-laptop illustration,
//                       shows a Back pill.
//    • Offline error  — "The Internet is lost!", bird-with-wifi-off icon,
//                       no Back button (root-level).
//
//  Background: DS.Color.Background.primary (light gray).
//  Title:      DS.Color.Label.error (pink).
//  CTA:        Blue "Reload page" pill.
//

import SwiftUI

struct ErrorStateView: View {
    enum Variant {
        case generic
        case offline
    }

    let variant: Variant
    var onReload: () -> Void = {}
    var onBack: (() -> Void)?

    var body: some View {
        ZStack {
            DS.Color.Background.primary.ignoresSafeArea()

            VStack(spacing: DS.Gap.gap500) {
                Spacer()

                // Title
                Text(titleText)
                    .dsStyle(.title2Bold)
                    .foregroundColor(DS.Color.Label.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Gap.gap600)

                // Illustration (prefer bundled Figma art, fall back to SF Symbols)
                Group {
                    switch variant {
                    case .generic:
                        if UIImage(named: "error_mouse") != nil {
                            Image("error_mouse").resizable().aspectRatio(contentMode: .fit)
                        } else {
                            Image(systemName: "laptopcomputer.slash")
                                .font(.system(size: 140, weight: .regular))
                                .foregroundStyle(DS.Color.Label.primary, DS.Palette.Neutral.n300)
                                .symbolRenderingMode(.hierarchical)
                        }
                    case .offline:
                        if UIImage(named: "error_bird") != nil {
                            Image("error_bird").resizable().aspectRatio(contentMode: .fit)
                        } else {
                            ZStack(alignment: .top) {
                                Image(systemName: "bird.fill")
                                    .font(.system(size: 140, weight: .regular))
                                    .foregroundStyle(DS.Palette.Yellow.c500)
                                Image(systemName: "wifi.slash")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(DS.Color.Label.primary.opacity(0.6))
                                    .offset(y: -16)
                            }
                        }
                    }
                }
                .frame(height: 180)

                // Description
                Text(descriptionText)
                    .dsStyle(.subheadlineSemi)
                    .foregroundColor(DS.Color.Label.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Gap.gap800)

                // CTA
                Button(action: onReload) {
                    Text("Reload page")
                        .dsStyle(.bodySemi)
                        .foregroundColor(DS.Palette.Neutral.n0)
                        .padding(.horizontal, DS.Gap.gap600)
                        .frame(height: 44)
                        .background(Capsule().fill(DS.Color.Fill.accentPrimary))
                }
                .buttonStyle(.plain)
                .padding(.top, DS.Gap.gap300)

                Spacer()
                Spacer()
            }

            // Back button (generic variant only)
            if variant == .generic, let onBack {
                VStack {
                    HStack {
                        Button(action: onBack) {
                            HStack(spacing: DS.Gap.gap100) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Back")
                                    .dsStyle(.subheadlineSemi)
                            }
                            .foregroundColor(DS.Color.Label.primary)
                            .padding(.horizontal, DS.Gap.gap300)
                            .padding(.vertical, DS.Gap.gap200)
                            .background(Capsule().fill(DS.Palette.Neutral.n0.opacity(0.8)))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, DS.Gap.gap400)
                    .padding(.top, DS.Gap.gap400)
                    Spacer()
                }
            }
        }
    }

    private var titleText: String {
        switch variant {
        case .generic: return "Some kind of mistake"
        case .offline: return "The Internet is lost!"
        }
    }

    private var descriptionText: String {
        switch variant {
        case .generic: return "Reload the page, it might help :)"
        case .offline: return "Restore a stable internet connection\nand try to reload the page"
        }
    }
}

#Preview("Generic") {
    ErrorStateView(variant: .generic, onReload: {}, onBack: {})
}

#Preview("Offline") {
    ErrorStateView(variant: .offline, onReload: {})
}
