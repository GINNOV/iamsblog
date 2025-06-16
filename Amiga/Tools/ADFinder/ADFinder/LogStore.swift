//
//  LogStore.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/15/25.
//

import SwiftUI
import Combine

@Observable
class LogStore {
    // A shared singleton instance for easy access throughout the app.
    static let shared = LogStore()

    // The array of log messages that views will observe.
    var entries: [String] = []
    
    // A private constructor to enforce the singleton pattern.
    private init() {}
    
    /// Adds a new message to the log store.
    /// This will be called from the C-to-Swift logging bridge.
    @MainActor
    func add(message: String) {
        // Append new messages to the store.
        // The @MainActor attribute ensures this is done safely on the main thread.
        entries.append(message)
    }

    /// Clears all messages from the log store.
    @MainActor
    func clear() {
        entries.removeAll()
    }
}
