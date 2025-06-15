//
//  SetPermissionsDialogConfig.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/15/25.
//

import Foundation

struct SetPermissionsDialogConfig: Identifiable {
    let id = UUID()
    let entryName: String
    let initialBits: UInt32
    let action: (UInt32) -> Void // The action takes the final, calculated bitmask.
}
