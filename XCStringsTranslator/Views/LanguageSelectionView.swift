//
//  LanguageSelectionView.swift
//  XCStringsTranslator
//
//  Language selection grid with filter options
//

import SwiftUI

struct LanguageSelectionView: View {
    let availableLanguages: [String]
    let sourceLanguage: String
    @Binding var selectedLanguages: Set<String>
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🌐 Target Languages")
                    .font(.headline)
                
                Spacer()
                
                Button("Select All") {
                    selectedLanguages = Set(availableLanguages.filter { $0 != sourceLanguage })
                }
                .buttonStyle(.link)
                
                Button("Clear") {
                    selectedLanguages = []
                }
                .buttonStyle(.link)
            }
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(availableLanguages.filter { $0 != sourceLanguage }, id: \.self) { code in
                    LanguageCheckbox(
                        code: code,
                        isSelected: selectedLanguages.contains(code),
                        onToggle: {
                            if selectedLanguages.contains(code) {
                                selectedLanguages.remove(code)
                            } else {
                                selectedLanguages.insert(code)
                            }
                        }
                    )
                }
            }
            
            Text("Selected: \(selectedLanguages.count) of \(availableLanguages.count - 1) languages")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct LanguageCheckbox: View {
    let code: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Text(flagEmoji(for: code))
                
                Text(languageName(for: code))
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    
    private func languageName(for code: String) -> String {
        Locale.current.localizedString(forIdentifier: code) ?? code.uppercased()
    }
    
    private func flagEmoji(for code: String) -> String {
        let flags: [String: String] = [
            "en": "🇺🇸", "es": "🇪🇸", "de": "🇩🇪", "fr": "🇫🇷",
            "it": "🇮🇹", "ja": "🇯🇵", "ko": "🇰🇷", "nl": "🇳🇱",
            "pl": "🇵🇱", "pt": "🇵🇹", "ru": "🇷🇺", "zh": "🇨🇳",
            "zh-Hans": "🇨🇳", "zh-Hant": "🇹🇼", "ar": "🇸🇦",
            "th": "🇹🇭", "tr": "🇹🇷", "uk": "🇺🇦", "vi": "🇻🇳",
            "id": "🇮🇩", "ro": "🇷🇴", "hi": "🇮🇳", "ms": "🇲🇾"
        ]
        return flags[code] ?? "🌐"
    }
}

#Preview {
    LanguageSelectionView(
        availableLanguages: ["en", "es", "de", "fr", "it", "ja", "ko", "nl", "pl", "pt", "ru", "zh", "vi"],
        sourceLanguage: "en",
        selectedLanguages: .constant(["es", "de", "fr"])
    )
    .padding()
}
