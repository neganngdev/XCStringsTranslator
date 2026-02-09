//
//  TranslationService.swift
//  XCStringsTranslator
//
//  Main translation engine orchestrating the translation process
//

import Foundation

/// Main service that orchestrates the translation process
class TranslationService {
    
    /// Translation provider to use
    let provider: TranslationProvider
    
    /// Initialize with a translation provider
    init(provider: TranslationProvider) {
        self.provider = provider
    }
    
    /// Translate a document to target languages
    /// - Parameters:
    ///   - document: The xcstrings document to translate
    ///   - targetLanguages: Languages to translate to
    ///   - skipOptions: Options for skipping strings
    ///   - onProgress: Progress callback
    /// - Returns: Translated document and statistics
    func translateDocument(
        _ document: XCStringsDocument,
        targetLanguages: [String],
        skipOptions: SkipOptions,
        onProgress: @escaping (TranslationProgress) -> Void
    ) async throws -> (document: XCStringsDocument, stats: TranslationStats) {
        
        var updatedDoc = document
        var stats = TranslationStats()
        
        let sourceLanguage = document.sourceLanguage
        let totalStrings = document.strings.count * targetLanguages.count
        var processedCount = 0
        
        // Process each string entry
        for (stringKey, var entry) in document.strings {
            // Check for task cancellation
            try Task.checkCancellation()
            
            // Get source value
            guard let localizations = entry.localizations,
                  let sourceLocalization = localizations[sourceLanguage],
                  let sourceValue = sourceLocalization.stringUnit?.value,
                  !sourceValue.isEmpty else {
                // Skip entries without source value
                for targetLang in targetLanguages {
                    if targetLang == sourceLanguage { continue }
                    processedCount += 1
                    stats.skipped += 1
                    stats.skipReasons[SkipReason.emptySource.rawValue, default: 0] += 1
                    
                    await MainActor.run {
                        onProgress(TranslationProgress(
                            current: processedCount,
                            total: totalStrings,
                            currentKey: stringKey,
                            currentLanguage: targetLang,
                            action: .skipped
                        ))
                    }
                }
                continue
            }
            
            // Process each target language
            for targetLang in targetLanguages {
                // Skip source language
                if targetLang == sourceLanguage { continue }
                
                // Check for task cancellation
                try Task.checkCancellation()
                
                processedCount += 1
                
                // Check if should skip
                let skipResult = SkipChecker.shouldSkip(
                    entry: entry,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLang,
                    options: skipOptions
                )
                
                if skipResult.shouldSkip {
                    stats.skipped += 1
                    if let reason = skipResult.reason {
                        stats.skipReasons[reason.rawValue, default: 0] += 1
                    }
                    
                    await MainActor.run {
                        onProgress(TranslationProgress(
                            current: processedCount,
                            total: totalStrings,
                            currentKey: stringKey,
                            currentLanguage: targetLang,
                            action: .skipped
                        ))
                    }
                    continue
                }
                
                // Translate
                do {
                    let translated = try await provider.translate(
                        text: sourceValue,
                        from: sourceLanguage,
                        to: targetLang,
                        context: entry.comment
                    )
                    
                    // Update entry with translation
                    if entry.localizations == nil {
                        entry.localizations = [:]
                    }
                    
                    entry.localizations?[targetLang] = Localization(
                        stringUnit: StringUnit(state: "translated", value: translated)
                    )
                    
                    stats.translated += 1
                    
                    await MainActor.run {
                        onProgress(TranslationProgress(
                            current: processedCount,
                            total: totalStrings,
                            currentKey: stringKey,
                            currentLanguage: targetLang,
                            action: .translated
                        ))
                    }
                    
                    // Small delay for rate limiting (100ms)
                    try await Task.sleep(nanoseconds: 100_000_000)
                    
                } catch {
                    stats.failed += 1
                    stats.errors.append("\(stringKey) [\(targetLang)]: \(error.localizedDescription)")
                    
                    await MainActor.run {
                        onProgress(TranslationProgress(
                            current: processedCount,
                            total: totalStrings,
                            currentKey: stringKey,
                            currentLanguage: targetLang,
                            action: .failed
                        ))
                    }
                }
            }
            
            // Update document with modified entry
            updatedDoc.strings[stringKey] = entry
        }
        
        return (updatedDoc, stats)
    }
    
    /// Save translated document to file
    /// - Parameters:
    ///   - document: The translated document
    ///   - url: URL to save to
    func saveDocument(_ document: XCStringsDocument, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(document)
        try data.write(to: url)
    }
}
