//
//  ToolbarView.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/13/25.
//

import SwiftUI

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
        let addFile: () -> Void
        let newFolder: () -> Void
        let editVolumeName: () -> Void
        let getInfo: () -> Void
        let setPermissions: () -> Void
        let viewContent: () -> Void
        let viewAsText: () -> Void
        let export: () -> Void
        let rename: () -> Void
        let delete: () -> Void
        let about: () -> Void
        // : Add actions for the new Tools menu to open the console and comparator windows. #END_REVIEW
        let showConsole: () -> Void
        let showComparator: () -> Void
    }
    let actions: Actions
    
    // MARK: - Body
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            // New ADF Button
            Button(action: actions.newADF) {
                Label("New", systemImage: "doc.badge.plus")
            }
            .help("Create New Blank ADF")
            
            // Save ADF Button
            Button(action: actions.saveADF) {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .help("Save ADF As...")
            .disabled(selectedFile == nil)

            // This section of the toolbar is only shown when an ADF file is open.
            if selectedFile != nil {
                
                Button(action: actions.addFile) {
                    Label("Add File", systemImage: "plus")
                }
                .help("Add file(s) to the current directory")

                // New Folder Button
                Button(action: actions.newFolder) {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
                .help("Create a New Folder")
                
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
                .help("Change Sort Order")
                
                // Edit Menu (Hex/Text)
                Menu {
                    Button(action: actions.viewContent) {
                        Label("Hex Viewer", systemImage: "number")
                    }
                    .disabled(selectedEntry?.type != .file)
                    
                    Button(action: actions.viewAsText) {
                        Label("Text Editor", systemImage: "text.quote")
                    }
                    .disabled(selectedEntry?.type != .file)
                } label: {
                    Label("View As", systemImage: "doc.text.magnifyingglass")
                }
                .help("Plug-ins")
                .disabled(selectedEntry?.type != .file)

                // Export Button
                Button(action: actions.export) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .help("Export Selected Item to Desktop")
                .disabled(selectedEntry == nil)

                // Rename Button
                Button(action: actions.rename) {
                    Label("Rename", systemImage: "pencil")
                }
                .help("Rename Selected Item")
                .disabled(selectedEntry == nil)

                // Delete Button
                Button(role: .destructive, action: actions.delete) {
                    Label("Delete", systemImage: "trash")
                }
                .help("Delete Selected Item")
                .disabled(selectedEntry == nil)
            }
            
            // : Add a new "Tools" menu to provide quick access to the console and comparator windows. #END_REVIEW
            Menu {
                Button(action: actions.showConsole) {
                    Label("Console", systemImage: "terminal")
                }
                Button(action: actions.showComparator) {
                    Label("Compare Disks", systemImage: "arrow.left.and.right.square")
                }
            } label: {
                Label("Tools", systemImage: "wrench.and.screwdriver")
            }
            .help("Show Tools")
            
            // About Button
            Button(action: actions.about) {
                Label("About ADFinder", systemImage: "info.circle")
            }
            .help("About This App")
        }
    }
}
