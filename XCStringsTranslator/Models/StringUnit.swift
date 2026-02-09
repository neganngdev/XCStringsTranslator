//
//  StringUnit.swift
//  XCStringsTranslator
//
//  State and value container for translations
//

import Foundation

/// Contains the translation state and actual text value
struct StringUnit: Codable {
    /// Translation state: "translated", "new", "needs_review", etc.
    var state: String
    
    /// The actual translated text value
    var value: String
}
