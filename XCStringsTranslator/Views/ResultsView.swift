//
//  ResultsView.swift
//  XCStringsTranslator
//
//  Shows translation completion results and actions
//

import SwiftUI

struct ResultsView: View {
    let stats: TranslationStats
    let outputFile: URL?
    let onOpenFinder: () -> Void
    let onOpenXcode: () -> Void
    let onNewTranslation: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Success header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
                
                Text("Translation Complete!")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Divider()
            
            // Statistics
            VStack(alignment: .leading, spacing: 12) {
                Text("📊 Statistics")
                    .font(.headline)
                
                StatisticRow(icon: "checkmark.circle", label: "Translated", value: "\(stats.translated)", color: .green)
                StatisticRow(icon: "forward.circle", label: "Skipped", value: "\(stats.skipped)", color: .orange)
                
                // Skip reason breakdown
                if !stats.skipReasons.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(stats.skipReasons.sorted(by: { $0.key < $1.key }), id: \.key) { reason, count in
                            HStack {
                                Text("• \(reason)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.leading, 32)
                        }
                    }
                }
                
                StatisticRow(icon: "xmark.circle", label: "Failed", value: "\(stats.failed)", color: .red)
            }
            
            // Errors (if any)
            if !stats.errors.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("⚠️ Errors")
                        .font(.headline)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(stats.errors.prefix(10), id: \.self) { error in
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if stats.errors.count > 10 {
                                Text("... and \(stats.errors.count - 10) more")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                }
            }
            
            Divider()
            
            // Output file
            if let outputFile = outputFile {
                VStack(alignment: .leading, spacing: 8) {
                    Text("📁 Output File")
                        .font(.headline)
                    
                    Text(outputFile.lastPathComponent)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Actions
            HStack(spacing: 12) {
                Button(action: onOpenFinder) {
                    Label("Show in Finder", systemImage: "folder")
                }
                .buttonStyle(.bordered)
                
                Button(action: onOpenXcode) {
                    Label("Open in Xcode", systemImage: "hammer")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: onNewTranslation) {
                    Label("New Translation", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatisticRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ResultsView(
        stats: TranslationStats(
            translated: 150,
            skipped: 30,
            failed: 2,
            skipReasons: ["Already translated": 25, "Marked do not translate": 5],
            errors: ["key1 [vi]: Translation failed"]
        ),
        outputFile: URL(fileURLWithPath: "/path/to/Localizable_translated.xcstrings"),
        onOpenFinder: {},
        onOpenXcode: {},
        onNewTranslation: {}
    )
    .padding()
}
