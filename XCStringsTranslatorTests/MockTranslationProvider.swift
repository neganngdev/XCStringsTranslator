//
//  MockTranslationProvider.swift
//  XCStringsTranslatorTests
//
//  Mock provider for testing translation workflows
//

import Foundation
@testable import XCStringsTranslator

/// Mock translation provider for testing
class MockTranslationProvider: TranslationProvider {
    let name = "Mock Provider"
    let needsAPIKey = false
    let costPer1000Chars = 0.0
    let supportedLanguages: Set<String> = ["en", "es", "fr", "de", "vi", "ja"]
    
    /// Whether to simulate errors
    var shouldFail = false
    var errorToThrow: TranslationError = .networkError
    
    /// Delay per translation (in seconds)
    var delay: TimeInterval = 0
    
    /// Translations performed
    var translationCount = 0
    
    /// Translation history
    var translations: [(text: String, from: String, to: String)] = []
    
    func translate(text: String, from: String, to: String, context: String?) async throws -> String {
        if shouldFail {
            throw errorToThrow
        }
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        translationCount += 1
        translations.append((text, from, to))
        
        // Return a mock translation with language prefix
        return "[\(to.uppercased())] \(text)"
    }
    
    func reset() {
        shouldFail = false
        translationCount = 0
        translations = []
    }
}
