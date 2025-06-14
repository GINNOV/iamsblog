//
//  InfoDialogView.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/14/25.
//

import SwiftUI

struct InfoDialogView: View {
    let config: InfoDialogConfig
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: config.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.accentColor)
                .symbolRenderingMode(.hierarchical)
            
            Text(config.title)
                .font(.headline)

            // Using a Form-like structure for alignment
            VStack(alignment: .leading, spacing: 10) {
                InfoRow(label: "Name:", value: config.entry.name)
                InfoRow(label: "Type:", value: config.entry.type.rawValue)
                InfoRow(label: "Size:", value: "\(config.entry.size) bytes")
                if let date = config.entry.date {
                    InfoRow(label: "Date:", value: date.formatted(date: .long, time: .standard))
                }
                if let comment = config.entry.comment, !comment.isEmpty {
                    InfoRow(label: "Comment:", value: comment)
                }
                
                HStack(alignment: .top) {
                    Text("Protection:")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.bold)
                        .frame(width: 100, alignment: .trailing)
                    ProtectionBitsView(bits: config.entry.protectionBits)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)

            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(30)
        .frame(width: 420)
    }
}

// Helper view for consistent row formatting
private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
                .frame(width: 100, alignment: .trailing)
            Text(value)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
