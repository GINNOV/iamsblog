//
//  InputDialogConfig.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/14/25.
//

import SwiftUI

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
