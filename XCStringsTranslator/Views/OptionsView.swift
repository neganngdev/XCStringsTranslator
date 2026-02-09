//
//  OptionsView.swift
//  XCStringsTranslator
//
//  Skip options configuration
//

import SwiftUI

struct OptionsView: View {
    @Binding var skipOptions: SkipOptions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("⚙️ Options")
                .font(.headline)
            
            Toggle(isOn: $skipOptions.skipAlreadyTranslated) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Skip already translated strings")
                    Text("Don't re-translate strings that differ from source")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Toggle(isOn: $skipOptions.skipShouldTranslateFalse) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Skip strings marked 'do not translate'")
                    Text("Respect comment markers like \"do not translate\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    OptionsView(skipOptions: .constant(SkipOptions()))
        .padding()
}
