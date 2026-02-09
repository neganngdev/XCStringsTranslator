//
//  StringEntry.swift
//  XCStringsTranslator
//
//  String entry with localizations and metadata
//

import Foundation

/// Represents a single translatable string with all its localizations
struct StringEntry: Codable {
    /// Optional comment providing context for translators
    var comment: String?
    
    /// Extraction state from Xcode (e.g., "manual", "extracted_with_value")
    var extractionState: String?
    
    /// All localizations keyed by language code
    var localizations: [String: Localization]?
    
    /// Whether this string should be translated
    /// Check comment for "do not translate" or similar markers
    var shouldTranslate: Bool {
        guard let comment = comment?.lowercased() else { return true }
        return !comment.contains("do not translate") &&
               !comment.contains("don't translate") &&
               !comment.contains("no translate")
    }
}
