//
//  TranslationProgress.swift
//  XCStringsTranslator
//
//  Progress tracking for translation operations
//

import Foundation

/// Current progress of a translation operation
struct TranslationProgress {
    /// Number of strings processed so far
    let current: Int
    
    /// Total number of strings to process
    let total: Int
    
    /// Current string key being processed
    let currentKey: String
    
    /// Current target language being processed
    let currentLanguage: String
    
    /// Action taken on this string
    let action: Action
    
    /// Percentage complete (0-100)
    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total) * 100
    }
    
    /// Action taken on a string
    enum Action: String {
        case translated = "Translated"
        case skipped = "Skipped"
        case failed = "Failed"
    }
}

/// Statistics from a completed translation operation
struct TranslationStats {
    /// Number of strings successfully translated
    var translated: Int = 0
    
    /// Number of strings skipped
    var skipped: Int = 0
    
    /// Number of strings that failed to translate
    var failed: Int = 0
    
    /// Count of skip reasons
    var skipReasons: [String: Int] = [:]
    
    /// Error messages for failed translations
    var errors: [String] = []
    
    /// Total strings processed
    var total: Int {
        translated + skipped + failed
    }
    
    /// Formatted summary of the translation operation
    var summary: String {
        var lines: [String] = [
            "📊 Translation Complete",
            "",
            "✅ Translated: \(translated)",
            "⏭️  Skipped: \(skipped)"
        ]
        
        // Add skip reason breakdown
        for (reason, count) in skipReasons.sorted(by: { $0.key < $1.key }) {
            lines.append("   • \(reason): \(count)")
        }
        
        lines.append("❌ Failed: \(failed)")
        
        // Add error summary if any
        if !errors.isEmpty {
            lines.append("")
            lines.append("Errors (first 5):")
            for error in errors.prefix(5) {
                lines.append("  • \(error)")
            }
            if errors.count > 5 {
                lines.append("  ... and \(errors.count - 5) more")
            }
        }
        
        return lines.joined(separator: "\n")
    }
}
