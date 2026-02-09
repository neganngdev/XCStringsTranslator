# XCStringsTranslator

## 📌 Table of Contents
- [Project Goal](#-project-goal)
- [Core Features](#-core-features)
- [Technical Architecture](#-technical-architecture)
- [User Flow](#-user-flow)
- [Core Components](#-core-components)
- [Translation Providers](#-translation-providers)
- [Smart Skip Logic](#-smart-skip-logic)
- [UI Design](#-ui-design)
- [Build Prompts](#-build-prompts)
- [Development Timeline](#-development-timeline)
- [Provider Comparison](#-provider-comparison)
- [Success Metrics](#-success-metrics)
- [File Structure](#-file-structure)

---

## 🎯 Project Goal

A simple macOS app that translates `.xcstrings` localization files using multiple AI providers (Apple Translation, Gemini, DeepLX), with smart skipping logic for already-translated strings and custom exclusions.

**Target Users:** Indie iOS/macOS developers shipping apps with 12+ languages

**Problem Solved:** Manual translation is slow and expensive. Existing services cost $10-20 per app. This tool is FREE or costs < $1 per app.

---

## 📋 Core Features

### Must-Have (MVP)
- ✅ Load `.xcstrings` files via drag & drop
- ✅ Auto-detect source language from file
- ✅ **Multiple translation providers:**
  - Apple Translation (FREE, on-device, no API key needed)
  - Google Gemini API (cheap ~$0.50/app, high quality)
  - DeepLX (FREE if self-hosted)
- ✅ **Smart skip logic:**
  - Skip if string already translated (value ≠ source)
  - Skip if marked `shouldTranslate: false`
- ✅ Translate to all/selected languages with one click
- ✅ Preserve format specifiers (`%@`, `%1$lld`, `{count}`)
- ✅ Show real-time translation progress with stats
- ✅ Save translated file

### Nice-to-Have (Optional)
- ⭐ Cost estimation per provider before running
- ⭐ Translation memory (cache results for reuse)
- ⭐ Export translation report as CSV
- ⭐ Batch process multiple files

---

## 🏗️ Technical Architecture

### Platform & Tools
- **Language:** Swift 5.9+
- **Framework:** SwiftUI
- **Minimum Platform:** macOS 14.0+
- **APIs:** 
  - Apple Translation framework (built-in)
  - Google Gemini REST API
  - DeepLX REST API (local/remote)

### Design Pattern
- **MVVM** (Model-View-ViewModel)
- **Protocol-Oriented** for translation providers
- **Async/Await** for all network operations
- **Codable** for JSON parsing

---

## 🔄 User Flow

```
1. Launch app
   ↓
2. Drag & drop .xcstrings file
   ↓
3. App analyzes and shows:
   ┌─────────────────────────────────┐
   │ Source: en                      │
   │ Total strings: 380              │
   │ Languages: 15                   │
   │ Already translated: 0           │
   │ Marked shouldTranslate:false: 0 │
   │ Need translation: 5,700         │
   └─────────────────────────────────┘
   ↓
4. User selects:
   - Provider: [Apple / Gemini / DeepLX]
   - API key (if Gemini selected)
   - Target languages (or "Select All")
   - Skip options:
     ☑ Skip already translated
     ☑ Skip shouldTranslate:false
   ↓
5. App shows cost estimate (if applicable):
   "Estimated cost: $0.50 with Gemini"
   ↓
6. User clicks "Translate" button
   ↓
7. App processes with real-time updates:
   ┌─────────────────────────────────────┐
   │ Progress: 45% (2,565/5,700)         │
   │ Current: account.pro_plan → vi      │
   │ Estimated: 12 min remaining         │
   │                                     │
   │ Stats:                              │
   │ ✅ Translated: 2,300                │
   │ ⏭️  Skipped: 265                    │
   │    - Already done: 215              │
   │    - shouldTranslate:false: 50      │
   │ ❌ Failed: 0                         │
   └─────────────────────────────────────┘
   ↓
8. Translation completes
   ↓
9. App auto-saves:
   "Localizable_translated.xcstrings"
   ↓
10. User imports into Xcode project
```

---

## 🧩 Core Components

### 1. Data Models

#### XCStringsDocument
```swift
struct XCStringsDocument: Codable {
    let sourceLanguage: String              // "en"
    var strings: [String: StringEntry]      // All translatable strings
    let version: String                     // "1.0"
}
```

#### StringEntry
```swift
struct StringEntry: Codable {
    let comment: String?                    // Context for translators
    var localizations: [String: Localization]
    
    // Custom metadata for skip logic
    var shouldTranslate: Bool? {
        get { metadata?["shouldTranslate"] as? Bool }
        set { 
            if metadata == nil { metadata = [:] }
            metadata?["shouldTranslate"] = newValue
        }
    }
    private var metadata: [String: Any]?
}
```

#### Localization
```swift
struct Localization: Codable {
    var stringUnit: StringUnit
}

struct StringUnit: Codable {
    let state: String                       // "translated"
    var value: String                       // The actual text
}
```

### 2. PlaceholderProtector

Protects format specifiers from being translated.

```swift
struct PlaceholderProtector {
    /// Protects placeholders by replacing with tokens
    /// Input:  "%1$lld / %2$lld tabs"
    /// Output: ("<<<PH0>>> / <<<PH1>>> tabs", ["%1$lld", "%2$lld"])
    static func protect(_ text: String) -> (protected: String, placeholders: [String]) {
        var result = text
        var placeholders: [String] = []
        
        // Regex patterns for various placeholder types
        let patterns = [
            #"%(\d+\$)?[@dDuUxXoOfFeEgGcCsSaAp]"#,  // %@, %d, %1$lld
            #"%(\d+\$)?[lh]*[ldiuoxX]+"#,             // %lld, %ld
            #"\{[^}]+\}"#,                             // {count}, {name}
            #"\\[ntr]"#                                // \n, \t, \r
        ]
        
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            
            for match in matches.reversed() {
                guard let range = Range(match.range, in: result) else { continue }
                let placeholder = String(result[range])
                let token = "<<<PH\(placeholders.count)>>>"
                placeholders.append(placeholder)
                result.replaceSubrange(range, with: token)
            }
        }
        
        return (result, placeholders)
    }
    
    /// Restores placeholders after translation
    /// Input:  ("<<<PH0>>> / <<<PH1>>> thẻ", ["%1$lld", "%2$lld"])
    /// Output: "%1$lld / %2$lld thẻ"
    static func restore(_ text: String, placeholders: [String]) -> String {
        var result = text
        for (index, placeholder) in placeholders.enumerated() {
            result = result.replacingOccurrences(of: "<<<PH\(index)>>>", with: placeholder)
        }
        return result
    }
}
```

### 3. SkipChecker

Smart logic to determine which strings to skip.

```swift
struct SkipChecker {
    struct SkipOptions {
        var skipAlreadyTranslated: Bool = true
        var skipShouldTranslateFalse: Bool = true
    }
    
    enum SkipReason: String {
        case alreadyTranslated = "already translated"
        case shouldTranslateFalse = "shouldTranslate: false"
    }
    
    static func shouldSkip(
        entry: StringEntry,
        sourceLanguage: String,
        targetLanguage: String,
        options: SkipOptions
    ) -> (skip: Bool, reason: SkipReason?) {
        
        // Check shouldTranslate flag
        if options.skipShouldTranslateFalse {
            if let shouldTranslate = entry.shouldTranslate, !shouldTranslate {
                return (true, .shouldTranslateFalse)
            }
        }
        
        // Check if already translated
        if options.skipAlreadyTranslated {
            guard let sourceValue = entry.localizations[sourceLanguage]?.stringUnit.value,
                  let targetValue = entry.localizations[targetLanguage]?.stringUnit.value else {
                return (false, nil)
            }
            
            // If values are different, it's already translated
            if sourceValue != targetValue {
                return (true, .alreadyTranslated)
            }
        }
        
        return (false, nil)
    }
}
```

### 4. TranslationService

Main engine that orchestrates the translation process.

```swift
class TranslationService {
    let provider: TranslationProvider
    
    init(provider: TranslationProvider) {
        self.provider = provider
    }
    
    func translateDocument(
        _ document: XCStringsDocument,
        targetLanguages: [String],
        skipOptions: SkipChecker.SkipOptions,
        onProgress: @escaping (TranslationProgress) -> Void
    ) async throws -> (document: XCStringsDocument, stats: TranslationStats) {
        
        var updatedDoc = document
        var stats = TranslationStats()
        
        let sourceLanguage = document.sourceLanguage
        let totalStrings = document.strings.count * targetLanguages.count
        var processedCount = 0
        
        for (stringKey, var entry) in document.strings {
            guard let sourceValue = entry.localizations[sourceLanguage]?.stringUnit.value else {
                continue
            }
            
            for targetLang in targetLanguages {
                // Check if should skip
                let skipResult = SkipChecker.shouldSkip(
                    entry: entry,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLang,
                    options: skipOptions
                )
                
                if skipResult.skip {
                    stats.skipped += 1
                    if let reason = skipResult.reason {
                        stats.skipReasons[reason.rawValue, default: 0] += 1
                    }
                    processedCount += 1
                    
                    // Update progress even for skipped items
                    onProgress(TranslationProgress(
                        current: processedCount,
                        total: totalStrings,
                        currentKey: stringKey,
                        currentLanguage: targetLang,
                        action: .skipped
                    ))
                    continue
                }
                
                // Translate
                do {
                    let translated = try await provider.translate(
                        text: sourceValue,
                        from: sourceLanguage,
                        to: targetLang,
                        context: entry.comment
                    )
                    
                    entry.localizations[targetLang]?.stringUnit.value = translated
                    stats.translated += 1
                    
                    // Update progress
                    processedCount += 1
                    onProgress(TranslationProgress(
                        current: processedCount,
                        total: totalStrings,
                        currentKey: stringKey,
                        currentLanguage: targetLang,
                        action: .translated
                    ))
                    
                    // Small delay to respect rate limits
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                    
                } catch {
                    stats.failed += 1
                    stats.errors.append("\(stringKey) [\(targetLang)]: \(error.localizedDescription)")
                    processedCount += 1
                }
            }
            
            updatedDoc.strings[stringKey] = entry
        }
        
        return (updatedDoc, stats)
    }
}
```

### 5. Supporting Models

```swift
struct TranslationProgress {
    let current: Int
    let total: Int
    let currentKey: String
    let currentLanguage: String
    let action: Action
    
    enum Action {
        case translated
        case skipped
    }
    
    var percentage: Double {
        Double(current) / Double(total) * 100
    }
}

struct TranslationStats {
    var translated = 0
    var skipped = 0
    var failed = 0
    var skipReasons: [String: Int] = [:]
    var errors: [String] = []
    
    var summary: String {
        """
        📊 Translation Complete
        
        ✅ Translated: \(translated)
        ⏭️  Skipped: \(skipped)
           - Already translated: \(skipReasons["already translated"] ?? 0)
           - shouldTranslate: false: \(skipReasons["shouldTranslate: false"] ?? 0)
        ❌ Failed: \(failed)
        
        \(errors.isEmpty ? "" : "\nErrors:\n" + errors.prefix(10).joined(separator: "\n"))
        """
    }
}
```

---

## 🔌 Translation Providers

### TranslationProvider Protocol

```swift
protocol TranslationProvider {
    var name: String { get }
    var needsAPIKey: Bool { get }
    var supportedLanguages: Set<String> { get }
    var costPer1000Chars: Double { get }
    
    func translate(
        text: String,
        from: String,
        to: String,
        context: String?
    ) async throws -> String
}
```

### 1. Apple Translation Provider (FREE)

```swift
@available(macOS 14.0, *)
class AppleTranslationProvider: TranslationProvider {
    let name = "Apple Translation"
    let needsAPIKey = false
    let costPer1000Chars = 0.0  // FREE!
    
    let supportedLanguages: Set<String> = [
        "ar", "zh", "zh-Hans", "zh-Hant", "nl", "en", 
        "fr", "de", "id", "it", "ja", "ko", "pl", 
        "pt", "ru", "es", "th", "tr", "uk", "vi"
    ]
    
    func translate(
        text: String,
        from: String,
        to: String,
        context: String?
    ) async throws -> String {
        // Protect placeholders
        let (protected, placeholders) = PlaceholderProtector.protect(text)
        
        // Use Apple Translation API
        let configuration = TranslationSession.Configuration()
        let session = TranslationSession(configuration: configuration)
        
        let request = TranslationSession.Request(
            sourceLanguage: .init(identifier: from),
            targetLanguage: .init(identifier: to)
        )
        
        let response = try await session.translate(protected, request: request)
        
        // Restore placeholders
        return PlaceholderProtector.restore(response.targetText, placeholders: placeholders)
    }
}
```

**Pros:**
- ✅ Completely FREE
- ✅ On-device (privacy, no internet needed)
- ✅ Fast
- ✅ No API key required

**Cons:**
- ⚠️ Limited to supported languages only
- ⚠️ Good but not best quality for complex text

---

### 2. Google Gemini Provider (Cheap)

```swift
class GeminiProvider: TranslationProvider {
    let name = "Google Gemini"
    let needsAPIKey = true
    let costPer1000Chars = 0.00008  // ~$0.08 per 1M chars
    
    let supportedLanguages: Set<String> = [
        "en", "es", "de", "fr", "it", "ja", "ko", "nl", 
        "pl", "ro", "ru", "th", "tr", "uk", "vi", 
        "ar", "zh", "pt", "hi", "id", "ms"
    ]
    
    private let apiKey: String
    private let model = "gemini-2.0-flash-exp"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func translate(
        text: String,
        from: String,
        to: String,
        context: String?
    ) async throws -> String {
        // Protect placeholders
        let (protected, placeholders) = PlaceholderProtector.protect(text)
        
        // Build prompt
        let prompt = """
        Translate this text from \(from) to \(to).
        
        CRITICAL RULES:
        1. Preserve ALL tokens like <<<PH0>>>, <<<PH1>>> exactly as-is
        2. Output ONLY the translation, no explanations
        3. Keep the same tone and formality
        4. This is for a mobile app UI
        \(context.map { "5. Context: \($0)" } ?? "")
        
        Text: \(protected)
        """
        
        // Call Gemini API
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 1000
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TranslationError.apiError("Gemini API error")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let candidates = json["candidates"] as! [[String: Any]]
        let content = candidates[0]["content"] as! [String: Any]
        let parts = content["parts"] as! [[String: Any]]
        let translated = (parts[0]["text"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Restore placeholders
        return PlaceholderProtector.restore(translated, placeholders: placeholders)
    }
}
```

**Pros:**
- ✅ Very cheap (~$0.50 per app)
- ✅ Excellent quality
- ✅ Context-aware
- ✅ Supports many languages

**Cons:**
- ⚠️ Requires API key
- ⚠️ Requires internet
- ⚠️ Rate limits apply

**How to get API key:**
1. Go to https://aistudio.google.com/app/apikey
2. Create new API key
3. Copy and paste into app

---

### 3. DeepLX Provider (FREE, Self-hosted)

```swift
class DeepLXProvider: TranslationProvider {
    let name = "DeepLX"
    let needsAPIKey = false
    let costPer1000Chars = 0.0  // FREE if self-hosted
    
    let supportedLanguages: Set<String> = [
        "en", "de", "fr", "es", "pt", "it", "nl", 
        "pl", "ru", "ja", "zh", "ko"
    ]
    
    private let endpoint: String
    
    init(endpoint: String = "http://localhost:1188/translate") {
        self.endpoint = endpoint
    }
    
    func translate(
        text: String,
        from: String,
        to: String,
        context: String?
    ) async throws -> String {
        // Protect placeholders
        let (protected, placeholders) = PlaceholderProtector.protect(text)
        
        // Call DeepLX API
        let url = URL(string: endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "text": protected,
            "source_lang": from.uppercased(),
            "target_lang": to.uppercased()
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TranslationError.apiError("DeepLX error - is the service running?")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let translated = (json["data"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Restore placeholders
        return PlaceholderProtector.restore(translated, placeholders: placeholders)
    }
}
```

**Pros:**
- ✅ FREE if self-hosted
- ✅ Excellent quality (DeepL quality)
- ✅ No API key needed
- ✅ Privacy-focused (local)

**Cons:**
- ⚠️ Requires running local server
- ⚠️ Setup required

**How to run DeepLX:**
```bash
# Install via Docker
docker run -d -p 1188:1188 ghcr.io/OwO-Network/DeepLX:latest

# Or download binary
# https://github.com/OwO-Network/DeepLX/releases
./deeplx
```

---

### Error Handling

```swift
enum TranslationError: Error, LocalizedError {
    case unsupportedLanguage(String)
    case apiError(String)
    case notAvailable
    case invalidFile
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .unsupportedLanguage(let lang):
            return "Language '\(lang)' is not supported by this provider"
        case .apiError(let message):
            return message
        case .notAvailable:
            return "Translation framework not available on this macOS version"
        case .invalidFile:
            return "Invalid .xcstrings file format"
        case .networkError:
            return "Network error - check your internet connection"
        }
    }
}
```

---

## 🎯 Smart Skip Logic

The app intelligently skips strings that don't need translation:

### Skip Conditions

1. **Already Translated**
   - Check if `target_value != source_value`
   - Example: 
     - EN: "Free"
     - VI: "Miễn phí" ← Different, skip!

2. **Marked shouldTranslate: false**
   - Check metadata field
   - Example:
     ```json
     {
       "app.name": {
         "metadata": {
           "shouldTranslate": false
         },
         "localizations": {
           "en": { "value": "MyApp" }
         }
       }
     }
     ```

### How to Mark Strings as No-Translate

In your `.xcstrings` file, add metadata:

```json
{
  "sourceLanguage": "en",
  "strings": {
    "brand.name": {
      "comment": "App brand name - do not translate",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "MyBrandName"
          }
        }
      },
      "metadata": {
        "shouldTranslate": false
      }
    }
  }
}
```

Or programmatically:

```swift
var entry = document.strings["brand.name"]
entry?.shouldTranslate = false
document.strings["brand.name"] = entry
```

### Skip Statistics

The app tracks skip reasons:

```
📊 Translation Complete

✅ Translated: 5,200
⏭️  Skipped: 500
   - Already translated: 450
   - shouldTranslate: false: 50
❌ Failed: 0
```

---

## 🎨 UI Design

### Main Window Layout

```
┌────────────────────────────────────────────────────────┐
│  XCStrings Translator                               ×  │
├────────────────────────────────────────────────────────┤
│                                                        │
│   🌍  Drop .xcstrings file here                       │
│       or click to browse                              │
│                                                        │
├────────────────────────────────────────────────────────┤
│  📄 File Information                                   │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  File: Localizable.xcstrings                          │
│  Total: 380 strings                                    │
│  Source: English (en)                                  │
│  Languages: 15                                         │
│                                                        │
│  Status:                                               │
│  ✅ Already translated: 0 strings                     │
│  ⚠️  Marked no-translate: 0 strings                   │
│  🎯 Need translation: 5,700 strings                   │
│                                                        │
├────────────────────────────────────────────────────────┤
│  🔧 Translation Provider                               │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                        │
│  ◉ Apple Translation                                  │
│     ✓ FREE  ✓ On-device  ✓ No setup                  │
│                                                        │
│  ○ Google Gemini                                      │
│     💰 ~$0.50  ⭐ Best quality                        │
│     API Key: [••••••••••••••••••••]  [Get Key]        │
│                                                        │
│  ○ DeepLX                                             │
│     ✓ FREE  🔒 Privacy-focused                        │
│     Endpoint: [http://localhost:1188/translate]       │
│                                                        │
├────────────────────────────────────────────────────────┤
│  🌐 Target Languages                                   │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                        │
│  ☑ Spanish (es)     ☑ German (de)      ☑ French (fr) │
│  ☑ Italian (it)     ☑ Japanese (ja)    ☑ Korean (ko) │
│  ☑ Dutch (nl)       ☑ Polish (pl)      ☑ Romanian(ro)│
│  ☑ Russian (ru)     ☑ Thai (th)        ☑ Turkish (tr)│
│  ☑ Ukrainian (uk)   ☑ Vietnamese (vi)                │
│                                                        │
│  [Select All]  [Deselect All]  [Select by Region ▼]  │
│                                                        │
├────────────────────────────────────────────────────────┤
│  ⚙️  Options                                           │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                        │
│  ☑ Skip already translated strings                    │
│  ☑ Skip strings marked shouldTranslate: false         │
│  ☐ Overwrite all existing translations (force)        │
│                                                        │
├────────────────────────────────────────────────────────┤
│                                                        │
│  ┌──────────────────────────────────────────────────┐ │
│  │                                                  │ │
│  │         🚀  Translate 5,700 strings              │ │
│  │              Estimated: $0.00                    │ │
│  │                                                  │ │
│  └──────────────────────────────────────────────────┘ │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### During Translation

```
┌────────────────────────────────────────────────────────┐
│  XCStrings Translator                               ×  │
├────────────────────────────────────────────────────────┤
│                                                        │
│  🔄 Translating...                                     │
│                                                        │
│  Progress: ████████████░░░░░░░░ 45% (2,565/5,700)     │
│                                                        │
│  Current:  account.pro_plan → Vietnamese              │
│  Provider: Apple Translation                           │
│  Time:     00:12:34 elapsed                           │
│  Estimate: ~15 min remaining                          │
│                                                        │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                        │
│  📊 Live Statistics                                    │
│                                                        │
│  ✅ Translated:  2,300 strings                        │
│  ⏭️  Skipped:     265 strings                         │
│     • Already translated:    215                      │
│     • shouldTranslate:false:  50                      │
│  ❌ Failed:       0 strings                           │
│                                                        │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                        │
│                        [Cancel]                        │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### After Completion

```
┌────────────────────────────────────────────────────────┐
│  XCStrings Translator                               ×  │
├────────────────────────────────────────────────────────┤
│                                                        │
│  ✅ Translation Complete!                              │
│                                                        │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                        │
│  📊 Final Statistics                                   │
│                                                        │
│  ✅ Translated:  5,200 strings                        │
│  ⏭️  Skipped:     500 strings                         │
│     • Already translated:    450                      │
│     • shouldTranslate:false:  50                      │
│  ❌ Failed:       0 strings                           │
│                                                        │
│  ⏱️  Total time: 18 min 42 sec                        │
│  💰 Total cost:  $0.00 (Apple Translation)            │
│                                                        │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                        │
│  📁 Output File:                                       │
│  Localizable_translated.xcstrings                     │
│                                                        │
│  [Open in Finder]  [Open in Xcode]  [New Translation]│
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

## 📝 Build Prompts

### Phase 1: Project Setup & Models (Day 1)

```
Create a macOS SwiftUI app called "XCStrings Translator" with these requirements:

1. Project Setup:
   - macOS 14.0+ deployment target
   - SwiftUI App lifecycle
   - Enable sandbox for file access

2. Create Models folder with:

   a) XCStringsDocument.swift:
      - Codable struct matching .xcstrings JSON format
      - sourceLanguage: String
      - strings: [String: StringEntry]
      - version: String
   
   b) StringEntry.swift:
      - comment: String?
      - localizations: [String: Localization]
      - metadata: [String: Any]? (for custom fields)
      - Computed property shouldTranslate: Bool?
   
   c) Localization.swift:
      - stringUnit: StringUnit
   
   d) StringUnit.swift:
      - state: String
      - value: String

3. Create Views folder with:
   
   a) ContentView.swift - main window with:
      - File drop zone
      - File info display area
      - Provider selection area
      - Language selection area
      - Options checkboxes
      - Translate button
   
   b) FileDropZone.swift:
      - Accepts .xcstrings files
      - Shows drag state
      - Emits file URL on drop

4. Create ViewModels folder with:
   
   TranslatorViewModel.swift:
   - @Published var inputFile: URL?
   - @Published var document: XCStringsDocument?
   - func loadFile(_ url: URL)
   - func analyzeFile() -> FileAnalysis
   
   FileAnalysis struct:
   - totalStrings: Int
   - availableLanguages: [String]
   - alreadyTranslated: Int
   - shouldTranslateFalse: Int
   - needsTranslation: Int

Use MVVM pattern, make it clean and testable.
```

---

### Phase 2: Placeholder Protection (Day 1)

```
Create PlaceholderProtector.swift utility with:

1. Static function protect():
   - Input: String with format specifiers
   - Detect patterns:
     * %@, %d, %ld, %lld, %1$@, %2$lld, etc.
     * {count}, {name}, {value}, etc.
     * \n, \t, \r
   - Replace with tokens: <<<PH0>>>, <<<PH1>>>, etc.
   - Return: (protected: String, placeholders: [String])

2. Static function restore():
   - Input: translated string with tokens, original placeholders
   - Replace <<<PH0>>> with original placeholders
   - Return: String with placeholders restored

3. Add unit tests:
   - Test: "%1$lld / %2$lld tabs" → protection → restoration
   - Test: "Hello {name}\n" → protection → restoration
   - Test: Multiple placeholders in one string
   - Verify placeholders are preserved exactly

Use NSRegularExpression for pattern matching.
Make it robust - handle edge cases.
```

---

### Phase 3: Translation Providers (Day 2-3)

```
Create translation provider system:

1. Create TranslationProvider.swift protocol:
   - var name: String { get }
   - var needsAPIKey: Bool { get }
   - var supportedLanguages: Set<String> { get }
   - var costPer1000Chars: Double { get }
   - func translate(text:from:to:context:) async throws -> String

2. Create Providers folder with:

   a) AppleTranslationProvider.swift:
      - Use Translation framework (import Translation)
      - Implement for macOS 14.0+
      - Supported languages: ar, zh, nl, en, fr, de, id, it, ja, ko, pl, pt, ru, es, th, tr, uk, vi
      - In translate():
        1. Protect placeholders
        2. Create TranslationSession
        3. Translate with Request
        4. Restore placeholders
        5. Return result
      - Handle errors gracefully
      - Cost: $0.00

   b) GeminiProvider.swift:
      - API endpoint: generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent
      - Init with apiKey: String
      - Supported languages: en, es, de, fr, it, ja, ko, nl, pl, ro, ru, th, tr, uk, vi, ar, zh, pt, hi, id, ms
      - Build prompt that:
        * Instructs to preserve <<<PHN>>> tokens
        * Includes context if provided
        * Asks for translation only, no explanations
        * Sets temperature: 0.3
      - Parse JSON response
      - Cost: $0.00008 per 1000 chars
   
   c) DeepLXProvider.swift:
      - Default endpoint: http://localhost:1188/translate
      - POST with JSON: {text, source_lang, target_lang}
      - Supported languages: en, de, fr, es, pt, it, nl, pl, ru, ja, zh, ko
      - Parse response: {data: "translated text"}
      - Cost: $0.00

3. Create TranslationError.swift enum:
   - unsupportedLanguage(String)
   - apiError(String)
   - notAvailable
   - invalidFile
   - networkError
   - Conform to LocalizedError

All providers must protect/restore placeholders.
All must be async/await based.
All must handle errors with clear messages.
```

---

### Phase 4: Skip Logic (Day 3)

```
Create SkipChecker.swift with smart skip logic:

1. SkipOptions struct:
   - skipAlreadyTranslated: Bool = true
   - skipShouldTranslateFalse: Bool = true

2. SkipReason enum:
   - alreadyTranslated
   - shouldTranslateFalse

3. Static function shouldSkip():
   - Parameters:
     * entry: StringEntry
     * sourceLanguage: String
     * targetLanguage: String
     * options: SkipOptions
   
   - Logic:
     a) If options.skipShouldTranslateFalse && entry.shouldTranslate == false:
        → return (true, .shouldTranslateFalse)
     
     b) If options.skipAlreadyTranslated:
        - Get sourceValue and targetValue
        - If sourceValue != targetValue:
          → return (true, .alreadyTranslated)
     
     c) Otherwise:
        → return (false, nil)
   
   - Return: (skip: Bool, reason: SkipReason?)

4. Add tests:
   - Test: Already translated string → should skip
   - Test: Same as source → should translate
   - Test: shouldTranslate: false → should skip
   - Test: Both conditions → skip with correct reason
```

---

### Phase 5: Translation Service (Day 3)

```
Create TranslationService.swift - the main engine:

1. Class properties:
   - let provider: TranslationProvider
   - init(provider:)

2. Main function translateDocument():
   - Parameters:
     * document: XCStringsDocument
     * targetLanguages: [String]
     * skipOptions: SkipChecker.SkipOptions
     * onProgress: (TranslationProgress) -> Void
   
   - Returns: (document: XCStringsDocument, stats: TranslationStats)
   
   - Logic:
     a) Create mutable copy of document
     b) Get source language from document
     c) Calculate total = strings.count × targetLanguages.count
     
     d) For each (stringKey, entry) in document.strings:
        - Get source value
        
        - For each targetLang in targetLanguages:
          * Check if should skip (use SkipChecker)
          * If skip:
            - Increment stats.skipped
            - Track skip reason
            - Call onProgress()
            - Continue
          
          * Otherwise translate:
            - Call provider.translate()
            - Update entry.localizations[targetLang].value
            - Increment stats.translated
            - Call onProgress()
            - Small delay (0.1s) for rate limiting
          
          * Catch errors:
            - Increment stats.failed
            - Store error message
        
        - Update document with modified entry
     
     e) Return (updated document, final stats)

