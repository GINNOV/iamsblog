//
//  FileListView.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/13/25.
//

import SwiftUI

struct FileListView: View {
    @Binding var selectedEntryID: AmigaEntry.ID?
    let sortedEntries: [AmigaEntry]
    let currentPath: [String]

    // These closures are provided by the parent view to handle user actions.
    let goUpDirectory: () -> Void
    let handleEntryTap: (AmigaEntry) -> Void
    let showInfoAlert: (AmigaEntry) -> Void
    let viewFileContent: (AmigaEntry) -> Void

    var body: some View {
        // The List that shows the directory contents.
        List(selection: $selectedEntryID) {
            // Show the ".." (go up) button if we are not at the root.
            if !currentPath.isEmpty {
                Button(action: goUpDirectory) {
                    Label(".. (Up one level)", systemImage: "arrow.up.left.circle.fill")
                }
                .buttonStyle(.plain) // Use plain style to make the whole row clickable
                .selectionDisabled(true)
            }

            // Iterate over the sorted entries and create a row for each one.
            ForEach(sortedEntries) { entry in
                FileRowView(entry: entry)
                    .contentShape(Rectangle()) // Makes the entire row tappable
                    .onTapGesture(count: 2) { // Double tap to activate
                        handleEntryTap(entry)
                    }
                    .onTapGesture(count: 1) { // Single tap to select
                        selectedEntryID = entry.id
                    }
                    .contextMenu {
                         // The context menu for each item.
                        Button("View Info") { showInfoAlert(entry) }
                         if entry.type == .file {
                             Button("View Content (Hex)") { viewFileContent(entry) }
                         }
                    }
                    .tag(entry.id)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }
}
