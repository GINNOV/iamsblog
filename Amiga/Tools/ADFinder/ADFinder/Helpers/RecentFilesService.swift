//
//  RecentFilesService.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/14/25.
//

import SwiftUI

@Observable
class RecentFilesService {
    // The key for storing recent file data in UserDefaults.
    private let recentsKey = "recentADFFilePaths"
    // The maximum number of recent files to keep.
    private let maxRecents = 10
    private var recentFilePaths: [String] = []

    // A computed property that converts the stored paths back into URL objects.
    // This is the property that views will access.
    var recentFiles: [URL] {
        recentFilePaths.compactMap { URL(fileURLWithPath: $0) }
    }
    
    init() {
        self.recentFilePaths = UserDefaults.standard.stringArray(forKey: recentsKey) ?? []
    }
    
    private func save() {
        UserDefaults.standard.set(recentFilePaths, forKey: recentsKey)
    }
    
    /// Adds a new URL to the top of the recents list.
    /// It ensures the URL is for an ADF file, removes any existing duplicate,
    // and trims the list to the maximum allowed count.
    func addRecentFile(_ url: URL) {
        // We only want to track .adf files.
        guard url.pathExtension.lowercased() == "adf" else { return }
        
        let path = url.path
        
        // Remove the path if it already exists to avoid duplicates and move it to the top.
        recentFilePaths.removeAll { $0 == path }
        
        // Add the new path to the beginning of the array.
        recentFilePaths.insert(path, at: 0)
        
        // Make sure the list doesn't exceed the maximum count.
        if recentFilePaths.count > maxRecents {
            recentFilePaths = Array(recentFilePaths.prefix(maxRecents))
        }
        
        // Save the updated list.
        save()
    }
    
    /// Clears the entire list of recent files.
    func clearRecents() {
        recentFilePaths.removeAll()
        // Save the empty list.
        save()
    }
}
