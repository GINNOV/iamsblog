//
//  HelperViews.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI

struct DeleteConfirmationView: View {
    let entry: AmigaEntry
    let onConfirm: (Bool) -> Void
    let onCancel: () -> Void

    @State private var forceDeletion = false

    var body: some View {
        VStack(spacing: 20) {
            Image("Trash/\(entry.type == .directory ? "trash_folder" : "trash_file")")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            Text("Delete \(entry.type == .directory ? "Folder" : "File")")
                .font(.headline)

            Text("Are you sure you want to permanently delete \"\(entry.name)\"? This action cannot be undone.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: $forceDeletion) {
                Text("Override AmigaOS flags (force operation)")
            }
            .toggleStyle(.checkbox)

            HStack(spacing: 12) {
                Button(role: .cancel, action: onCancel) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.cancelAction)

                Button(role: .destructive, action: { onConfirm(forceDeletion) }) {
                    Text("Delete")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 380)
    }
}


struct WelcomeView: View {
    var body: some View {
        VStack {
            Image(systemName: "archivebox.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.secondary)
                .padding()
            Text("Please open or drop an ADF file here.")
                .font(.title)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FileRowView: View {
    let entry: AmigaEntry
    
    var body: some View {
        HStack {
            Image(systemName: iconForEntry(entry.type))
                .foregroundColor(colorForEntry(entry.type))
            Text(entry.name)
            Spacer()
            if entry.type == .file {
                Text("\(entry.size) bytes")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func iconForEntry(_ type: EntryType) -> String {
        switch type {
        case .file: return "doc.fill"; case .directory: return "folder.fill"
        case .softLinkFile, .softLinkDir: return "link"; default: return "questionmark.diamond.fill"
        }
    }
    
    private func colorForEntry(_ type: EntryType) -> Color {
        switch type {
        case .file: return .blue; case .directory: return .orange
        case .softLinkFile, .softLinkDir: return .purple; default: return .gray
        }
    }
}
