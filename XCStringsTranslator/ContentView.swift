//
//  ContentView.swift
//  XCStringsTranslator
//
//  Main window with full translation workflow
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TranslatorViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.document == nil {
                    // File drop zone
                    FileDropZone { url in
                        viewModel.loadFile(url)
                    }
                    .frame(minHeight: 300)
                } else if viewModel.isComplete, let stats = viewModel.stats {
                    // Results view
                    ResultsView(
                        stats: stats,
                        outputFile: viewModel.outputFile,
                        onOpenFinder: viewModel.openInFinder,
                        onOpenXcode: viewModel.openInXcode,
                        onNewTranslation: viewModel.reset
                    )
                } else if viewModel.isTranslating {
                    // Progress view
                    fileInfoSection
                    
                    TranslationProgressView(
                        progress: viewModel.progress,
                        onCancel: viewModel.cancelTranslation
                    )
                } else {
                    // Configuration view
                    fileInfoSection
                    
                    ProviderSelectionView(
                        selectedProvider: $viewModel.selectedProvider,
                        apiKey: $viewModel.apiKey,
                        deeplxEndpoint: $viewModel.deeplxEndpoint
                    )
                    
                    if let analysis = viewModel.fileAnalysis {
                        LanguageSelectionView(
                            availableLanguages: analysis.availableLanguages,
                            sourceLanguage: analysis.sourceLanguage,
                            selectedLanguages: $viewModel.selectedLanguages
                        )
                    }
                    
                    OptionsView(skipOptions: $viewModel.skipOptions)
                    
                    translateButton
                }
            }
            .padding(24)
        }
        .frame(minWidth: 600, minHeight: 500)
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
    
    // MARK: - File Info Section
    
    private var fileInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
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
                
                if !viewModel.isTranslating {
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
            
            // Statistics
            if let analysis = viewModel.fileAnalysis {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    StatCard(icon: "globe", label: "Source", value: languageName(for: analysis.sourceLanguage))
                    StatCard(icon: "number", label: "Strings", value: "\(analysis.totalStrings)")
                    StatCard(icon: "list.bullet", label: "Languages", value: "\(analysis.availableLanguages.count)")
                    StatCard(icon: "checkmark.circle", label: "Translated", value: "\(analysis.alreadyTranslated)")
                    StatCard(icon: "xmark.circle", label: "No Translate", value: "\(analysis.shouldNotTranslate)")
                    StatCard(icon: "arrow.triangle.2.circlepath", label: "To Translate", value: "\(viewModel.stringsToTranslate)")
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Translate Button
    
    private var translateButton: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.translate()
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    
                    Text("Translate \(viewModel.selectedLanguages.count) Languages")
                    
                    if viewModel.estimatedCost > 0 {
                        Text("(~$\(String(format: "%.2f", viewModel.estimatedCost)))")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("(FREE)")
                            .foregroundStyle(.green)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canTranslate)
            
            if !viewModel.canTranslate {
                if viewModel.selectedProvider == .gemini && viewModel.apiKey.isEmpty {
                    Text("Please enter your Gemini API key")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if viewModel.selectedLanguages.isEmpty {
                    Text("Please select at least one target language")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func languageName(for code: String) -> String {
        Locale.current.localizedString(forIdentifier: code) ?? code.uppercased()
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
}
