//
//  RenameVolumeDialog.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/13/25.
//

import SwiftUI

extension View {
    func renameVolumeDialog(
        isPresented: Binding<Bool>,
        newVolumeName: Binding<String>,
        renameAction: @escaping () -> Void
    ) -> some View {
        self.alert("Rename Volume", isPresented: isPresented) {
            TextField("New Volume Name", text: newVolumeName)
                .autocorrectionDisabled()
            Button("Rename", action: renameAction)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enter the new name for the volume (max 30 characters).")
        }
    }
}
