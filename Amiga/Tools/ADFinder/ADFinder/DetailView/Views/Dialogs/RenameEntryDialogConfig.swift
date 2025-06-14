//
//  RenameEntryDialogConfig.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/14/25.
//

import Foundation

// AI_REVIEW: This struct provides a specific configuration for the "Rename Entry" input dialog.
struct RenameEntryDialogConfig {
    static func config(entry: AmigaEntry, action: @escaping (String) -> Void) -> InputDialogConfig {
        InputDialogConfig(
            title: "Rename Entry",
            message: "Enter a new name for \"\(entry.name)\".",
            imageName: "pencil.SFSymbol",
            prompt: "New Name",
            initialText: entry.name,
            confirmButtonTitle: "Rename",
            action: action
        )
    }
}
