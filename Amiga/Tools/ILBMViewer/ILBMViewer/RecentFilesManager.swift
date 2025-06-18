//
//  RecentFilesManager.swift
//  ILBMViewer
//
//  Created by Mario Esposito on 6/18/25.
//

import Foundation

class RecentFilesManager: ObservableObject {
    @Published var files: [URL] = []
    private let key = "recentIFFBookmarks"
    private let maxRecents = 5

    init() {
        loadRecents()
    }

    func add(url: URL) {
        // Create secure bookmark data from the URL
        guard let bookmark = try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil) else {
            return
        }

        var bookmarks = UserDefaults.standard.array(forKey: key) as? [Data] ?? []

        // Avoid duplicates by removing any existing bookmark for the same file
        if let existingIndex = files.firstIndex(of: url) {
            bookmarks.remove(at: existingIndex)
        }
        
        // Add the new bookmark to the top of the list
        bookmarks.insert(bookmark, at: 0)
        
        // Keep the list at the desired size
        if bookmarks.count > maxRecents {
            bookmarks = Array(bookmarks.prefix(maxRecents))
        }
        
        UserDefaults.standard.set(bookmarks, forKey: key)
        loadRecents() // Reload to update the @Published property
    }

    private func loadRecents() {
        let bookmarks = UserDefaults.standard.array(forKey: key) as? [Data] ?? []
        files = bookmarks.compactMap { bookmark in
            var isStale = false
            // Resolve the bookmark data back into a URL
            guard let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale), !isStale else {
                return nil
            }
            return url
        }
    }
}
