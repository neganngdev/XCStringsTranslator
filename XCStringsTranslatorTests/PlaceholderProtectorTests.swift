//
//  PlaceholderProtectorTests.swift
//  XCStringsTranslatorTests
//
//  Unit tests for PlaceholderProtector
//

import XCTest
@testable import XCStringsTranslator

final class PlaceholderProtectorTests: XCTestCase {
    
    // MARK: - Basic Placeholder Tests
    
    func testSimpleStringPlaceholder() {
        let input = "Hello %@"
        let result = PlaceholderProtector.protect(input)
        
        XCTAssertEqual(result.placeholders, ["%@"])
        XCTAssertEqual(result.protected, "Hello <<<PH0>>>")
        
        let restored = PlaceholderProtector.restore(result.protected, placeholders: result.placeholders)
        XCTAssertEqual(restored, input)
    }
    
    func testIntegerPlaceholder() {
        let input = "You have %d items"
        let result = PlaceholderProtector.protect(input)
        
        XCTAssertEqual(result.placeholders, ["%d"])
        XCTAssertEqual(result.protected, "You have <<<PH0>>> items")
        
        let restored = PlaceholderProtector.restore(result.protected, placeholders: result.placeholders)
        XCTAssertEqual(restored, input)
    }
    
    func testLongIntegerPlaceholder() {
        let input = "You have %lld items"
        let result = PlaceholderProtector.protect(input)
        
        XCTAssertEqual(result.placeholders, ["%lld"])
        XCTAssertEqual(result.protected, "You have <<<PH0>>> items")
        
        let restored = PlaceholderProtector.restore(result.protected, placeholders: result.placeholders)
        XCTAssertEqual(restored, input)
    }
    
    // MARK: - Positional Placeholder Tests
    
    func testPositionalPlaceholders() {
        let input = "%1$lld / %2$lld tabs"
        let result = PlaceholderProtector.protect(input)
        
        XCTAssertEqual(result.placeholders.count, 2)
        XCTAssertTrue(result.placeholders.contains("%1$lld"))
        XCTAssertTrue(result.placeholders.contains("%2$lld"))
        XCTAssertEqual(result.protected, "<<<PH0>>> / <<<PH1>>> tabs")
        
        let restored = PlaceholderProtector.restore(result.protected, placeholders: result.placeholders)
        XCTAssertEqual(restored, input)
    }
    
    func testMixedPositionalPlaceholders() {
        let input = "Hello %1$@, you have %2$d items"
        let result = PlaceholderProtector.protect(input)
        
        XCTAssertEqual(result.placeholders.count, 2)
        
        let restored = PlaceholderProtector.restore(result.protected, placeholders: result.placeholders)
        XCTAssertEqual(restored, input)
    }
    
    // MARK: - Named Placeholder Tests
    
    func testNamedPlaceholder() {
        let input = "Hello {name}"
        let result = PlaceholderProtector.protect(input)
        
        XCTAssertEqual(result.placeholders, ["{name}"])
        XCTAssertEqual(result.protected, "Hello <<<PH0>>>")
        
        let restored = PlaceholderProtector.restore(result.protected, placeholders: result.placeholders)
        XCTAssertEqual(restored, input)
    }
    
    func testMultipleNamedPlaceholders() {
        let input = "Hello {firstName} {lastName}, you have {count} items"
        let result = PlaceholderProtector.protect(input)
        
        XCTAssertEqual(result.placeholders.count, 3)
        XCTAssertTrue(result.placeholders.contains("{firstName}"))
        XCTAssertTrue(result.placeholders.contains("{lastName}"))
        XCTAssertTrue(result.placeholders.contains("{count}"))
        
        let restored = PlaceholderProtector.restore(result.protected, placeholders: result.placeholders)
        XCTAssertEqual(restored, input)
    }
    
    // MARK: - Escape Sequence Tests
    
    func testNewlineEscape() {
        let input = "Line 1\\nLine 2"
        let result = PlaceholderProtector.protect(input)
        
        XCTAssertEqual(result.placeholders, ["\\n"])
        
        let restored = PlaceholderProtector.restore(result.protected, placeholders: result.placeholders)
        XCTAssertEqual(restored, input)
    }
    
    func testTabEscape() {
        let input = "Column 1\\tColumn 2"
        let result = PlaceholderProtector.protect(input)
        
        XCTAssertEqual(result.placeholders, ["\\t"])
        
        let restored = PlaceholderProtector.restore(result.protected, placeholders: result.placeholders)
        XCTAssertEqual(restored, input)
    }
    
    // MARK: - Edge Cases
    
    func testNoPlaceholders() {
        let input = "Hello world"
        let result = PlaceholderProtector.protect(input)
        
        XCTAssertEqual(result.placeholders, [])
        XCTAssertEqual(result.protected, input)
        
        let restored = PlaceholderProtector.restore(result.protected, placeholders: result.placeholders)
        XCTAssertEqual(restored, input)
    }
    
    func testEmptyString() {
        let input = ""
        let result = PlaceholderProtector.protect(input)
        
        XCTAssertEqual(result.placeholders, [])
        XCTAssertEqual(result.protected, "")
        
        let restored = PlaceholderProtector.restore(result.protected, placeholders: result.placeholders)
        XCTAssertEqual(restored, input)
    }
    
    func testPercentEscape() {
        let input = "50%% off"
        let result = PlaceholderProtector.protect(input)
        
        XCTAssertEqual(result.placeholders, ["%%"])
        
        let restored = PlaceholderProtector.restore(result.protected, placeholders: result.placeholders)
        XCTAssertEqual(restored, input)
    }
    
    // MARK: - Complex Cases
    
    func testComplexMixedPlaceholders() {
        let input = "Hello %1$@,\\nYou have %2$lld items in {folder}"
        let result = PlaceholderProtector.protect(input)
        
        XCTAssertEqual(result.placeholders.count, 4)
        
        let restored = PlaceholderProtector.restore(result.protected, placeholders: result.placeholders)
        XCTAssertEqual(restored, input)
    }
    
    func testFloatPlaceholder() {
        let input = "Price: $%0.2f"
        let result = PlaceholderProtector.protect(input)
        
        // The float placeholder should be protected
        XCTAssertFalse(result.protected.contains("%"))
        
        let restored = PlaceholderProtector.restore(result.protected, placeholders: result.placeholders)
        XCTAssertEqual(restored, input)
    }
}
