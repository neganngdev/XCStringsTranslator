//
//  FileDropZone.swift
//  XCStringsTranslator
//
//  Drag & drop component for xcstrings files
//

import SwiftUI
import UniformTypeIdentifiers

struct FileDropZone: View {
    /// Called when a valid file is dropped
    var onFileDrop: (URL) -> Void
    
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 48))
                .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
            
            Text("Drop .xcstrings file here")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("or click to browse")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
                )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            openFilePicker()
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
    }
    
    /// Handle dropped files
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard error == nil,
                  let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  url.pathExtension.lowercased() == "xcstrings" else {
                return
            }
            
            DispatchQueue.main.async {
                onFileDrop(url)
            }
        }
        
        return true
    }
    
    /// Open file picker dialog
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "xcstrings")].compactMap { $0 }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Select an .xcstrings file to translate"
        
        if panel.runModal() == .OK, let url = panel.url {
            onFileDrop(url)
        }
    }
}

#Preview {
    FileDropZone { url in
        print("Dropped: \(url)")
    }
    .frame(width: 400, height: 300)
    .padding()
}
