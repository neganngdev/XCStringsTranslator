//
//  ProviderSelectionView.swift
//  XCStringsTranslator
//
//  Provider selection with configuration options
//

import SwiftUI

struct ProviderSelectionView: View {
    @Binding var selectedProvider: ProviderType
    @Binding var apiKey: String
    @Binding var deeplxEndpoint: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🔧 Translation Provider")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(ProviderType.allCases) { provider in
                    ProviderRow(
                        provider: provider,
                        isSelected: selectedProvider == provider,
                        onSelect: { selectedProvider = provider }
                    )
                }
            }
            
            // Provider-specific configuration
            if selectedProvider == .gemini {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        SecureField("Enter your Gemini API key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                        
                        Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                            Text("Get Key")
                                .font(.caption)
                        }
                    }
                }
                .padding(.top, 8)
            }
            
            if selectedProvider == .deeplx {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DeepLX Endpoint")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextField("http://localhost:1188/translate", text: $deeplxEndpoint)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Run: docker run -d -p 1188:1188 ghcr.io/OwO-Network/DeepLX:latest")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ProviderRow: View {
    let provider: ProviderType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Image(systemName: provider.icon)
                    .frame(width: 24)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.rawValue)
                        .fontWeight(.medium)
                    
                    Text(provider.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProviderSelectionView(
        selectedProvider: .constant(.gemini),
        apiKey: .constant(""),
        deeplxEndpoint: .constant("http://localhost:1188/translate")
    )
    .padding()
}