3. Create TranslationProgress struct:
   - current: Int
   - total: Int
   - currentKey: String
   - currentLanguage: String
   - action: Action enum (translated/skipped)
   - percentage: Double (computed)

4. Create TranslationStats struct:
   - translated: Int
   - skipped: Int
   - failed: Int
   - skipReasons: [String: Int]
   - errors: [String]
   - summary: String (computed, formatted nicely)

Make it robust with proper error handling.
Make it cancellable (check Task.isCancelled).
```

---

### Phase 6: UI Implementation (Day 4)

```
Build the complete UI:

1. Update ContentView.swift:
   
   Layout structure:
   - VStack with sections:
     * FileDropZone
     * File info (if file loaded)
     * Provider selection
     * Language selection
     * Options
     * Translate button
     * Progress view (if translating)
     * Results (if complete)
   
   - Use @StateObject var viewModel = TranslatorViewModel()
   - Bind all UI to viewModel properties

2. Create ProviderSelectionView.swift:
   - Radio button group for providers
   - Show provider details (cost, features)
   - API key input (SecureField) - only visible if needed
   - Endpoint input (TextField) - for DeepLX
   - Validate inputs before allowing translation

3. Create LanguageSelectionView.swift:
   - Grid of language checkboxes
   - Each shows: flag emoji + language name + code
   - "Select All" / "Deselect All" buttons
   - Only show languages present in file
   - Highlight unsupported languages for selected provider

