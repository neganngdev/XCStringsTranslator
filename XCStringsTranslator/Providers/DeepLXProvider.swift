//
//  DeepLXProvider.swift
//  XCStringsTranslator
//
//  Translation provider using self-hosted DeepLX service
//

import Foundation

/// Translation provider using self-hosted DeepLX service
/// Requires running DeepLX server locally or on a remote host
/// See: https://github.com/OwO-Network/DeepLX
class DeepLXProvider: TranslationProvider {
    
    let name = "DeepLX"
    let needsAPIKey = false
    let costPer1000Chars = 0.0  // FREE if self-hosted
    
    let supportedLanguages: Set<String> = [
        "en", "de", "fr", "es", "pt", "it", "nl",
        "pl", "ru", "ja", "zh", "ko"
    ]
    
    /// DeepLX language code mapping
    private let languageCodeMapping: [String: String] = [
        "en": "EN",
        "de": "DE",
        "fr": "FR",
        "es": "ES",
        "pt": "PT",
        "it": "IT",
        "nl": "NL",
        "pl": "PL",
        "ru": "RU",
        "ja": "JA",
        "zh": "ZH",
        "ko": "KO"
    ]
    
    private let endpoint: String
    
    init(endpoint: String = "http://localhost:1188/translate") {
        self.endpoint = endpoint
    }
    
    func translate(
        text: String,
        from: String,
        to: String,
        context: String?
    ) async throws -> String {
        // Validate language support
        guard supportedLanguages.contains(from) else {
            throw TranslationError.unsupportedLanguage(from)
        }
        guard supportedLanguages.contains(to) else {
            throw TranslationError.unsupportedLanguage(to)
        }
        
        // Protect placeholders
        let protectionResult = PlaceholderProtector.protect(text)
        
        // Make API request
        let translatedText = try await callDeepLXAPI(
            text: protectionResult.protected,
            from: from,
            to: to
        )
        
        // Restore placeholders
        return PlaceholderProtector.restore(translatedText, placeholders: protectionResult.placeholders)
    }
    
    /// Call DeepLX API and return translated text
    private func callDeepLXAPI(text: String, from: String, to: String) async throws -> String {
        // Build URL
        guard let url = URL(string: endpoint) else {
            throw TranslationError.apiError("Invalid DeepLX endpoint URL")
        }
        
        // Map language codes to DeepL format
        let sourceLang = languageCodeMapping[from] ?? from.uppercased()
        let targetLang = languageCodeMapping[to] ?? to.uppercased()
        
        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        // Build request body
        let body: [String: Any] = [
            "text": text,
            "source_lang": sourceLang,
            "target_lang": targetLang
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranslationError.networkError
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw TranslationError.apiError("DeepLX error (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            // Parse response
            return try parseDeepLXResponse(data: data)
            
        } catch let error as TranslationError {
            throw error
        } catch {
            // Connection error - likely server not running
            throw TranslationError.apiError("DeepLX not reachable. Is the service running?\n\nStart with: docker run -d -p 1188:1188 ghcr.io/OwO-Network/DeepLX:latest")
        }
    }
    
    /// Parse DeepLX API response
    private func parseDeepLXResponse(data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TranslationError.apiError("Invalid response format from DeepLX")
        }
        
        // Check for error in response
        if let code = json["code"] as? Int, code != 200 {
            let message = json["message"] as? String ?? "Unknown error"
            throw TranslationError.apiError("DeepLX error: \(message)")
        }
        
        // Extract translated text
        guard let translatedText = json["data"] as? String else {
            throw TranslationError.apiError("No translation data in DeepLX response")
        }
        
        return translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
