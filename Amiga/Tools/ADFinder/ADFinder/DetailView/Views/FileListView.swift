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
        @State private var dragOverId: AmigaEntry.ID? = nil
        @State private var isUpButtonTargeted: Bool = false

    // These closures are provided by the parent view to handle user actions.
    let goUpDirectory: () -> Void
    let handleEntryTap: (AmigaEntry) -> Void
    let showInfoAlert: (AmigaEntry) -> Void
    let viewFileContent: (AmigaEntry) -> Void
    let viewAsText: (AmigaEntry) -> Void
        let handleMove: (AmigaEntry.ID, AmigaEntry) -> Void
        let handleMoveToParent: (AmigaEntry.ID) -> Void

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
                                .background(isUpButtonTargeted ? Color.accentColor.opacity(0.5) : Color.clear)
                .onDrop(of: [.plainText], isTargeted: $isUpButtonTargeted) { providers -> Bool in
                    providers.first?.loadObject(ofClass: NSString.self) { string, error in
                        if let uuidString = string as? String, let sourceID = UUID(uuidString: uuidString) {
                            DispatchQueue.main.async {
                                handleMoveToParent(sourceID)
                            }
                        }
                    }
                    return true
                }
            }

            // Iterate over the sorted entries and create a row for each one.
            ForEach(sortedEntries) { entry in
                FileRowView(entry: entry)
                                        .background(dragOverId == entry.id && entry.type == .directory ? Color.accentColor.opacity(0.5) : Color.clear)
                    .contentShape(Rectangle()) // Makes the entire row tappable
                    .onTapGesture(count: 2) { // Double tap to activate
                        handleEntryTap(entry)
                    }
                    .onTapGesture(count: 1) { // Single tap to select
                        selectedEntryID = entry.id
                    }
                    .contextMenu {
                         // The context menu for each item.
                        Button("Get Info") { showInfoAlert(entry) }
                         if entry.type == .file {
                             Button("View as Hex") { viewFileContent(entry) }
                             Button("Edit as Text") { viewAsText(entry) }
                         }
                    }
                    .tag(entry.id)
                                        .onDrag {
                        NSItemProvider(object: entry.id.uuidString as NSString)
                    }
                    
                    .onDrop(of: [.plainText], isTargeted: Binding(get: {
                        dragOverId == entry.id
                    }, set: { isTargeted in
                        dragOverId = isTargeted ? entry.id : nil
                    })) { providers -> Bool in
                        guard entry.type == .directory else { return false }
                        providers.first?.loadObject(ofClass: NSString.self) { string, error in
                            if let uuidString = string as? String, let sourceID = UUID(uuidString: uuidString) {
                                DispatchQueue.main.async {
                                    handleMove(sourceID, entry)
                                }
                            }
                        }
                        return true
                    }
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }
}