4. Create ProgressView.swift:
   - Progress bar with percentage
   - Current string being translated
   - Live stats (translated, skipped, failed)
   - Estimated time remaining
   - Cancel button

5. Create ResultsView.swift:
   - Success/failure indicator
   - Final statistics
   - Skip reason breakdown
   - Error list (if any)
   - Action buttons:
     * Open in Finder
     * Open in Xcode
     * Translate Another File

6. Add Settings view:
   - Provider configurations
   - Default skip options
   - API key management (Keychain)
   - About section

Use SF Symbols for icons.
Make it look native macOS (standard spacing, colors).
Add keyboard shortcuts (Cmd+O, Cmd+S).
```

---

### Phase 7: ViewModel Logic (Day 4)

```
Complete TranslatorViewModel.swift:

1. Published properties:
   - inputFile: URL?
   - document: XCStringsDocument?
   - fileAnalysis: FileAnalysis?
   - selectedProvider: ProviderType = .apple
   - selectedLanguages: Set<String> = []
   - skipOptions: SkipChecker.SkipOptions
   - apiKey: String = ""
   - deeplxEndpoint: String = "http://localhost:1188/translate"
   - isTranslating: Bool = false
   - progress: TranslationProgress?
   - stats: TranslationStats?
   - error: Error?

