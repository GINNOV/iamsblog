//
//  ADFDocument.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ADFDocument: FileDocument {
    static var readableContentTypes: [UTType] { [ContentView.adfUType] }
    
    var data: Data
    var volumeName: String?
    var defaultFileName: String? {
        guard let volumeName = volumeName, !volumeName.isEmpty else {
            return "Untitled.adf"
        }
        // Sanitize the name to make it a valid filename.
        let invalidChars = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        let cleanName = volumeName.components(separatedBy: invalidChars).joined(separator: "_")
        return "\(cleanName).adf"
    }

    init(data: Data = Data(), volumeName: String? = nil) {
        self.data = data
        self.volumeName = volumeName
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
        // When reading, we don't know the volume name yet, so it remains nil.
        self.volumeName = nil
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}
