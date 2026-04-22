//
//  LanguagePickerView.swift
//  DetiZhivotnieApp
//
//  Figma: `1:7487` (2.3.1 Language).
//  Header: "< Language"  · List: [flag] [name] [radio]
//  Tapping a row applies the language and dismisses.
//

import SwiftUI

struct LanguagePickerView: View {
    @EnvironmentObject var localizationService: LocalizationService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.Background.primary.ignoresSafeArea()

                VStack(spacing: 0) {
                    ForEach(Array(LocalizationService.Language.allCases.enumerated()), id: \.element) { index, language in
                        languageRow(language)
                        if index < LocalizationService.Language.allCases.count - 1 {
                            Rectangle()
                                .fill(DS.Color.separator)
                                .frame(height: 1)
                                .padding(.leading, DS.Gap.gap400 + 28 + DS.Gap.gap300)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.l)
                        .fill(DS.Color.Background.primaryElevated)
                )
                .padding(.horizontal, DS.Gap.gap400)
                .padding(.top, DS.Gap.gap400)
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle(currentTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(DS.Color.Icon.primary)
                    }
                }
            }
        }
    }

    private var currentTitle: String {
        localizationService.currentLanguage == .ru ? "Язык" : "Language"
    }

    private func languageRow(_ language: LocalizationService.Language) -> some View {
        let isSelected = localizationService.currentLanguage == language
        return Button {
            localizationService.currentLanguage = language
            // Brief cosmetic delay so the radio update is perceptible,
            // then dismiss back to Cabinet.
            Task {
                try? await Task.sleep(nanoseconds: 250_000_000)
                await MainActor.run { dismiss() }
            }
        } label: {
            HStack(spacing: DS.Gap.gap300) {
                Text(flag(for: language))
                    .font(.system(size: 24))
                    .frame(width: 28, height: 28)

                Text(language.displayName)
                    .dsStyle(.body)
                    .foregroundColor(DS.Color.Label.primary)

                Spacer()

                RadioIcon(isSelected: isSelected)
            }
            .padding(.horizontal, DS.Gap.gap400)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func flag(for language: LocalizationService.Language) -> String {
        switch language {
        case .ru: return "🇷🇺"
        case .en: return "🇬🇧"
        }
    }
}

// MARK: - Radio icon

struct RadioIcon: View {
    let isSelected: Bool
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? DS.Color.Fill.accentPrimary : DS.Color.separator, lineWidth: 2)
                .frame(width: 22, height: 22)
            if isSelected {
                Circle()
                    .fill(DS.Color.Fill.accentPrimary)
                    .frame(width: 12, height: 12)
            }
        }
    }
}
