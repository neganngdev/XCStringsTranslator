//
//  TranslatorViewModel.swift
//  XCStringsTranslator
//
//  Main ViewModel for file loading and translation
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
    
    /// Error message to display
    @Published var errorMessage: String?
    
    /// Whether a file is currently being loaded
    @Published var isLoading = false
    
    // MARK: - File Loading
    
    /// Load and parse an xcstrings file
    /// - Parameter url: URL to the xcstrings file
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
            
        } catch {
            self.errorMessage = "Failed to load file: \(error.localizedDescription)"
            self.inputFile = nil
            self.document = nil
            self.fileAnalysis = nil
        }
        
        isLoading = false
    }
    
    // MARK: - File Analysis
    
    /// Analyze an xcstrings document and return statistics
    /// - Parameter document: The parsed xcstrings document
    /// - Returns: Analysis results with translation statistics
    private func analyzeDocument(_ document: XCStringsDocument) -> FileAnalysis {
        let sourceLanguage = document.sourceLanguage
        var allLanguages = Set<String>()
        var alreadyTranslatedCount = 0
        var shouldNotTranslateCount = 0
        
        for (_, entry) in document.strings {
            // Count strings marked as "do not translate"
            if !entry.shouldTranslate {
                shouldNotTranslateCount += 1
            }
            
            // Get source value
            guard let localizations = entry.localizations,
                  let sourceLocalization = localizations[sourceLanguage],
                  let sourceValue = sourceLocalization.stringUnit?.value else {
                continue
            }
            
            // Collect all languages and check for existing translations
            for (langCode, localization) in localizations {
                allLanguages.insert(langCode)
                
                // Skip source language
                if langCode == sourceLanguage { continue }
                
                // Check if this localization has a different value (already translated)
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
    
    /// Reset the view model state
    func reset() {
        inputFile = nil
        document = nil
        fileAnalysis = nil
        errorMessage = nil
        isLoading = false
    }
}
