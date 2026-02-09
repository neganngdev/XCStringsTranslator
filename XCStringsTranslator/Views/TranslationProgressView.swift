//
//  TranslationProgressView.swift
//  XCStringsTranslator
//
//  Shows translation progress with live stats
//

import SwiftUI

struct TranslationProgressView: View {
    let progress: TranslationProgress?
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress indicator
            VStack(spacing: 12) {
                ProgressView(value: progress?.percentage ?? 0, total: 100)
                    .progressViewStyle(.linear)
                
                HStack {
                    Text("\(Int(progress?.percentage ?? 0))%")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if let p = progress {
                        Text("\(p.current) / \(p.total)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Current item
            if let p = progress {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.accentColor)
                    
                    Text(p.currentKey)
                        .lineLimit(1)
                    
                    Text("→")
                        .foregroundStyle(.secondary)
                    
                    Text(languageName(for: p.currentLanguage))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(p.action.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(actionColor(p.action).opacity(0.2))
                        .foregroundColor(actionColor(p.action))
                        .clipShape(Capsule())
                }
                .font(.subheadline)
            }
            
            // Cancel button
            Button("Cancel", role: .cancel, action: onCancel)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func languageName(for code: String) -> String {
        Locale.current.localizedString(forIdentifier: code) ?? code.uppercased()
    }
    
    private func actionColor(_ action: TranslationProgress.Action) -> Color {
        switch action {
        case .translated: return .green
        case .skipped: return .orange
        case .failed: return .red
        }
    }
}

#Preview {
    TranslationProgressView(
        progress: TranslationProgress(
            current: 45,
            total: 100,
            currentKey: "settings.account.title",
            currentLanguage: "vi",
            action: .translated
        ),
        onCancel: {}
    )
    .padding()
}