2. Computed properties:
   - currentProvider: TranslationProvider
   - estimatedCost: Double
   - canTranslate: Bool (validates all inputs)

3. Functions:
   
   a) loadFile(_ url: URL):
      - Read JSON data
      - Decode to XCStringsDocument
      - Analyze file
      - Auto-select all languages
   
   b) analyzeFile() -> FileAnalysis:
      - Count total strings
      - Get available languages
      - Count already translated
      - Count shouldTranslate: false
      - Calculate needs translation
   
   c) translate():
      - Validate inputs
      - Create provider instance
      - Create TranslationService
      - Call translateDocument() with progress callback
      - Update UI on main thread
      - Handle errors
      - Save result
   
   d) saveResult(_ document: XCStringsDocument):
      - Generate output filename
      - Encode to JSON with pretty print
      - Write to file
      - Show save panel

4. Helper functions:
   - selectAllLanguages()
   - deselectAllLanguages()
   - resetState()
   - validateAPIKey() -> Bool

Use @MainActor for UI updates.
Make all async operations cancellable.
```

---

### Phase 8: Testing & Polish (Day 5)

```
Complete the app:

1. Testing:
   
   a) Unit tests:
      - PlaceholderProtector
      - SkipChecker
      - FileAnalysis logic
   
   b) Integration tests:
      - Load sample .xcstrings file
      - Test translation with mock provider
      - Verify placeholders preserved
      - Verify skip logic works
   
   c) Manual testing:
      - Test with your 380-string file
      - Try all 3 providers
      - Test skip scenarios
      - Test error cases:
        * Invalid API key
        * DeepLX not running
        * Network errors
        * Invalid file format

