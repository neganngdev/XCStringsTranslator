//
//  SkipChecker.swift
//  XCStringsTranslator
//
//  Smart skip logic for translation optimization
//

import Foundation

/// Options for controlling which strings to skip during translation
struct SkipOptions {
    /// Skip strings that are already translated (value differs from source)
    var skipAlreadyTranslated: Bool = true
    
    /// Skip strings marked as "do not translate"
    var skipShouldTranslateFalse: Bool = true
}

/// Reason why a string was skipped
enum SkipReason: String, CaseIterable {
    case alreadyTranslated = "Already translated"
    case shouldTranslateFalse = "Marked do not translate"
    case emptySource = "Empty source value"
}

/// Result of skip check
struct SkipResult {
    let shouldSkip: Bool
    let reason: SkipReason?
}

/// Utility for checking if strings should be skipped during translation
struct SkipChecker {
    
    /// Check if a string entry should be skipped for a target language
    /// - Parameters:
    ///   - entry: The string entry to check
    ///   - sourceLanguage: Source language code
    ///   - targetLanguage: Target language code
    ///   - options: Skip options
    /// - Returns: Skip result with reason
    static func shouldSkip(
        entry: StringEntry,
        sourceLanguage: String,
        targetLanguage: String,
        options: SkipOptions
    ) -> SkipResult {
        
        // Check if marked as "do not translate"
        if options.skipShouldTranslateFalse && !entry.shouldTranslate {
            return SkipResult(shouldSkip: true, reason: .shouldTranslateFalse)
        }
        
        // Get source value
        guard let localizations = entry.localizations,
              let sourceLocalization = localizations[sourceLanguage],
              let sourceValue = sourceLocalization.stringUnit?.value,
              !sourceValue.isEmpty else {
            return SkipResult(shouldSkip: true, reason: .emptySource)
        }
        
        // Check if already translated
        if options.skipAlreadyTranslated {
            if let targetLocalization = localizations[targetLanguage],
               let targetValue = targetLocalization.stringUnit?.value,
               !targetValue.isEmpty,
               targetValue != sourceValue {
                return SkipResult(shouldSkip: true, reason: .alreadyTranslated)
            }
        }
        
        // Should translate
        return SkipResult(shouldSkip: false, reason: nil)
    }
}
