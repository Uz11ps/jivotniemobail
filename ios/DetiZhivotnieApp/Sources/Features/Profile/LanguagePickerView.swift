import SwiftUI

struct LanguagePickerView: View {
    @EnvironmentObject var localizationService: LocalizationService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(LocalizationService.Language.allCases, id: \.self) { language in
                    Button(action: {
                        localizationService.currentLanguage = language
                        dismiss()
                    }) {
                        HStack {
                            Text(language.displayName)
                            Spacer()
                            if localizationService.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Выберите язык")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
