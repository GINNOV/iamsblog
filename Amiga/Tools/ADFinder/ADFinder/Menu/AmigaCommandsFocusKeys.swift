//
//  AmigaCommandsFocusKeys.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/13/25.
//

import SwiftUI

// AI_REVIEW: These keys define the custom values that our DetailView will
// provide to the application's focused scene. Commands can then read these
// values to update their state (e.g., enabling/disabling menu items).

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
