//
//  SkipCheckerTests.swift
//  XCStringsTranslatorTests
//
//  Unit tests for SkipChecker
//

import XCTest
@testable import XCStringsTranslator

final class SkipCheckerTests: XCTestCase {
    
    // MARK: - Test Data
    
    private func makeEntry(
        sourceValue: String,
        targetValue: String? = nil,
        comment: String? = nil
    ) -> StringEntry {
        var localizations: [String: Localization] = [
            "en": Localization(stringUnit: StringUnit(state: "translated", value: sourceValue))
        ]
        
        if let targetValue = targetValue {
            localizations["vi"] = Localization(stringUnit: StringUnit(state: "translated", value: targetValue))
        }
        
        return StringEntry(
            comment: comment,
            extractionState: nil,
            localizations: localizations
        )
    }
    
    // MARK: - Already Translated Tests
    
    func testSkipsAlreadyTranslated() {
        let entry = makeEntry(sourceValue: "Hello", targetValue: "Xin chào")
        let options = SkipOptions(skipAlreadyTranslated: true, skipShouldTranslateFalse: true)
        
        let result = SkipChecker.shouldSkip(
            entry: entry,
            sourceLanguage: "en",
            targetLanguage: "vi",
            options: options
        )
        
        XCTAssertTrue(result.shouldSkip)
        XCTAssertEqual(result.reason, .alreadyTranslated)
    }
    
    func testDoesNotSkipWhenSameAsSource() {
        let entry = makeEntry(sourceValue: "Hello", targetValue: "Hello")
        let options = SkipOptions(skipAlreadyTranslated: true, skipShouldTranslateFalse: true)
        
        let result = SkipChecker.shouldSkip(
            entry: entry,
            sourceLanguage: "en",
            targetLanguage: "vi",
            options: options
        )
        
        XCTAssertFalse(result.shouldSkip)
        XCTAssertNil(result.reason)
    }
    
    func testDoesNotSkipWhenNoTargetValue() {
        let entry = makeEntry(sourceValue: "Hello", targetValue: nil)
        let options = SkipOptions(skipAlreadyTranslated: true, skipShouldTranslateFalse: true)
        
        let result = SkipChecker.shouldSkip(
            entry: entry,
            sourceLanguage: "en",
            targetLanguage: "vi",
            options: options
        )
        
        XCTAssertFalse(result.shouldSkip)
        XCTAssertNil(result.reason)
    }
    
    // MARK: - Should Translate False Tests
    
    func testSkipsShouldTranslateFalse() {
        let entry = makeEntry(sourceValue: "MyBrandName", comment: "Do not translate - brand name")
        let options = SkipOptions(skipAlreadyTranslated: true, skipShouldTranslateFalse: true)
        
        let result = SkipChecker.shouldSkip(
            entry: entry,
            sourceLanguage: "en",
            targetLanguage: "vi",
            options: options
        )
        
        XCTAssertTrue(result.shouldSkip)
        XCTAssertEqual(result.reason, .shouldTranslateFalse)
    }
    
    // MARK: - Options Tests
    
    func testRespectsSkipAlreadyTranslatedOption() {
        let entry = makeEntry(sourceValue: "Hello", targetValue: "Xin chào")
        let options = SkipOptions(skipAlreadyTranslated: false, skipShouldTranslateFalse: true)
        
        let result = SkipChecker.shouldSkip(
            entry: entry,
            sourceLanguage: "en",
            targetLanguage: "vi",
            options: options
        )
        
        // Should NOT skip because option is false
        XCTAssertFalse(result.shouldSkip)
    }
    
    func testRespectsSkipShouldTranslateFalseOption() {
        let entry = makeEntry(sourceValue: "MyBrandName", comment: "Do not translate")
        let options = SkipOptions(skipAlreadyTranslated: true, skipShouldTranslateFalse: false)
        
        let result = SkipChecker.shouldSkip(
            entry: entry,
            sourceLanguage: "en",
            targetLanguage: "vi",
            options: options
        )
        
        // Should NOT skip because option is false
        XCTAssertFalse(result.shouldSkip)
    }
    
    // MARK: - Empty Source Tests
    
    func testSkipsEmptySource() {
        let entry = makeEntry(sourceValue: "")
        let options = SkipOptions(skipAlreadyTranslated: true, skipShouldTranslateFalse: true)
        
        let result = SkipChecker.shouldSkip(
            entry: entry,
            sourceLanguage: "en",
            targetLanguage: "vi",
            options: options
        )
        
        XCTAssertTrue(result.shouldSkip)
        XCTAssertEqual(result.reason, .emptySource)
    }
}