2. Error handling:
   
   - Add user-friendly error alerts
   - Provide actionable suggestions:
     * "Invalid API key" → "Get key at..."
     * "DeepLX not running" → "Start with: docker run..."
     * "File invalid" → "Use .xcstrings exported from Xcode"
   
   - Add retry logic for network errors
   - Add validation before translation starts

3. Polish:
   
   a) Performance:
      - Concurrent translations (5-10 at a time)
      - Rate limiting per provider
      - Memory efficient for large files
   
   b) UX improvements:
      - Remember last used settings
      - Recent files menu
      - Drag file onto dock icon
      - Show tooltips for complex features
      - Add keyboard shortcuts
   
   c) Visual polish:
      - App icon (globe + translation theme)
      - Launch screen
      - Proper spacing and alignment
      - Dark mode support
      - Animations for state changes

4. Documentation:
   
   - Add README.md with:
     * What it does
     * How to use
     * Provider comparison
     * How to get API keys
     * FAQ
   
   - Add in-app help:
     * Tooltips
     * "How to" buttons
     * Example file

5. Final checks:
   
   - No force unwraps
   - All errors handled
   - No crashes
   - Memory leaks checked
   - Works on macOS 14.0+
   - File saved correctly
   - Placeholders always preserved
```

---

## 📅 Development Timeline

### Simplified 5-Day Plan

| Day | Focus | Deliverable |
|-----|-------|-------------|
| **Day 1** | Models + Parser + Placeholder | Can load files, analyze them, protect placeholders |
| **Day 2** | Apple Translation | Can translate with Apple (FREE provider) |
| **Day 3** | Gemini + DeepLX + Skip Logic | All 3 providers working, smart skip implemented |
| **Day 4** | UI + ViewModel | Complete, polished UI with all features |
| **Day 5** | Testing + Polish | Production-ready app |

### Daily Breakdown

#### Day 1: Foundation
- ✅ Create Xcode project
- ✅ Build all data models
- ✅ File drop zone UI
- ✅ JSON parser
- ✅ File analysis
- ✅ PlaceholderProtector utility
- ✅ Unit tests for protection

**End of Day 1:** Can load and analyze .xcstrings files, protect placeholders

---

#### Day 2: First Provider
- ✅ TranslationProvider protocol
- ✅ AppleTranslationProvider implementation
- ✅ Basic TranslationService
- ✅ Simple UI to test translation
- ✅ Verify placeholders preserved

**End of Day 2:** Working translation with Apple (free!)

---

#### Day 3: Multi-Provider + Skip Logic
- ✅ GeminiProvider implementation
- ✅ DeepLXProvider implementation
- ✅ SkipChecker utility
- ✅ Enhanced TranslationService with skip logic
- ✅ TranslationStats tracking
- ✅ Test all providers

**End of Day 3:** All providers work, smart skipping works

---

#### Day 4: Complete UI
- ✅ Provider selection view
- ✅ Language selection grid
- ✅ Options checkboxes
- ✅ Progress view
- ✅ Results view
- ✅ Complete ViewModel
- ✅ Settings view
- ✅ File saving

**End of Day 4:** Fully functional app with nice UI

---

#### Day 5: Polish & Ship
- ✅ Integration testing
- ✅ Error handling
- ✅ Performance optimization
- ✅ Visual polish
- ✅ Documentation
- ✅ App icon
- ✅ Final testing

**End of Day 5:** Production-ready app!

---

## 📊 Provider Comparison

### Cost Comparison (for 380 strings, 15 languages)

| Provider | Cost per App | Speed | Quality | Setup Difficulty |
|----------|-------------|-------|---------|------------------|
| **Apple Translation** | $0.00 | ⚡⚡⚡ Fast | ⭐⭐⭐ Good | ✅ None |
| **Google Gemini** | ~$0.50 | ⚡⚡ Medium | ⭐⭐⭐⭐⭐ Excellent | ⚡ Easy (API key) |
| **DeepLX** | $0.00 | ⚡⚡⚡ Fast | ⭐⭐⭐⭐⭐ Excellent | ⚡⚡ Medium (Install) |

### Language Support Comparison

| Language | Apple | Gemini | DeepLX |
|----------|-------|--------|--------|
| Spanish (es) | ✅ | ✅ | ✅ |
| German (de) | ✅ | ✅ | ✅ |
| French (fr) | ✅ | ✅ | ✅ |
| Italian (it) | ✅ | ✅ | ✅ |
| Japanese (ja) | ✅ | ✅ | ✅ |
| Korean (ko) | ✅ | ✅ | ✅ |
| Dutch (nl) | ✅ | ✅ | ✅ |
| Polish (pl) | ✅ | ✅ | ✅ |
| Romanian (ro) | ❌ | ✅ | ❌ |
| Russian (ru) | ✅ | ✅ | ✅ |
| Thai (th) | ✅ | ✅ | ❌ |
| Turkish (tr) | ✅ | ✅ | ❌ |
| Ukrainian (uk) | ✅ | ✅ | ❌ |
| Vietnamese (vi) | ✅ | ✅ | ❌ |
| Arabic (ar) | ✅ | ✅ | ❌ |
| Chinese (zh) | ✅ | ✅ | ✅ |
| Portuguese (pt) | ✅ | ✅ | ✅ |
| Hindi (hi) | ❌ | ✅ | ❌ |
| Indonesian (id) | ✅ | ✅ | ❌ |

### Recommendations

**For your file (15 languages including ro, th, tr, uk, vi):**

1. **Best Free Option:** Start with **Apple Translation**
   - Supports 14/15 of your languages (missing Romanian)
   - Completely free
   - No setup needed
   - Fast

2. **Best Quality:** Use **Gemini**
   - Supports all 15 languages
   - Only ~$0.50 per translation run
   - Best context awareness
   - Easy setup (just API key)

3. **Best Privacy:** Use **DeepLX**
   - Supports 10/15 languages
   - Completely local (no data sent to cloud)
   - Free if self-hosted
   - Requires Docker/binary installation

**Recommended Strategy:**
- Use Apple Translation for 14 languages (FREE)
- Manually translate Romanian (1 language × 380 strings = 380 strings)
- Or use Gemini for all 15 languages for $0.50

---

## 🎯 Success Metrics

### For Your Specific File

**File Stats:**
- Total strings: 380
- Languages: 15 (es, de, fr, it, ja, ko, nl, pl, ro, ru, th, tr, uk, vi)
- Translation units: 380 × 15 = 5,700

### Scenario 1: First Translation (All New)

| Provider | Time | Cost | Result |
|----------|------|------|--------|
| **Apple Translation** | ~25-30 min | $0.00 | 5,320 strings (14 langs) |
| **Gemini** | ~20-25 min | ~$0.50 | 5,700 strings (15 langs) |
| **DeepLX** | ~15-20 min | $0.00 | 3,800 strings (10 langs) |

**Manual translation would take:** ~10-15 hours  
**Cost with service like TranslateKit:** ~$15-20

**Your savings with this tool:**
- ⏱️ Time: 10-15 hours → 20-30 minutes (96% faster)
- 💰 Money: $15-20 → $0-0.50 (97-100% cheaper)

---

### Scenario 2: Update (50 New Strings)

Your app update adds 50 new strings. The tool:
- Auto-skips: 330 × 15 = 4,950 already translated ✅
- Translates: 50 × 15 = 750 new strings

| Provider | Time | Cost |
|----------|------|------|
| **Apple** | ~3-4 min | $0.00 |
| **Gemini** | ~2-3 min | ~$0.06 |

**Manual would take:** ~1-2 hours  
**Your savings:** 1-2 hours → 2-4 minutes (95% faster)

---

### Scenario 3: Fix Translations (Mark Some as No-Translate)

You realize 20 strings shouldn't be translated (brand names, etc.):
1. Mark them with `shouldTranslate: false` in .xcstrings
2. Re-run tool
3. Tool auto-skips all 20 × 15 = 300 strings ✅

No wasted translations, no wasted money!

---

### ROI Analysis

**Tool Development Time:** 5 days (40 hours)

**Payback:**
- After 1st app: Save 10 hours + $15 = **$150+ value**
- After 3 apps: Save 30 hours + $45 = **$450+ value**
- After 10 apps: Save 100 hours + $150 = **$1500+ value**

**Plus:** You own the tool forever, use for all future apps!

---

## 📁 File Structure

```
XCStringsTranslator/
├── XCStringsTranslator.xcodeproj
├── README.md
├── LICENSE
│
├── XCStringsTranslator/
│   ├── App/
│   │   ├── XCStringsTranslatorApp.swift
│   │   └── Info.plist
│   │
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── FileDropZone.swift
│   │   ├── ProviderSelectionView.swift
│   │   ├── LanguageSelectionView.swift
│   │   ├── OptionsView.swift
│   │   ├── TranslationProgressView.swift
│   │   ├── ResultsView.swift
│   │   └── SettingsView.swift
│   │
│   ├── ViewModels/
│   │   └── TranslatorViewModel.swift
│   │
│   ├── Models/
│   │   ├── XCStringsDocument.swift
│   │   ├── StringEntry.swift
│   │   ├── Localization.swift
│   │   ├── StringUnit.swift
│   │   ├── TranslationProgress.swift
│   │   ├── TranslationStats.swift
│   │   └── FileAnalysis.swift
│   │
│   ├── Services/
│   │   ├── TranslationService.swift
│   │   ├── SkipChecker.swift
│   │   └── Providers/
│   │       ├── TranslationProvider.swift
│   │       ├── AppleTranslationProvider.swift
│   │       ├── GeminiProvider.swift
│   │       └── DeepLXProvider.swift
│   │
│   ├── Utilities/
│   │   ├── PlaceholderProtector.swift
│   │   ├── APIKeyManager.swift
│   │   ├── FileManager+Extensions.swift
│   │   └── String+Extensions.swift
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   │   ├── AppIcon.appiconset/
│   │   │   └── Colors/
│   │   └── Localizable.xcstrings
│   │
│   └── Supporting Files/
│       └── XCStringsTranslator.entitlements
│
├── XCStringsTranslatorTests/
│   ├── PlaceholderProtectorTests.swift
│   ├── SkipCheckerTests.swift
│   ├── TranslationServiceTests.swift
│   └── MockProvider.swift
│
└── Samples/
    ├── Example.xcstrings
    └── README.md
