//
//  InfoDialogConfig.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/14/25.
//

import Foundation

struct InfoDialogConfig: Identifiable {
    let id = UUID()
    let entry: AmigaEntry
    
    var title: String {
        "Info: \(entry.name)"
    }
    
    var imageName: String {
        switch entry.type {
        case .file: return "doc.text.magnifyingglass"
        case .directory: return "folder.fill"
        default: return "questionmark.diamond.fill"
        }
    }
}
