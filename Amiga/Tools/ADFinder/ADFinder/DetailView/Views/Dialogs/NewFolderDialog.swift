//
//  NewFolderDialog.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/13/25.
//

import SwiftUI

// AI_REVIEW: This modifier encapsulates the "New Folder" alert logic.
extension View {
    func newFolderDialog(
        isPresented: Binding<Bool>,
        newFolderName: Binding<String>,
        createAction: @escaping () -> Void
    ) -> some View {
        self.alert("New Folder", isPresented: isPresented) {
            TextField("Folder Name", text: newFolderName)
                .autocorrectionDisabled()
            Button("Create", action: createAction)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enter a name for the new folder.")
        }
    }
}
