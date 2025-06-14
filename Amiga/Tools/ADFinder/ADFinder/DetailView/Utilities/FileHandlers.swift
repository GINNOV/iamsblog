//
//  FileHandlers.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/13/25.
//

import SwiftUI
import UniformTypeIdentifiers

extension DetailView {

    // MARK: - Core ADF Operations

    /// Reloads the contents of the current directory from the ADFService.
    func loadDirectoryContents() {
        guard selectedFile != nil else {
            currentEntries = []
            return
        }
        currentEntries = adfService.listCurrentDirectory()
        selectedEntryID = nil
    }

    /// Navigates to the parent directory.
    func goUpDirectory() {
        if adfService.goUpDirectory() {
            loadDirectoryContents()
        }
    }

    /// Handles a file being dropped onto the view.
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        // Handle ADF file types
        if provider.hasItemConformingToTypeIdentifier(ContentView.adfUType.identifier) {
            provider.loadItem(forTypeIdentifier: ContentView.adfUType.identifier, options: nil) { (item, error) in
                DispatchQueue.main.async {
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        self.selectedFile = url
                    } else if let url = item as? URL {
                        self.selectedFile = url
                    } else {
                        self.showAlert(message: "Could not read the dropped file.")
                    }
                }
            }
            return true
        }

        // Handle generic file URLs
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            _ = provider.loadObject(ofClass: URL.self) { (url, error) in
                DispatchQueue.main.async {
                    if let url = url { self.selectedFile = url }
                }
            }
            return true
        }
        return false
    }
    
    /// Opens and processes an ADF file from a URL.
    func processDroppedURL(_ url: URL) {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { url.stopAccessingSecurityScopedResource() } }

        if adfService.openADF(filePath: url.path) {
            loadDirectoryContents()
        } else {
            showAlert(message: "Failed to open or mount ADF: \"\(url.lastPathComponent)\". Check console for ADFlib errors.")
            selectedFile = nil
        }
    }
    
    /// Creates a new, blank ADF image.
    func createNewAdf() {
        if let newAdfUrl = adfService.createNewBlankADF(volumeName: "adfinder_vol1") {
            self.selectedFile = newAdfUrl
        } else {
            showAlert(message: "Failed to create a new blank ADF image.")
        }
    }
    
    /// Saves the currently open ADF to a new file.
    func saveAdf() {
        guard let url = selectedFile else { return }
        
        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            adfDocumentToSave = ADFDocument(data: data)
            showingFileExporter = true
        } catch {
            showAlert(message: "Could not read data from the current ADF file to save it: \(error.localizedDescription)")
        }
    }
    
    func handleFileExport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("Successfully saved ADF to \(url.path)")
            // If the user saves to a new file, we should probably treat that as the active file now.
            self.selectedFile = url
        case .failure(let error):
            showAlert(message: "Failed to save file: \(error.localizedDescription)")
        }
    }

    func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            var errors: [String] = []
            for url in urls {
                if let errorMessage = adfService.addFile(from: url) {
                    errors.append("Could not add \(url.lastPathComponent): \(errorMessage)")
                }
            }
            if !errors.isEmpty {
                showAlert(message: errors.joined(separator: "\n"))
            }
            loadDirectoryContents() // Refresh the view to show the new file(s)
        case .failure(let error):
            showAlert(message: "Failed to import files: \(error.localizedDescription)")
        }
    }

    // MARK: - Entry Actions

    /// Handles the action when a file or folder is double-clicked.
    func handleEntryTap(_ entry: AmigaEntry) {
        switch entry.type {
        case .directory:
            if adfService.navigateToDirectory(entry.name) {
                loadDirectoryContents()
            } else {
                showAlert(message: "Could not enter directory: \(entry.name)")
            }
        case .file:
            viewFileContent(entry)
        default:
            showAlert(message: "Cannot open item of type: \(entry.type.rawValue)")
        }
    }
    
    /// Reads a file's content from the ADF and prepares it for viewing.
    func viewFileContent(_ entry: AmigaEntry) {
        guard entry.type == .file else { return }
        selectedEntryForView = entry
        isLoadingFileContent = true
        loadingTask = Task {
            let data = adfService.readFileContent(entry: entry)
            await MainActor.run {
                guard !Task.isCancelled else { return }
                self.fileContentData = data
                self.isLoadingFileContent = false
                if data != nil {
                    self.showingFileViewer = true
                } else {
                    self.showAlert(message: "Could not read content for file: \(entry.name)")
                }
            }
        }
    }
    
    /// Creates a new folder in the current directory.
    func createFolder(name: String) {
        guard !name.isEmpty else {
            showAlert(message: "Folder name cannot be empty.")
            return
        }
        if let errorMessage = adfService.createDirectory(name: name, force: false) {
            showAlert(message: "Failed to create folder \"\(name)\": \(errorMessage)")
        } else {
            loadDirectoryContents()
        }
    }
    
    /// Deletes the specified file or folder.
    func deleteEntry(_ entry: AmigaEntry, force: Bool) {
        if let errorMessage = adfService.deleteEntryRecursively(entry: entry, force: force) {
            showAlert(message: "Failed to delete \"\(entry.name)\": \(errorMessage)")
        } else {
            loadDirectoryContents()
        }
    }
    
    /// Renames the specified entry.
    func renameEntry(entry: AmigaEntry, newName: String) {
        guard !newName.isEmpty else {
            showAlert(message: "New name cannot be empty.")
            return
        }
        if let errorMessage = adfService.renameEntry(oldName: entry.name, newName: newName) {
            showAlert(message: "Failed to rename \"\(entry.name)\": \(errorMessage)")
        } else {
            loadDirectoryContents()
        }
    }
    
    // MARK: - Alert & Dialog Presentation
    
    /// A generic helper to show an alert with a message.
    func showAlert(message: String) {
        self.alertMessage = message
        self.showingAlert = true
    }
    
    /// Shows a detailed info alert for a specific entry.
    func showInfoAlert(for entry: AmigaEntry) {
        var info = "Name: \(entry.name)\nType: \(entry.type.rawValue)\nSize: \(entry.size) bytes"
        if let date = entry.date {
            info += "\nDate: \(date.formatted(date: .long, time: .standard))"
        }
        if let comment = entry.comment, !comment.isEmpty {
            info += "\nComment: \(comment)"
        }
        info += "\nProtection: \(formatProtectionBits(entry.protectionBits))"
        showAlert(message: info)
    }
    
    /// Presents the generic confirmation dialog with a specific configuration.
    func presentConfirmation(config: ConfirmationConfig) {
        self.forceFlag = false // Reset state before showing dialog
        self.confirmationConfig = config
    }
}
