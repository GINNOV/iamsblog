//
//  RenameVolumeDialogConfig.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/14/25.
//

import Foundation

struct RenameVolumeDialogConfig {
    static func config(currentName: String, action: @escaping (String) -> Void) -> InputDialogConfig {
        InputDialogConfig(
            title: "Rename Volume",
            message: "Enter a new name for the volume (max 30 characters).",
            imageName: "pencil.and.outline.SFSymbol",
            prompt: "Volume Name",
            initialText: currentName,
            confirmButtonTitle: "Rename",
            action: action
        )
    }
}
