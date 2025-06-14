//
//  NewFolderDialogConfig.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/14/25.
//

import Foundation

struct NewFolderDialogConfig {
    static func config(action: @escaping (String) -> Void) -> InputDialogConfig {
        InputDialogConfig(
            title: "New Folder",
            message: "Please enter a name for the new folder.",
            imageName: "folder.badge.plus.SFSymbol",
            prompt: "Folder Name",
            initialText: "",
            confirmButtonTitle: "Create",
            action: action
        )
    }
}
