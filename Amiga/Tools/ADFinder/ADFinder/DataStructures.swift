//
//  DataStructures.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import Foundation

enum SortOrder: String, CaseIterable, Identifiable {
    case nameAscending = "Name (A-Z)"
    case nameDescending = "Name (Z-A)"
    case sizeAscending = "Size (Smallest)"
    case sizeDescending = "Size (Largest)"
    
    var id: String { self.rawValue }
}


struct AmigaEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: EntryType
    let size: Int32
    let protectionBits: UInt32
    let date: Date?
    let comment: String?
    
    static func == (lhs: AmigaEntry, rhs: AmigaEntry) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum EntryType: String {
    case file = "File"
    case directory = "Directory"
    case softLinkFile = "Soft-Link File"
    case softLinkDir = "Soft-Link Dir"
    case unknown = "Unknown"
}
