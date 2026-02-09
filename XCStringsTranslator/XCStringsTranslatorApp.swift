//
//  XCStringsTranslatorApp.swift
//  XCStringsTranslator
//
//  Main app entry point with keyboard shortcuts
//

import SwiftUI
import Combine

@main
struct XCStringsTranslatorApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button("Open File...") {
                    appState.showOpenPanel = true
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Divider()
                
                Menu("Open Recent") {
                    ForEach(AppSettings.shared.recentFiles, id: \.self) { url in
                        Button(url.lastPathComponent) {
                            appState.fileToOpen = url
                        }
                    }
                    
                    if !AppSettings.shared.recentFiles.isEmpty {
                        Divider()
                        Button("Clear Recent") {
                            AppSettings.shared.clearRecentFiles()
                        }
                    }
                }
            }
            
            // Help
            CommandGroup(replacing: .help) {
                Link("Get Gemini API Key", destination: URL(string: "https://aistudio.google.com/app/apikey")!)
                Link("DeepLX GitHub", destination: URL(string: "https://github.com/OwO-Network/DeepLX")!)
            }
        }
    }
}

/// App-wide state for menu commands
class AppState: ObservableObject {
    @Published var showOpenPanel = false
    @Published var fileToOpen: URL?
}