```

---

## ✅ Definition of Done

The project is complete when:

### Functional Requirements
- ✅ Can load any valid .xcstrings file
- ✅ Correctly parses sourceLanguage and all strings
- ✅ Displays accurate file analysis
- ✅ Supports 3 translation providers (Apple, Gemini, DeepLX)
- ✅ Translates all selected languages with one click
- ✅ Skips already-translated strings
- ✅ Skips strings marked shouldTranslate: false
- ✅ Preserves ALL placeholders (100% accuracy)
- ✅ Shows real-time progress during translation
- ✅ Displays skip statistics with reasons
- ✅ Saves valid .xcstrings output file
- ✅ Output file works in Xcode

### Quality Requirements
- ✅ No crashes under normal use
- ✅ Handles errors gracefully with user-friendly messages
- ✅ Works on macOS 14.0+
- ✅ Fast (translates 5,700 strings in < 30 min)
- ✅ Memory efficient (handles large files)
- ✅ No data loss (always saves progress)

### UI/UX Requirements
- ✅ Clean, native macOS design
- ✅ Intuitive workflow (drag, select, translate, save)
- ✅ Clear progress indicators
- ✅ Helpful error messages
- ✅ Dark mode support
- ✅ Keyboard shortcuts work

### Testing Requirements
- ✅ Unit tests pass for core utilities
- ✅ Manual testing completed on real file
- ✅ All 3 providers verified working
- ✅ Edge cases handled (empty strings, special characters)
- ✅ Placeholders verified preserved in 100+ test cases

### Documentation Requirements
- ✅ README with usage instructions
- ✅ Provider comparison guide
- ✅ API key setup instructions
- ✅ In-app tooltips for complex features

---

## 🚀 Getting Started

Once built, here's how to use the app:

### First-Time Setup

1. **Launch app**

2. **Choose provider:**
   - Start with **Apple Translation** (no setup needed)
   - Or get Gemini API key from https://aistudio.google.com/app/apikey
   - Or install DeepLX: `docker run -d -p 1188:1188 ghcr.io/OwO-Network/DeepLX:latest`

3. **Drag your .xcstrings file** into the drop zone

4. **Select languages** (or "Select All")

5. **Click "Translate"**

6. **Wait for completion** (20-30 min for first time)

7. **Save output file**

8. **Import back into Xcode project**

### Subsequent Uses

1. Drag file
2. Click "Translate" (skips already done!)
3. Done in 2-3 minutes ✨

---

## 💡 Tips & Best Practices

### For Best Results

1. **Add context comments in Xcode:**
   ```swift
   NSLocalizedString("button.save", 
                    comment: "Save button in settings screen")
   ```
   Context helps AI translate better!

2. **Mark brand names as no-translate:**
   ```json
   {
     "app.name": {
       "metadata": {"shouldTranslate": false},
       "localizations": {
         "en": {"stringUnit": {"value": "MyApp"}}
       }
     }
   }
   ```

3. **Use Apple Translation first:**
   - Free and fast
   - Good quality for UI strings
   - Only use Gemini if you need better quality

4. **Keep source strings simple:**
   - Short sentences work best
   - Avoid complex grammar
   - Split long strings into smaller ones

5. **Review critical strings:**
   - Marketing text
   - Legal disclaimers
   - Error messages
   - Have native speaker review these

### Troubleshooting

**Placeholders not preserved?**
- Check PlaceholderProtector regex patterns
- Test with sample string first
- File bug report with example

**Gemini API errors?**
- Check API key is valid
- Check rate limits (60 req/min)
- Check billing is enabled

**DeepLX not connecting?**
- Verify Docker container is running: `docker ps`
- Check endpoint URL is correct
- Test with curl: `curl http://localhost:1188/translate`

**Translation quality poor?**
- Add more context comments
- Try different provider
- Break complex strings into simpler ones

---

## 🎉 Conclusion

You now have a complete blueprint to build a professional-quality XCStrings translation tool in just 5 days!

**What you get:**
- ✅ Free translation (Apple) or cheap ($0.50 with Gemini)
- ✅ Save 10+ hours per app
- ✅ Smart skipping (don't re-translate)
- ✅ Multiple provider options
- ✅ Professional macOS app
- ✅ Tool you own forever

**ROI:** Pays for itself on first use, saves thousands over time!

Ready to build? Follow the prompts phase by phase, and you'll have a working tool by end of week! 🚀

---

## 📞 Support

For questions during development:
- Check the build prompts for specific guidance
- Test each component independently
- Use unit tests to verify correctness
- Start simple, add complexity incrementally

**Good luck building! You got this! 💪**