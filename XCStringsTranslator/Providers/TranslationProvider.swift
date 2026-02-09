//
//  TranslationProvider.swift
//  XCStringsTranslator
//
//  Protocol defining translation provider interface
//

import Foundation

/// Protocol for translation service providers
protocol TranslationProvider {
    /// Display name of the provider
    var name: String { get }
    
    /// Whether this provider requires an API key
    var needsAPIKey: Bool { get }
    
    /// Set of supported language codes
    var supportedLanguages: Set<String> { get }
    
    /// Cost per 1000 characters (for estimation)
    var costPer1000Chars: Double { get }
    
    /// Translate text from source to target language
    /// - Parameters:
    ///   - text: Text to translate
    ///   - from: Source language code
    ///   - to: Target language code
    ///   - context: Optional context for better translation
    /// - Returns: Translated text
    func translate(
        text: String,
        from: String,
        to: String,
        context: String?
    ) async throws -> String
}

/// Provider type enumeration for UI selection
enum ProviderType: String, CaseIterable, Identifiable {
    case apple = "Apple Translation"
    case gemini = "Google Gemini"
    case deeplx = "DeepLX"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .apple: return "apple.logo"
        case .gemini: return "sparkles"
        case .deeplx: return "server.rack"
        }
    }
    
    var description: String {
        switch self {
        case .apple: return "FREE • On-device • No setup"
        case .gemini: return "~$0.50/app • Best quality"
        case .deeplx: return "FREE • Self-hosted • Privacy"
        }
    }
}
