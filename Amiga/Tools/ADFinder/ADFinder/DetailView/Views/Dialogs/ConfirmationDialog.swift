//
//  ConfirmationConfig.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/13/25.
//

import SwiftUI

// AI_REVIEW: This struct was moved from DetailView.swift to its own file.
// It holds all the necessary information to configure and display the generic confirmation dialog.
// The problematic @Binding property has been removed.
struct ConfirmationConfig: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let imageName: String
    let confirmButtonTitle: String
    let showsForceToggle: Bool
    
    // The action now takes the state of the force toggle as a parameter when executed.
    let action: (Bool) -> Void

    // Factory method for creating a "New ADF" confirmation.
    static func newADF(action: @escaping () -> Void) -> ConfirmationConfig {
        ConfirmationConfig(
            title: "Create New ADF?",
            message: "Creating a new ADF will close the current one. Any unsaved changes will be lost.",
            imageName: "warning",
            confirmButtonTitle: "Proceed",
            showsForceToggle: false,
            action: { _ in action() } // The boolean is ignored here.
        )
    }

    // Factory method for creating a "Delete Entry" confirmation.
    static func delete(entry: AmigaEntry, action: @escaping (Bool) -> Void) -> ConfirmationConfig {
        ConfirmationConfig(
            title: "Delete \(entry.type == .directory ? "Folder" : "File")",
            message: "Are you sure you want to permanently delete \"\(entry.name)\"? This action cannot be undone.",
            imageName: (entry.type == .directory ? "trash_folder" : "trash_file"),
            confirmButtonTitle: "Delete",
            showsForceToggle: true, // This action can be forced.
            action: action
        )
    }
}
