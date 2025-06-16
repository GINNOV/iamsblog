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
    
        func handleMoveToParent(sourceEntryID: AmigaEntry.ID) {
        guard let sourceEntry = currentEntries.first(where: { $0.id == sourceEntryID }) else {
            showAlert(message: "Could not find the source item to move.")
            return
        }

        if let errorMessage = adfService.moveEntryToParent(entryNameToMove: sourceEntry.name) {
            showAlert(message: "Failed to move item up: \(errorMessage)")
        } else {
            loadDirectoryContents()
        }
    }
    
        func handleMove(sourceEntryID: AmigaEntry.ID, destinationEntry: AmigaEntry) {
        // Find the source entry from the ID.
        guard let sourceEntry = currentEntries.first(where: { $0.id == sourceEntryID }) else {
            showAlert(message: "Could not find the source item to move.")
            return
        }

        // Prevent illogical moves: dropping an item onto itself or onto a file.
        if sourceEntry.id == destinationEntry.id || destinationEntry.type != .directory {
            return
        }
        
        // Call the ADFService to perform the actual move.
        if let errorMessage = adfService.moveEntry(entryNameToMove: sourceEntry.name, toDestinationDirName: destinationEntry.name) {
            showAlert(message: "Failed to move item: \(errorMessage)")
        } else {
            // If the move is successful, reload the directory contents to reflect the change.
            loadDirectoryContents()
        }
    }

    func loadDirectoryContents() {
        guard selectedFile != nil else {
            currentEntries = []
            return
        }
        currentEntries = adfService.listCurrentDirectory()
        selectedEntryID = nil
    }

    func goUpDirectory() {
        if adfService.goUpDirectory() {
            loadDirectoryContents()
        }
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
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
    
    func createNewAdf(volumeName: String, fsType: UInt8) {
        if let newAdfUrl = adfService.createNewBlankADF(volumeName: volumeName, fsType: fsType) {
            self.selectedFile = newAdfUrl
        } else {
            showAlert(message: "Failed to create a new blank ADF image.")
        }
    }
    
    func saveAdf() {
        guard let url = selectedFile else { return }
        
        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            adfDocumentToSave = ADFDocument(data: data, volumeName: adfService.volumeLabel)
            showingFileExporter = true
        } catch {
            showAlert(message: "Could not read data from the current ADF file to save it: \(error.localizedDescription)")
        }
    }
    
    func handleFileExport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("Successfully saved ADF to \(url.path)")
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
            loadDirectoryContents()
        case .failure(let error):
            showAlert(message: "Failed to import files: \(error.localizedDescription)")
        }
    }

    // MARK: - Entry Actions

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
    
    func viewTextContent(_ entry: AmigaEntry) {
        guard entry.type == .file else { return }
        
        selectedEntryForTextEdit = entry
        isLoadingFileContent = true
        
        loadingTask = Task {
            guard let data = adfService.readFileContent(entry: entry) else {
                await MainActor.run {
                    showAlert(message: "Could not read data for \(entry.name).")
                    isLoadingFileContent = false
                }
                return
            }
            
            // Attempt to decode as Amiga's standard text encoding.
            let string = String(data: data, encoding: .isoLatin1) ?? ""
            
            await MainActor.run {
                guard !Task.isCancelled else { return }
                self.textFileContent = string
                self.isLoadingFileContent = false
                self.showingTextViewer = true
            }
        }
    }
    
    func saveTextContent() {
        guard let entry = selectedEntryForTextEdit else { return }
        
        if let errorMessage = adfService.writeTextFile(entry: entry, content: textFileContent) {
            showAlert(message: "Failed to save file: \(errorMessage)")
        } else {
            // Success, refresh the directory to show updated size
            loadDirectoryContents()
        }
    }
    
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
    
    func deleteEntry(_ entry: AmigaEntry, force: Bool) {
        if let errorMessage = adfService.deleteEntryRecursively(entry: entry, force: force) {
            showAlert(message: "Failed to delete \"\(entry.name)\": \(errorMessage)")
        } else {
            loadDirectoryContents()
        }
    }
    
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
    
    func exportSelectedItem() {
        guard let selectedEntry = selectedEntry else {
            showAlert(message: "No item selected to export.")
            return
        }

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Choose destination for \"\(selectedEntry.name)\""
        panel.message = "The selected item will be exported into the folder you choose."
        panel.prompt = "Export Here"

        panel.begin { response in
            if response == .OK, let destinationURL = panel.url {
                DispatchQueue.global(qos: .userInitiated).async {
                    let errorMessage = self.adfService.exportEntry(entry: selectedEntry, toDirectory: destinationURL)
                    
                    DispatchQueue.main.async {
                        if let errorMessage = errorMessage {
                            self.showAlert(message: "Export failed: \(errorMessage)")
                        } else {
                            self.showAlert(message: "'\(selectedEntry.name)' was successfully exported.")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Alert & Dialog Presentation
    
    func showAlert(message: String) {
        self.alertMessage = message
        self.showingAlert = true
    }
    
    func showInfoAlert(for entry: AmigaEntry) {
        self.infoDialogConfig = InfoDialogConfig(entry: entry)
    }
    
    func presentConfirmation(config: ConfirmationConfig) {
        self.forceFlag = false
        self.confirmationConfig = config
    }
}
