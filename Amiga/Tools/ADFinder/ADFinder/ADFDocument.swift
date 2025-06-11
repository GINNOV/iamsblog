//
//  ADFDocument.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ADFDocument: FileDocument {
    // This defines the types of files our document can handle.
    static var readableContentTypes: [UTType] { [ContentView.adfUType] }
    
    // The raw data of the ADF file.
    var data: Data
    
    // Initialize a blank document.
    init(data: Data = Data()) {
        self.data = data
    }
    
    // Initialize from a file on disk.
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    // Create a FileWrapper to save the document to disk.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}
