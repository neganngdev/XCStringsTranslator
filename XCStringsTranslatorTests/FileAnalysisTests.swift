//
//  FileAnalysisTests.swift
//  XCStringsTranslatorTests
//
//  Tests for file analysis logic
//

import XCTest
@testable import XCStringsTranslator

final class FileAnalysisTests: XCTestCase {
    
    // MARK: - Test Data
    
    private func makeDocument(strings: [String: StringEntry]) -> XCStringsDocument {
        return XCStringsDocument(
            sourceLanguage: "en",
            strings: strings,
            version: "1.0"
        )
    }
    
    private func makeEntry(
        sourceValue: String,
        translations: [String: String] = [:],
        comment: String? = nil
    ) -> StringEntry {
        var localizations: [String: Localization] = [
            "en": Localization(stringUnit: StringUnit(state: "translated", value: sourceValue))
        ]
        
        for (lang, value) in translations {
            localizations[lang] = Localization(stringUnit: StringUnit(state: "translated", value: value))
        }
        
        return StringEntry(
            comment: comment,
            extractionState: nil,
            localizations: localizations
        )
    }
    
    // MARK: - Tests
    
    func testCountsTotalStrings() {
        let doc = makeDocument(strings: [
            "key1": makeEntry(sourceValue: "Value 1"),
            "key2": makeEntry(sourceValue: "Value 2"),
            "key3": makeEntry(sourceValue: "Value 3")
        ])
        
        let analysis = FileAnalysis(
            totalStrings: doc.strings.count,
            availableLanguages: ["en"],
            alreadyTranslated: 0,
            shouldNotTranslate: 0,
            sourceLanguage: "en"
        )
        
        XCTAssertEqual(analysis.totalStrings, 3)
    }
    
    func testCalculatesNeedsTranslation() {
        let analysis = FileAnalysis(
            totalStrings: 100,
            availableLanguages: ["en", "vi"],
            alreadyTranslated: 30,
            shouldNotTranslate: 10,
            sourceLanguage: "en"
        )
        
        // 100 - 30 - 10 = 60
        XCTAssertEqual(analysis.needsTranslation, 60)
    }
    
    func testShouldTranslateProperty() {
        let normalEntry = makeEntry(sourceValue: "Hello")
        XCTAssertTrue(normalEntry.shouldTranslate)
        
        let noTranslateEntry = makeEntry(sourceValue: "Brand", comment: "do not translate")
        XCTAssertFalse(noTranslateEntry.shouldTranslate)
        
        let noTranslateEntry2 = makeEntry(sourceValue: "Brand", comment: "Don't translate this")
        XCTAssertFalse(noTranslateEntry2.shouldTranslate)
        
        let noTranslateEntry3 = makeEntry(sourceValue: "Brand", comment: "No translate needed")
        XCTAssertFalse(noTranslateEntry3.shouldTranslate)
    }
}
