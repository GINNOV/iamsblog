//
//  InputDialogConfig.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/14/25.
//

import SwiftUI

// AI_REVIEW: This struct defines the configuration for a generic input dialog,
// similar to how ConfirmationConfig works for confirmation dialogs. The specific
// factory methods have been moved to their own dedicated files for better organization.
struct InputDialogConfig: Identifiable {
    let id = UUID(  )
    let title: String
    let message: String
    let imageName: String
    let prompt: String
    let initialText: String
    let confirmButtonTitle: String
    let action: (String) -> Void // The action takes the text field's final string value.
}
