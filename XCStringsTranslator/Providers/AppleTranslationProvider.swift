//
//  AppleTranslationProvider.swift
//  XCStringsTranslator
//
//  Translation provider using Apple's on-device Translation framework
//

import Foundation
import Translation

/// Translation provider using Apple's on-device Translation framework
/// Available on macOS 14.0+ with supported language pairs
@available(macOS 14.0, *)
class AppleTranslationProvider: TranslationProvider {
    
    let name = "Apple Translation"
    let needsAPIKey = false
    let costPer1000Chars = 0.0  // FREE!
    
    let supportedLanguages: Set<String> = [
        "ar", "zh", "zh-Hans", "zh-Hant", "nl", "en",
        "fr", "de", "id", "it", "ja", "ko", "pl",
        "pt", "ru", "es", "th", "tr", "uk", "vi"
    ]
    
    /// Shared translation session configuration
    private var configuration: TranslationSession.Configuration?
    
    func translate(
        text: String,
        from: String,
        to: String,
        context: String?
    ) async throws -> String {
        // Validate language support
        guard supportedLanguages.contains(from) || supportedLanguages.contains(normalizeLanguageCode(from)) else {
            throw TranslationError.unsupportedLanguage(from)
        }
        guard supportedLanguages.contains(to) || supportedLanguages.contains(normalizeLanguageCode(to)) else {
            throw TranslationError.unsupportedLanguage(to)
        }
        
        // Protect placeholders
        let protectionResult = PlaceholderProtector.protect(text)
        
        // Create language identifiers
        let sourceLanguage = Locale.Language(identifier: from)
        let targetLanguage = Locale.Language(identifier: to)
        
        do {
            // Use TranslationSession for translation
            let session = TranslationSession.Configuration(
                source: sourceLanguage,
                target: targetLanguage
            )
            
            // Perform translation using the session
            let request = TranslationSession.Request(sourceText: protectionResult.protected)
            
            // Note: In actual implementation, you would use the session's translate method
            // For now, we'll use a simpler approach with availability check
            let translatedText = try await performTranslation(
                text: protectionResult.protected,
                from: sourceLanguage,
                to: targetLanguage
            )
            
            // Restore placeholders
            return PlaceholderProtector.restore(translatedText, placeholders: protectionResult.placeholders)
            
        } catch {
            throw TranslationError.apiError("Apple Translation error: \(error.localizedDescription)")
        }
    }
    
    /// Perform the actual translation
    private func performTranslation(
        text: String,
        from: Locale.Language,
        to: Locale.Language
    ) async throws -> String {
        // The Translation framework requires a UI context in SwiftUI
        // For command-line or background usage, we need to handle this differently
        
        // Create a translation configuration
        let config = TranslationSession.Configuration(source: from, target: to)
        
        // Note: TranslationSession requires being used within a SwiftUI view context
        // In a real implementation, you would:
        // 1. Use .translationTask() modifier in SwiftUI
        // 2. Or use a bridge to handle the translation
        
        // For now, throw an error indicating the limitation
        // This will be properly integrated with SwiftUI in Phase 6
        throw TranslationError.apiError("Apple Translation requires SwiftUI context - will be integrated in UI phase")
    }
    
    /// Normalize language codes (e.g., "zh" -> "zh-Hans")
    private func normalizeLanguageCode(_ code: String) -> String {
        switch code {
        case "zh": return "zh-Hans"
        default: return code
        }
    }
}
