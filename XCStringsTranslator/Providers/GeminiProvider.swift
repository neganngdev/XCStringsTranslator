//
//  GeminiProvider.swift
//  XCStringsTranslator
//
//  Translation provider using Google Gemini API
//

import Foundation

/// Translation provider using Google Gemini API
/// Requires API key from https://aistudio.google.com/app/apikey
class GeminiProvider: TranslationProvider {
    
    let name = "Google Gemini"
    let needsAPIKey = true
    let costPer1000Chars = 0.00008  // ~$0.08 per 1M chars
    
    let supportedLanguages: Set<String> = [
        "en", "es", "de", "fr", "it", "ja", "ko", "nl",
        "pl", "ro", "ru", "th", "tr", "uk", "vi",
        "ar", "zh", "pt", "hi", "id", "ms"
    ]
    
    private let apiKey: String
    private let model = "gemini-2.0-flash-exp"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func translate(
        text: String,
        from: String,
        to: String,
        context: String?
    ) async throws -> String {
        // Validate API key
        guard !apiKey.isEmpty else {
            throw TranslationError.invalidAPIKey
        }
        
        // Protect placeholders
        let protectionResult = PlaceholderProtector.protect(text)
        
        // Build translation prompt
        let prompt = buildPrompt(
            text: protectionResult.protected,
            from: from,
            to: to,
            context: context
        )
        
        // Make API request
        let translatedText = try await callGeminiAPI(prompt: prompt)
        
        // Restore placeholders
        return PlaceholderProtector.restore(translatedText, placeholders: protectionResult.placeholders)
    }
    
    /// Build the translation prompt
    private func buildPrompt(text: String, from: String, to: String, context: String?) -> String {
        var prompt = """
        Translate this text from \(languageName(from)) to \(languageName(to)).
        
        CRITICAL RULES:
        1. Preserve ALL tokens like <<<PH0>>>, <<<PH1>>> exactly as-is
        2. Output ONLY the translation, no explanations or quotes
        3. Keep the same tone and formality
        4. This is for a mobile app UI
        """
        
        if let context = context, !context.isEmpty {
            prompt += "\n5. Context: \(context)"
        }
        
        prompt += "\n\nText: \(text)"
        
        return prompt
    }
    
    /// Get human-readable language name
    private func languageName(_ code: String) -> String {
        Locale.current.localizedString(forIdentifier: code) ?? code
    }
    
    /// Call Gemini API and return translated text
    private func callGeminiAPI(prompt: String) async throws -> String {
        // Build URL
        guard let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)") else {
            throw TranslationError.apiError("Invalid API URL")
        }
        
        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        // Build request body
        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 1000
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.networkError
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401, 403:
            throw TranslationError.invalidAPIKey
        case 429:
            throw TranslationError.rateLimitExceeded
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TranslationError.apiError("Gemini API error (\(httpResponse.statusCode)): \(errorMessage)")
        }
        
        // Parse response
        return try parseGeminiResponse(data: data)
    }
    
    /// Parse Gemini API response
    private func parseGeminiResponse(data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw TranslationError.apiError("Invalid response format from Gemini API")
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
