//
//  Localization.swift
//  XCStringsTranslator
//
//  Localization wrapper for StringUnit
//

import Foundation

/// Wrapper containing the actual string unit for a localization
struct Localization: Codable {
    /// The string unit containing state and value
    var stringUnit: StringUnit?
}
