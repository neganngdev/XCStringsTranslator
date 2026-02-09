//
//  XCStringsDocument.swift
//  XCStringsTranslator
//
//  Codable struct matching .xcstrings JSON format
//

import Foundation

/// Root document structure for .xcstrings files
struct XCStringsDocument: Codable {
    /// Source language code (e.g., "en")
    let sourceLanguage: String
    
    /// All translatable strings keyed by their identifier
    var strings: [String: StringEntry]
    
    /// File format version (e.g., "1.0")
    let version: String
}
