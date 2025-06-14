//
//  NewADFDialogConfig.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/14/25.
//

import Foundation

struct NewADFDialogConfig: Identifiable {
    let id = UUID()
    let action: (String, UInt8) -> Void
}
