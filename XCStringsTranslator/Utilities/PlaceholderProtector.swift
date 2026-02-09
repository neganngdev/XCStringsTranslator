//
//  PlaceholderProtector.swift
//  XCStringsTranslator
//
//  Utility to protect format specifiers from being translated
//

import Foundation

/// Protects format specifiers by replacing them with tokens before translation
/// and restores them after translation is complete
struct PlaceholderProtector {
    
    /// Token format used to replace placeholders
    private static let tokenFormat = "<<<PH%d>>>"
    
    /// Regex patterns for various placeholder types
    private static let patterns: [String] = [
        // Positional specifiers: %1$@, %2$lld, etc.
        #"%\d+\$[@dDuUxXoOfFeEgGcCsSaAp]"#,
        #"%\d+\$[lh]*[ldiuoxXfeEgGaA]+"#,
        
        // Standard specifiers: %@, %d, %ld, %lld, etc.
        #"%[@dDuUxXoOfFeEgGcCsSaAp]"#,
        #"%[lh]*[ldiuoxXfeEgGaA]+"#,
        
        // Named placeholders: {count}, {name}, {value}, etc.
        #"\{[^}]+\}"#,
        
        // Escape sequences: \n, \t, \r
        #"\\[ntr]"#,
        
        // Percent sign placeholder: %%
        #"%%"#
    ]
    
    /// Combined regex pattern matching all placeholder types
    private static var combinedPattern: String {
        patterns.joined(separator: "|")
    }
    
    /// Result of protecting placeholders in a string
    struct ProtectionResult {
        /// String with placeholders replaced by tokens
        let protected: String
        
        /// Original placeholders in order
        let placeholders: [String]
    }
    
    /// Protects placeholders by replacing them with tokens
    /// - Parameter text: Original text with format specifiers
    /// - Returns: Protected string and list of original placeholders
    ///
    /// Example:
    /// ```
    /// Input:  "%1$lld / %2$lld tabs"
    /// Output: ("<<<PH0>>> / <<<PH1>>> tabs", ["%1$lld", "%2$lld"])
    /// ```
    static func protect(_ text: String) -> ProtectionResult {
        guard let regex = try? NSRegularExpression(pattern: combinedPattern) else {
            return ProtectionResult(protected: text, placeholders: [])
        }
        
        var result = text
        var placeholders: [String] = []
        
        // Find all matches
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        
        // Process matches in reverse order to preserve indices
        for match in matches.reversed() {
            guard let swiftRange = Range(match.range, in: result) else { continue }
            
            let placeholder = String(result[swiftRange])
            
            // Insert at the beginning since we're going in reverse
            placeholders.insert(placeholder, at: 0)
            
            // Replace with token (index will be count - 1 when going in reverse)
            let tokenIndex = placeholders.count - 1
            let token = String(format: tokenFormat, tokenIndex)
            result.replaceSubrange(swiftRange, with: token)
        }
        
        return ProtectionResult(protected: result, placeholders: placeholders)
    }
    
    /// Restores placeholders after translation
    /// - Parameters:
    ///   - text: Translated text with tokens
    ///   - placeholders: Original placeholders to restore
    /// - Returns: Text with original placeholders restored
    ///
    /// Example:
    /// ```
    /// Input:  ("<<<PH0>>> / <<<PH1>>> thẻ", ["%1$lld", "%2$lld"])
    /// Output: "%1$lld / %2$lld thẻ"
    /// ```
    static func restore(_ text: String, placeholders: [String]) -> String {
        var result = text
        
        for (index, placeholder) in placeholders.enumerated() {
            let token = String(format: tokenFormat, index)
            result = result.replacingOccurrences(of: token, with: placeholder)
        }
        
        return result
    }
}
