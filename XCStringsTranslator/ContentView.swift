//
//  ContentView.swift
//  XCStringsTranslator
//
//  Main window with file drop zone and info display
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TranslatorViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.document == nil {
                // File drop zone
                FileDropZone { url in
                    viewModel.loadFile(url)
                }
                .padding(24)
            } else {
                // File info display
                fileInfoView
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - File Info View
    
    private var fileInfoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with file name
                fileHeader
                
                Divider()
                
                // File statistics
                if let analysis = viewModel.fileAnalysis {
                    statisticsSection(analysis)
                }
                
                Divider()
                
                // Actions placeholder (for future phases)
                actionsSection
                
                Spacer()
            }
            .padding(24)
        }
    }
    
    private var fileHeader: some View {
        HStack {
            Image(systemName: "doc.text.fill")
                .font(.title)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.inputFile?.lastPathComponent ?? "Unknown File")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(viewModel.inputFile?.deletingLastPathComponent().path ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button {
                viewModel.reset()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Close file")
        }
    }
    
    private func statisticsSection(_ analysis: FileAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📄 File Information")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], alignment: .leading, spacing: 12) {
                StatRow(icon: "globe", label: "Source Language", value: languageName(for: analysis.sourceLanguage))
                StatRow(icon: "number", label: "Total Strings", value: "\(analysis.totalStrings)")
                StatRow(icon: "list.bullet", label: "Languages", value: "\(analysis.availableLanguages.count)")
                StatRow(icon: "checkmark.circle", label: "Already Translated", value: "\(analysis.alreadyTranslated)")
                StatRow(icon: "xmark.circle", label: "Do Not Translate", value: "\(analysis.shouldNotTranslate)")
                StatRow(icon: "arrow.triangle.2.circlepath", label: "Need Translation", value: "\(analysis.needsTranslation)")
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🚀 Translation")
                .font(.headline)
            
            Text("Translation provider selection will be available in the next phase.")
                .foregroundStyle(.secondary)
            
            Button {
                // Placeholder for future translation action
            } label: {
                Label("Translate", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(true)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helpers
    
    private func languageName(for code: String) -> String {
        Locale.current.localizedString(forIdentifier: code) ?? code.uppercased()
    }
}

// MARK: - Supporting Views

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            
            Text(label)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ContentView()
}
