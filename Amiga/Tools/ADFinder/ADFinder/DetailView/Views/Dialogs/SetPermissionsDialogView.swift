//
//  SetPermissionsDialogView.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/15/25.
//

import SwiftUI

struct SetPermissionsDialogView: View {
    let config: SetPermissionsDialogConfig
    @Environment(\.dismiss) var dismiss
    
    
    @State private var isDeletable: Bool
    @State private var isWritable: Bool
    @State private var isReadable: Bool
    @State private var isExecutable: Bool
    
    // State for each attribute flag
    @State private var isHold: Bool
    @State private var isScript: Bool
    @State private var isPure: Bool
    @State private var isArchive: Bool

    // Initialize state from the initial bitmask
    init(config: SetPermissionsDialogConfig) {
        self.config = config
        let bits = config.initialBits
        
        
        _isDeletable = State(initialValue: (bits & ACCMASK_D_SWIFT) == 0)
        _isWritable = State(initialValue: (bits & ACCMASK_W_SWIFT) == 0)
        _isReadable = State(initialValue: (bits & ACCMASK_R_SWIFT) == 0)
        _isExecutable = State(initialValue: (bits & ACCMASK_E_SWIFT) == 0)

        // Attribute bits are positive, so their logic remains the same.
        _isHold = State(initialValue: (bits & FIBF_HOLD_SWIFT) != 0)
        _isScript = State(initialValue: (bits & FIBF_SCRIPT_SWIFT) != 0)
        _isPure = State(initialValue: (bits & FIBF_PURE_SWIFT) != 0)
        _isArchive = State(initialValue: (bits & FIBF_ARCHIVE_SWIFT) != 0)
    }

    private var calculatedBits: UInt32 {
        var bits: UInt32 = 0
        
        if !isDeletable { bits |= ACCMASK_D_SWIFT }
        if !isWritable { bits |= ACCMASK_W_SWIFT }
        if !isReadable { bits |= ACCMASK_R_SWIFT }
        if !isExecutable { bits |= ACCMASK_E_SWIFT }
        
        // Attribute flags are positive and are set directly.
        if isHold { bits |= FIBF_HOLD_SWIFT }
        if isScript { bits |= FIBF_SCRIPT_SWIFT }
        if isPure { bits |= FIBF_PURE_SWIFT }
        if isArchive { bits |= FIBF_ARCHIVE_SWIFT }
        return bits
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.accentColor)
                .symbolRenderingMode(.hierarchical)
            
            Text("Set Permissions")
                .font(.headline)

            Text("Set permissions for \"\(config.entryName)\"")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Form {
                                Section(header: Text("Permissions (rwed)")) {
                    PermissionToggle(title: "Readable", isOn: $isReadable, flag: "r")
                    PermissionToggle(title: "Writable", isOn: $isWritable, flag: "w")
                    PermissionToggle(title: "Executable", isOn: $isExecutable, flag: "e")
                    PermissionToggle(title: "Deletable", isOn: $isDeletable, flag: "d")
                }
                
                Section(header: Text("Attributes (hspa)")) {
                    PermissionToggle(title: "Hold (Load on Boot)", isOn: $isHold, flag: "h")
                    PermissionToggle(title: "Script (Executable)", isOn: $isScript, flag: "s")
                    PermissionToggle(title: "Pure (Re-entrant)", isOn: $isPure, flag: "p")
                    PermissionToggle(title: "Archive (Modified)", isOn: $isArchive, flag: "a")
                }
            }
            .formStyle(.grouped)
            .frame(height: 380)

            HStack(spacing: 12) {
                Button(role: .cancel, action: { dismiss() }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.cancelAction)

                Button(action: {
                    config.action(calculatedBits)
                    dismiss()
                }) {
                    Text("Set Permissions")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 420)
    }
}

// Helper View for a consistent Toggle style
private struct PermissionToggle: View {
    let title: String
    @Binding var isOn: Bool
    let flag: String

    var body: some View {
        HStack {
            Text(flag.uppercased())
                .font(.system(.body, design: .monospaced).bold())
                .foregroundColor(isOn ? .white : .primary.opacity(0.8))
                .frame(width: 24, height: 24)
                .background(isOn ? Color.accentColor : Color.secondary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            
            Toggle(title, isOn: $isOn)
        }
    }
}
