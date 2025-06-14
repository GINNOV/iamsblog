//
//  RenameDialog.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/13/25.
//

import SwiftUI


extension View {
    func renameDialog(
        entryToRename: Binding<AmigaEntry?>,
        newEntryName: Binding<String>,
        renameAction: @escaping () -> Void
    ) -> some View {
        // The alert's presentation is tied to whether 'entryToRename' is nil or not.
        self.alert(
            "Rename Entry",
            isPresented: .constant(entryToRename.wrappedValue != nil),
            presenting: entryToRename.wrappedValue
        ) { _ in
            TextField("New Name", text: newEntryName)
                .autocorrectionDisabled()
            
            Button("Rename") {
                renameAction()
                entryToRename.wrappedValue = nil // Dismiss alert on action
            }
            
            Button("Cancel", role: .cancel) {
                entryToRename.wrappedValue = nil // Dismiss alert on cancel
            }
        } message: { entry in
            Text("Enter a new name for \"\(entry.name)\".")
        }
    }
}
