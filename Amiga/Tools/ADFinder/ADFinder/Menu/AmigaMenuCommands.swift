//
//  AmigaMenuCommands.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/13/25.
//

import SwiftUI

// AI_REVIEW: This Commands struct defines the "Amiga" application menu.
// It now uses @FocusedValue to get the actions and context from the focused DetailView
// to enable or disable its menu items appropriately.
struct AmigaMenuCommands: Commands {
    
    @FocusedValue(\.amigaActions) private var actions: DetailToolbar.Actions?
    @FocusedValue(\.isFileOpen) private var isFileOpen: Bool?
    @FocusedValue(\.isEntrySelected) private var isEntrySelected: Bool?
    
    var body: some Commands {
        CommandMenu("Amiga") {
            // Only show the menu items if the actions are available from a focused view.
            if let actions = actions {
                let isFileOpen = self.isFileOpen ?? false
                let isEntrySelected = self.isEntrySelected ?? false

                // MARK: - File Operations
                Button("New Blank ADF...", action: actions.newADF)
                Button("Save ADF As...", action: actions.saveADF)
                    .disabled(!isFileOpen)
                
                Divider()

                // MARK: - Item Creation
                Button("Add File(s)...", action: actions.addFile)
                    .disabled(!isFileOpen)
                Button("New Folder...", action: actions.newFolder)
                    .disabled(!isFileOpen)
                
                Button("Edit Volume Name...", action: actions.editVolumeName)
                    .disabled(!isFileOpen)
                
                Divider()
                
                // MARK: - Selected Item Operations
                Button("Get Info", action: actions.getInfo)
                    .disabled(!isEntrySelected)
                    .keyboardShortcut("i", modifiers: .command)

                Button("View Content", action: actions.viewContent)
                    .disabled(!isEntrySelected)
                Button("Export Item...", action: actions.export)
                    .disabled(!isEntrySelected)

                Divider()

                Button("Rename Item...", action: actions.rename)
                    .disabled(!isEntrySelected)
                Button("Delete Item", action: actions.delete)
                    .disabled(!isEntrySelected)
                    // Also adding a standard keyboard shortcut for delete.
                    .keyboardShortcut(.delete, modifiers: [])
            }
        }
    }
}
