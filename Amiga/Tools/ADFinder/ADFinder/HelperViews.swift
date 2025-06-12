//
//  HelperViews.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI

// AI_TRACK: This generic confirmation view is now used for all destructive actions.
struct ActionConfirmationView: View {
    let title: String
    let message: String
    let imageName: String
    let confirmButtonTitle: String
    let confirmButtonRole: ButtonRole
    var showsForceToggle: Bool = false
    
    @Binding var forceFlag: Bool
    
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            Text(title)
                .font(.headline)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if showsForceToggle {
                Toggle("Override AmigaOS flags (force operation)", isOn: $forceFlag)
                    .toggleStyle(.checkbox)
            }

            HStack(spacing: 12) {
                Button(role: .cancel, action: onCancel) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.cancelAction)

                Button(role: confirmButtonRole, action: onConfirm) {
                    Text(confirmButtonTitle)
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
