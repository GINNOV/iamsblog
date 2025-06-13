//
//  ToolbarView.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/13/25.
//

import SwiftUI

// AI_REVIEW: This ToolbarContent struct encapsulates the entire toolbar logic for the DetailView.
// This makes the main view's body much cleaner and separates the concern of toolbar construction.
struct DetailToolbar: ToolbarContent {
    
    // MARK: - State & Bindings
    @Binding var selectedFile: URL?
    @Binding var sortOrder: SortOrder
    let selectedEntry: AmigaEntry?
    
    // Using a nested struct to group all the action closures together neatly.
    struct Actions {
        let newADF: () -> Void
        let saveADF: () -> Void
        let newFolder: () -> Void
        let viewContent: () -> Void
        let export: () -> Void
        let rename: () -> Void
        let delete: () -> Void
        let about: () -> Void
    }
    let actions: Actions
    
    // MARK: - Body
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            // New ADF Button
            Button(action: actions.newADF) {
                Label("New", systemImage: "doc.badge.plus")
            }
            
            // Save ADF Button
            Button(action: actions.saveADF) {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(selectedFile == nil)

            // This section of the toolbar is only shown when an ADF file is open.
            if selectedFile != nil {
                // Sort Menu
                Menu {
                    Picker("Sort By", selection: $sortOrder) {
                        ForEach(SortOrder.allCases) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down.circle")
                }
                
                // New Folder Button
                Button(action: actions.newFolder) {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
                
                // Edit Menu (Hex/Text)
                Menu {
                    Button(action: actions.viewContent) {
                        Label("Hex Editor", systemImage: "number")
                    }
                    .disabled(selectedEntry?.type != .file)
                    
                    Button(action: {}) { Label("Txt Editor", systemImage: "text.quote") }
                    .disabled(true) // AI_REVIEW: Text editor not yet implemented
                } label: {
                    Label("View As", systemImage: "doc.text.magnifyingglass")
                }
                .disabled(selectedEntry?.type != .file)

                // Export Button
                Button(action: actions.export) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(selectedEntry == nil)

                // Rename Button
                Button(action: actions.rename) {
                    Label("Rename", systemImage: "pencil")
                }
                .disabled(selectedEntry == nil)

                // Delete Button
                Button(role: .destructive, action: actions.delete) {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedEntry == nil)
            }
            
            // About Button
            Button(action: actions.about) {
                Label("About ADFinder", systemImage: "info.circle")
            }
        }
    }
}
