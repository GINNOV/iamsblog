//
//  AmigaCommandsFocusKeys.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/14/25.
//

import SwiftUI

private struct AmigaActionsKey: FocusedValueKey {
    typealias Value = DetailToolbar.Actions
}

private struct IsFileOpenKey: FocusedValueKey {
    typealias Value = Bool
}

private struct IsEntrySelectedKey: FocusedValueKey {
    typealias Value = Bool
}

extension FocusedValues {
    var amigaActions: DetailToolbar.Actions? {
        get { self[AmigaActionsKey.self] }
        set { self[AmigaActionsKey.self] = newValue }
    }

    var isFileOpen: Bool? {
        get { self[IsFileOpenKey.self] }
        set { self[IsFileOpenKey.self] = newValue }
    }

    var isEntrySelected: Bool? {
        get { self[IsEntrySelectedKey.self] }
        set { self[IsEntrySelectedKey.self] = newValue }
    }
}
