//
//  Notifications.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/13/25.
//

import Foundation

// This extension holds custom notifications for the app,
// allowing different parts of the UI (like menus and views) to
// communicate without being directly coupled.
extension Notification.Name {
    static let openAdfFile = Notification.Name("com.adfinder.openAdfFile")
    // recent files
    static let openSpecificAdfFile = Notification.Name("com.adfinder.openSpecificAdfFile")
}
