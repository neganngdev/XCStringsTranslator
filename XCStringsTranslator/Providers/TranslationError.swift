//
//  TranslationError.swift
//  XCStringsTranslator
//
//  Translation-related errors with user-friendly messages
//

import Foundation

/// Errors that can occur during translation
enum TranslationError: Error, LocalizedError {
    /// Target language is not supported by this provider
    case unsupportedLanguage(String)
    
    /// API returned an error
    case apiError(String)
    
    /// Translation service is not available
    case notAvailable
    
    /// Invalid file format
    case invalidFile
    
    /// Network connection failed
    case networkError
    
    /// Rate limit exceeded
    case rateLimitExceeded
    
    /// Invalid API key
    case invalidAPIKey
    
    /// User-friendly error description
    var errorDescription: String? {
        switch self {
        case .unsupportedLanguage(let lang):
            return "Language '\(lang)' is not supported by this provider"
        case .apiError(let message):
            return message
        case .notAvailable:
            return "Translation service is not available on this macOS version"
        case .invalidFile:
            return "Invalid .xcstrings file format"
        case .networkError:
            return "Network error - check your internet connection"
        case .rateLimitExceeded:
            return "Rate limit exceeded - please wait and try again"
        case .invalidAPIKey:
            return "Invalid API key - please check your credentials"
        }
    }
    
    /// Suggestion for how to fix the error
    var recoverySuggestion: String? {
        switch self {
        case .unsupportedLanguage:
            return "Try using a different provider that supports this language"
        case .apiError:
            return nil
        case .notAvailable:
            return "Update to macOS 14.0 or later"
        case .invalidFile:
            return "Export a fresh .xcstrings file from Xcode"
        case .networkError:
            return "Check your internet connection and try again"
        case .rateLimitExceeded:
            return "Wait a few minutes before trying again"
        case .invalidAPIKey:
            return "Get a new API key from the provider"
        }
    }
}
