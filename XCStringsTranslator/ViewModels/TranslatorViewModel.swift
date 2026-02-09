//
//  TranslatorViewModel.swift
//  XCStringsTranslator
//
//  Main ViewModel for file loading, translation, and UI state
//

import Foundation
import SwiftUI
import Combine

@MainActor
class TranslatorViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// URL of the loaded xcstrings file
    @Published var inputFile: URL?
    
    /// Parsed xcstrings document
    @Published var document: XCStringsDocument?
    
    /// Analysis results for the loaded file
    @Published var fileAnalysis: FileAnalysis?
    
    /// Selected translation provider
    @Published var selectedProvider: ProviderType = .gemini
    
    /// Selected target languages
    @Published var selectedLanguages: Set<String> = []
    
    /// Skip options
    @Published var skipOptions = SkipOptions()
    
    /// API key for Gemini
    @Published var apiKey: String = ""
    
    /// DeepLX endpoint
    @Published var deeplxEndpoint: String = "http://localhost:1188/translate"
    
    /// Whether translation is in progress
    @Published var isTranslating = false
    
    /// Current translation progress
    @Published var progress: TranslationProgress?
    
    /// Translation statistics
    @Published var stats: TranslationStats?
    
    /// Error message to display
    @Published var errorMessage: String?
    
    /// Whether a file is currently being loaded
    @Published var isLoading = false
    
    /// Whether translation is complete
    @Published var isComplete = false
    
    /// Output file URL
    @Published var outputFile: URL?
    
    /// Current translation task (for cancellation)
    private var translationTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    /// Current translation provider instance
    var currentProvider: TranslationProvider {
        switch selectedProvider {
        case .apple:
            if #available(macOS 14.0, *) {
                return AppleTranslationProvider()
            } else {
                // Fallback - shouldn't happen on macOS 14+
                return GeminiProvider(apiKey: apiKey)
            }
        case .gemini:
            return GeminiProvider(apiKey: apiKey)
        case .deeplx:
            return DeepLXProvider(endpoint: deeplxEndpoint)
        }
    }
    
    /// Estimated cost for translation
    var estimatedCost: Double {
        guard let analysis = fileAnalysis else { return 0 }
        let totalChars = analysis.totalStrings * 50 * selectedLanguages.count // Estimate 50 chars per string
        return currentProvider.costPer1000Chars * Double(totalChars) / 1000
    }
    
    /// Whether translation can be started
    var canTranslate: Bool {
        guard document != nil, !selectedLanguages.isEmpty else { return false }
        
        switch selectedProvider {
        case .gemini:
            return !apiKey.isEmpty
        case .apple, .deeplx:
            return true
        }
    }
    
    /// Strings that need translation
    var stringsToTranslate: Int {
        guard let analysis = fileAnalysis else { return 0 }
        return analysis.needsTranslation
    }
    
    // MARK: - File Loading
    
    /// Load and parse an xcstrings file
    func loadFile(_ url: URL) {
        isLoading = true
        errorMessage = nil
        
        do {
            // Start accessing security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let doc = try decoder.decode(XCStringsDocument.self, from: data)
            
            self.inputFile = url
            self.document = doc
            self.fileAnalysis = analyzeDocument(doc)
            
            // Auto-select all non-source languages
            if let analysis = fileAnalysis {
                selectedLanguages = Set(analysis.availableLanguages.filter { $0 != analysis.sourceLanguage })
            }
            
            // Reset state
            isComplete = false
            stats = nil
            progress = nil
            outputFile = nil
            
        } catch {
            self.errorMessage = "Failed to load file: \(error.localizedDescription)"
            self.inputFile = nil
            self.document = nil
            self.fileAnalysis = nil
        }
        
        isLoading = false
    }
    
    // MARK: - Translation
    
    /// Start the translation process
    func translate() {
        guard canTranslate, let document = document else { return }
        
        isTranslating = true
        isComplete = false
        errorMessage = nil
        stats = nil
        
        translationTask = Task {
            do {
                let service = TranslationService(provider: currentProvider)
                
                let result = try await service.translateDocument(
                    document,
                    targetLanguages: Array(selectedLanguages),
                    skipOptions: skipOptions
                ) { [weak self] progress in
                    self?.progress = progress
                }
                
                self.document = result.document
                self.stats = result.stats
                self.isComplete = true
                
                // Save result
                try await saveResult(result.document)
                
            } catch is CancellationError {
                self.errorMessage = "Translation cancelled"
            } catch {
                self.errorMessage = error.localizedDescription
            }
            
            self.isTranslating = false
        }
    }
    
    /// Cancel the current translation
    func cancelTranslation() {
        translationTask?.cancel()
        translationTask = nil
        isTranslating = false
    }
    
    /// Save translated document
    private func saveResult(_ document: XCStringsDocument) async throws {
        guard let inputFile = inputFile else { return }
        
        // Generate output filename
        let outputName = inputFile.deletingPathExtension().lastPathComponent + "_translated.xcstrings"
        let outputURL = inputFile.deletingLastPathComponent().appendingPathComponent(outputName)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(document)
        try data.write(to: outputURL)
        
        self.outputFile = outputURL
    }
    
    // MARK: - File Analysis
    
    private func analyzeDocument(_ document: XCStringsDocument) -> FileAnalysis {
        let sourceLanguage = document.sourceLanguage
        var allLanguages = Set<String>()
        var alreadyTranslatedCount = 0
        var shouldNotTranslateCount = 0
        
        for (_, entry) in document.strings {
            if !entry.shouldTranslate {
                shouldNotTranslateCount += 1
            }
            
            guard let localizations = entry.localizations,
                  let sourceLocalization = localizations[sourceLanguage],
                  let sourceValue = sourceLocalization.stringUnit?.value else {
                continue
            }
            
            for (langCode, localization) in localizations {
                allLanguages.insert(langCode)
                
                if langCode == sourceLanguage { continue }
                
                if let targetValue = localization.stringUnit?.value,
                   !targetValue.isEmpty,
                   targetValue != sourceValue {
                    alreadyTranslatedCount += 1
                }
            }
        }
        
        return FileAnalysis(
            totalStrings: document.strings.count,
            availableLanguages: allLanguages.sorted(),
            alreadyTranslated: alreadyTranslatedCount,
            shouldNotTranslate: shouldNotTranslateCount,
            sourceLanguage: sourceLanguage
        )
    }
    
    // MARK: - Helper Functions
    
    func selectAllLanguages() {
        guard let analysis = fileAnalysis else { return }
        selectedLanguages = Set(analysis.availableLanguages.filter { $0 != analysis.sourceLanguage })
    }
    
    func deselectAllLanguages() {
        selectedLanguages = []
    }
    
    func reset() {
        cancelTranslation()
        inputFile = nil
        document = nil
        fileAnalysis = nil
        selectedLanguages = []
        isComplete = false
        stats = nil
        progress = nil
        errorMessage = nil
        outputFile = nil
    }
    
    /// Open file in Finder
    func openInFinder() {
        guard let url = outputFile else { return }
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }
    
    /// Open file in Xcode
    func openInXcode() {
        guard let url = outputFile else { return }
        NSWorkspace.shared.open(url)
    }
}
