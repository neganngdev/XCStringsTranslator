//
//  FileAnalysis.swift
//  XCStringsTranslator
//
//  Analysis results for loaded xcstrings files
//

import Foundation

/// Results from analyzing an xcstrings file
struct FileAnalysis {
    /// Total number of unique string keys
    let totalStrings: Int
    
    /// All available language codes found in the file
    let availableLanguages: [String]
    
    /// Count of strings already translated (value differs from source)
    let alreadyTranslated: Int
    
    /// Count of strings marked as "do not translate"
    let shouldNotTranslate: Int
    
    /// Count of strings still needing translation
    var needsTranslation: Int {
        let perLanguage = totalStrings - shouldNotTranslate
        let targetLanguages = availableLanguages.count - 1 // Exclude source
        return max(0, (perLanguage * targetLanguages) - alreadyTranslated)
    }
    
    /// Source language code
    let sourceLanguage: String
}
