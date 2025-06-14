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

// AI_REVIEW: This is the new, sleeker view for displaying protection bits.
struct ProtectionBitsView: View {
    let bits: UInt32

    private struct BitInfo {
        let label: String
        let flag: UInt32
        let isProtectionBit: Bool // True if a SET bit means protection is ON (action is disallowed)
    }

    private let standardFlags: [BitInfo] = [
        .init(label: "D", flag: ACCMASK_D_SWIFT, isProtectionBit: true),
        .init(label: "W", flag: ACCMASK_W_SWIFT, isProtectionBit: true),
    ]
    
    private let specialFlags: [BitInfo] = [
        .init(label: "H", flag: FIBF_HOLD_SWIFT, isProtectionBit: false),
        .init(label: "S", flag: FIBF_SCRIPT_SWIFT, isProtectionBit: false),
        .init(label: "P", flag: FIBF_PURE_SWIFT, isProtectionBit: false),
        .init(label: "A", flag: FIBF_ARCHIVE_SWIFT, isProtectionBit: false)
    ]

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Permissions")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack {
                    // Placeholders for R and E which are not in the 'access' field
                    ProtectionBitView(label: "R", isSet: false, isProtection: false, isNA: true)
                    ProtectionBitView(label: "E", isSet: false, isProtection: false, isNA: true)
                    // The actual protection flags
                    ForEach(standardFlags, id: \.label) { flagInfo in
                        ProtectionBitView(label: flagInfo.label, isSet: (bits & flagInfo.flag) != 0, isProtection: flagInfo.isProtectionBit)
                    }
                }
            }
            
            VStack(alignment: .leading) {
                Text("Attributes")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack {
                    ForEach(specialFlags, id: \.label) { flagInfo in
                        ProtectionBitView(label: flagInfo.label, isSet: (bits & flagInfo.flag) != 0, isProtection: flagInfo.isProtectionBit)
                    }
                }
            }
        }
    }
}

private struct ProtectionBitView: View {
    let label: String
    let isSet: Bool
    let isProtection: Bool
    var isNA: Bool = false

    private var statusColor: Color {
        if isNA { return .gray.opacity(0.3) }
        if isProtection {
            // For protection bits, set (protected) is red, unset (allowed) is green.
            return isSet ? .red.opacity(0.8) : .green.opacity(0.8)
        } else {
            // For attribute bits, set (active) is blue, unset is gray.
            return isSet ? .blue.opacity(0.8) : .gray.opacity(0.3)
        }
    }
    
    private var statusText: String {
        if isNA { return label }
        return isSet ? label : "-"
    }

    var body: some View {
        Text(statusText)
            .font(.system(.caption, design: .monospaced).bold())
            .foregroundColor(.white)
            .frame(width: 22, height: 22)
            .background(statusColor)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
            .help(getHelpText())
    }
    
    private func getHelpText() -> String {
        if isNA { return "\(label): Read/Execute (not stored in this flag set)" }
        switch label {
        case "D": return isSet ? "Delete Protected" : "Deletable"
        case "W": return isSet ? "Write Protected" : "Writable"
        case "H": return isSet ? "Hold (Load into RAM on boot)" : "Not Hold"
        case "S": return isSet ? "Script (Executable Script)" : "Not a Script"
        case "P": return isSet ? "Pure (Re-entrant/Sharable)" : "Not Pure"
        case "A": return isSet ? "Archive (Modified since last backup)" : "Archive bit cleared"
        default: return ""
        }
    }
}


extension View {
    func inputDialogSheet(
        config: Binding<InputDialogConfig?>
    ) -> some View {
        self.sheet(item: config) { item in
            InputDialogView(config: item)
        }
    }
    
    func infoDialogSheet(
        config: Binding<InfoDialogConfig?>
    ) -> some View {
        self.sheet(item: config) { item in
            InfoDialogView(config: item)
        }
    }
}
