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
    // : State to track which entry is being dragged over for visual feedback. #END_REVIEW
    @State private var dragOverId: AmigaEntry.ID? = nil
    // : State to track if the "Up" button is being targeted for a drop. #END_REVIEW
    @State private var isUpButtonTargeted: Bool = false

    // These closures are provided by the parent view to handle user actions.
    let goUpDirectory: () -> Void
    let handleEntryTap: (AmigaEntry) -> Void
    let showInfoAlert: (AmigaEntry) -> Void
    let viewFileContent: (AmigaEntry) -> Void
    let viewAsText: (AmigaEntry) -> Void
    // : Add a closure to handle the move action. #END_REVIEW
    let handleMove: (AmigaEntry.ID, AmigaEntry) -> Void
    // : Add a closure to handle moving an item to the parent directory. #END_REVIEW
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
                // : Add a background for visual feedback and the onDrop modifier. #END_REVIEW
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
                    // : Apply a background color when an item is dragged over a directory. #END_REVIEW
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
                    // : The .onDrag modifier provides the UUID of the dragged item. #END_REVIEW
                    .onDrag {
                        NSItemProvider(object: entry.id.uuidString as NSString)
                    }
                    // : The .onDrop modifier accepts the drop, validates it's a directory,
                    // extracts the source ID, and calls the handleMove closure. #END_REVIEW
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
