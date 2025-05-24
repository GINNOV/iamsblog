//
//  DataStructures.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import Foundation

// Represents a file or directory entry in the ADF
struct AmigaEntry: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var type: EntryType
    var size: Int32 // Corresponds to AdfEntry.size (often uint32_t, cast needed)
    var protectionBits: UInt32 // Corresponds to AdfEntry.access (uint32_t)
    var date: Date? // Derived from AdfEntry.days, mins, ticks
    var comment: String? // From AdfEntry.comment
}

enum EntryType: Hashable {
    case file
    case directory
    case softLinkFile
    case softLinkDir
    case unknown
}

