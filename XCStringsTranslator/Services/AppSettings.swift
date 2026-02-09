//
//  AppSettings.swift
//  XCStringsTranslator
//
//  Persistent app settings using UserDefaults
//

import Foundation
import Combine

/// Persistent storage for app settings
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    
    private enum Keys {
        static let selectedProvider = "selectedProvider"
        static let skipAlreadyTranslated = "skipAlreadyTranslated"
        static let skipShouldTranslateFalse = "skipShouldTranslateFalse"
        static let deeplxEndpoint = "deeplxEndpoint"
        static let recentFiles = "recentFiles"
    }
    
    // MARK: - Properties
    
    var selectedProvider: ProviderType {
        get {
            guard let raw = defaults.string(forKey: Keys.selectedProvider),
                  let provider = ProviderType(rawValue: raw) else {
                return .gemini
            }
            return provider
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.selectedProvider)
        }
    }
    
    var skipAlreadyTranslated: Bool {
        get { defaults.object(forKey: Keys.skipAlreadyTranslated) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.skipAlreadyTranslated) }
    }
    
    var skipShouldTranslateFalse: Bool {
        get { defaults.object(forKey: Keys.skipShouldTranslateFalse) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.skipShouldTranslateFalse) }
    }
    
    var deeplxEndpoint: String {
        get { defaults.string(forKey: Keys.deeplxEndpoint) ?? "http://localhost:1188/translate" }
        set { defaults.set(newValue, forKey: Keys.deeplxEndpoint) }
    }
    
    var recentFiles: [URL] {
        get {
            guard let data = defaults.data(forKey: Keys.recentFiles),
                  let bookmarks = try? JSONDecoder().decode([Data].self, from: data) else {
                return []
            }
            
            return bookmarks.compactMap { bookmark in
                var isStale = false
                return try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            }
        }
        set {
            let bookmarks = newValue.compactMap { url in
                try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            }
            
            if let data = try? JSONEncoder().encode(bookmarks) {
                defaults.set(data, forKey: Keys.recentFiles)
            }
        }
    }
    
    // MARK: - Methods
    
    func addRecentFile(_ url: URL) {
        var files = recentFiles
        files.removeAll { $0 == url }
        files.insert(url, at: 0)
        recentFiles = Array(files.prefix(10))
    }
    
    func clearRecentFiles() {
        recentFiles = []
    }
}
