//
//  TranslationServiceTests.swift
//  XCStringsTranslatorTests
//
//  Integration tests for translation service
//

import XCTest
@testable import XCStringsTranslator

final class TranslationServiceTests: XCTestCase {
    
    var mockProvider: MockTranslationProvider!
    var service: TranslationService!
    
    override func setUp() {
        super.setUp()
        mockProvider = MockTranslationProvider()
        service = TranslationService(provider: mockProvider)
    }
    
    override func tearDown() {
        mockProvider = nil
        service = nil
        super.tearDown()
    }
    
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
    
    // MARK: - Integration Tests
    
    func testTranslatesStringsToTargetLanguages() async throws {
        let doc = makeDocument(strings: [
            "hello": makeEntry(sourceValue: "Hello"),
            "goodbye": makeEntry(sourceValue: "Goodbye")
        ])
        
        var progressUpdates: [TranslationProgress] = []
        
        let result = try await service.translateDocument(
            doc,
            targetLanguages: ["vi", "es"],
            skipOptions: SkipOptions(skipAlreadyTranslated: false, skipShouldTranslateFalse: true)
        ) { progress in
            progressUpdates.append(progress)
        }
        
        // Verify translations were made
        XCTAssertEqual(mockProvider.translationCount, 4) // 2 strings × 2 languages
        
        // Verify stats
        XCTAssertEqual(result.stats.translated, 4)
        XCTAssertEqual(result.stats.skipped, 0)
        XCTAssertEqual(result.stats.failed, 0)
        
        // Verify progress updates
        XCTAssertEqual(progressUpdates.count, 4)
    }
    
    func testSkipsAlreadyTranslatedStrings() async throws {
        let doc = makeDocument(strings: [
            "hello": makeEntry(sourceValue: "Hello", translations: ["vi": "Xin chào"])
        ])
        
        let result = try await service.translateDocument(
            doc,
            targetLanguages: ["vi"],
            skipOptions: SkipOptions(skipAlreadyTranslated: true, skipShouldTranslateFalse: true)
        ) { _ in }
        
        // Should skip already translated
        XCTAssertEqual(mockProvider.translationCount, 0)
        XCTAssertEqual(result.stats.skipped, 1)
        XCTAssertEqual(result.stats.skipReasons["Already translated"], 1)
    }
    
    func testSkipsNoTranslateStrings() async throws {
        let doc = makeDocument(strings: [
            "brand": makeEntry(sourceValue: "MyBrand", comment: "Do not translate")
        ])
        
        let result = try await service.translateDocument(
            doc,
            targetLanguages: ["vi"],
            skipOptions: SkipOptions(skipAlreadyTranslated: true, skipShouldTranslateFalse: true)
        ) { _ in }
        
        // Should skip "do not translate"
        XCTAssertEqual(mockProvider.translationCount, 0)
        XCTAssertEqual(result.stats.skipped, 1)
        XCTAssertEqual(result.stats.skipReasons["Marked do not translate"], 1)
    }
    
    func testHandlesProviderErrors() async throws {
        mockProvider.shouldFail = true
        mockProvider.errorToThrow = .networkError
        
        let doc = makeDocument(strings: [
            "hello": makeEntry(sourceValue: "Hello")
        ])
        
        let result = try await service.translateDocument(
            doc,
            targetLanguages: ["vi"],
            skipOptions: SkipOptions()
        ) { _ in }
        
        // Should record failure
        XCTAssertEqual(result.stats.failed, 1)
        XCTAssertEqual(result.stats.errors.count, 1)
    }
    
    func testPreservesPlaceholders() async throws {
        let doc = makeDocument(strings: [
            "count": makeEntry(sourceValue: "%lld items remaining")
        ])
        
        let result = try await service.translateDocument(
            doc,
            targetLanguages: ["vi"],
            skipOptions: SkipOptions()
        ) { _ in }
        
        // Verify placeholder was in the text sent to provider (protected form)
        let translation = mockProvider.translations.first
        XCTAssertNotNil(translation)
        XCTAssertTrue(translation!.text.contains("<<<PH"))
    }
}
