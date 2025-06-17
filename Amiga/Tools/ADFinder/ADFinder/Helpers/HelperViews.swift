//
//  HelperViews.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI

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

struct ProtectionBitsView: View {
    let bits: UInt32

    private struct BitInfo {
        let label: String
        let flag: UInt32
    }

        private let permissionFlags: [BitInfo] = [
        .init(label: "r", flag: ACCMASK_R_SWIFT),
        .init(label: "w", flag: ACCMASK_W_SWIFT),
        .init(label: "e", flag: ACCMASK_E_SWIFT),
        .init(label: "d", flag: ACCMASK_D_SWIFT)
    ]
    
    private let attributeFlags: [BitInfo] = [
        .init(label: "h", flag: FIBF_HOLD_SWIFT),
        .init(label: "s", flag: FIBF_SCRIPT_SWIFT),
        .init(label: "p", flag: FIBF_PURE_SWIFT),
        .init(label: "a", flag: FIBF_ARCHIVE_SWIFT)
    ]

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Permissions")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack {
                    
                    ForEach(permissionFlags, id: \.label) { flagInfo in
                        ProtectionBitView(
                            label: flagInfo.label,
                            isSet: (bits & flagInfo.flag) == 0, // Inverted logic
                            isProtection: true
                        )
                    }
                }
            }
            
            VStack(alignment: .leading) {
                Text("Attributes")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack {
                                        ForEach(attributeFlags, id: \.label) { flagInfo in
                        ProtectionBitView(
                            label: flagInfo.label,
                            isSet: (bits & flagInfo.flag) != 0, // Direct logic
                            isProtection: false
                        )
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

    private var statusColor: Color {
        
        if isSet {
            return isProtection ? .green.opacity(0.8) : .blue.opacity(0.8)
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private var statusText: String {
        return isSet ? label : "-"
    }

    var body: some View {
        Text(statusText.uppercased())
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
        switch label.lowercased() {
        case "d": return isSet ? "Deletable" : "Delete Protected"
        case "e": return isSet ? "Executable" : "Execute Protected"
        case "w": return isSet ? "Writable" : "Write Protected"
        case "r": return isSet ? "Readable" : "Read Protected"
        case "a": return isSet ? "Archive (Needs backup)" : "Archive bit cleared"
        case "p": return isSet ? "Pure (Re-entrant/Sharable)" : "Not Pure"
        case "s": return isSet ? "Script (Executable Script)" : "Not a Script"
        case "h": return isSet ? "Hold (Load into RAM on boot)" : "Not Hold"
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
    
    func newAdfDialogSheet(
        config: Binding<NewADFDialogConfig?>
    ) -> some View {
        self.sheet(item: config) { item in
            NewADFDialogView(config: item)
        }
    }
    
        func setPermissionsDialogSheet(
        config: Binding<SetPermissionsDialogConfig?>
    ) -> some View {
        self.sheet(item: config) { item in
            SetPermissionsDialogView(config: item)
        }
    }
}
