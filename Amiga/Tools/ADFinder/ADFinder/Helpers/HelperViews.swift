//
//  HelperViews.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI

// AI_REVIEW: This is the new generic input dialog view. It's used for any action
// that requires text input from the user, like creating a new folder or renaming an item.
struct InputDialogView: View {
    let config: InputDialogConfig
    
    @State private var inputText: String
    @Environment(\.dismiss) var dismiss

    init(config: InputDialogConfig) {
        self.config = config
        _inputText = State(initialValue: config.initialText)
    }

    var body: some View {
        VStack(spacing: 20) {
            // The image can now be an asset or an SF Symbol
            if config.imageName.hasSuffix(".SFSymbol") {
                Image(systemName: String(config.imageName.dropLast(".SFSymbol".count)))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.accentColor)
                    .symbolRenderingMode(.hierarchical)
            } else {
                Image(config.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            }

            Text(config.title)
                .font(.headline)

            Text(config.message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            TextField(config.prompt, text: $inputText)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()

            HStack(spacing: 12) {
                Button(role: .cancel, action: { dismiss() }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.cancelAction)

                Button(action: {
                    config.action(inputText)
                    dismiss()
                }) {
                    Text(config.confirmButtonTitle)
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.defaultAction)
                // The confirm button is disabled if the text field is empty.
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(30)
        .frame(width: 380)
    }
}

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

// AI_REVIEW: New view extension to present the InputDialogView as a sheet.
extension View {
    func inputDialogSheet(
        config: Binding<InputDialogConfig?>
    ) -> some View {
        self.sheet(item: config) { item in
            InputDialogView(config: item)
        }
    }
}
