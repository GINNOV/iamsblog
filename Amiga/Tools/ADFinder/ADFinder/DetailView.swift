//
//  DetailView.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct DetailView: View {
    @Bindable var adfService: ADFService
    @Binding var selectedFile: URL?
    
    // MARK: - State Variables
    @State private var currentEntries: [AmigaEntry] = []
    @State private var selectedEntryID: AmigaEntry.ID?
    @State private var alertMessage: String?
    @State private var showingAlert = false
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var entryToDelete: AmigaEntry?
    @State private var showingAboutView = false
    @State private var showingFileViewer = false
    @State private var selectedEntryForView: AmigaEntry?
    @State private var fileContentData: Data?
    @State private var isLoadingFileContent = false
    @State private var loadingTask: Task<Void, Never>?
    @State private var isDetailViewTargetedForDrop = false
    
    private var selectedEntry: AmigaEntry? {
        guard let selectedEntryID = selectedEntryID else { return nil }
        return currentEntries.first { $0.id == selectedEntryID }
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            mainContent
        }
        .sheet(item: $entryToDelete) { entry in
            DeleteConfirmationView(
                entry: entry,
                onConfirm: { force in
                    deleteEntry(entry, force: force)
                    entryToDelete = nil
                },
                onCancel: {
                    entryToDelete = nil
                }
            )
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder Name", text: $newFolderName)
                .autocorrectionDisabled()
            Button("Create") { createFolder(name: newFolderName) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enter a name for the new folder.")
        }
        .sheet(isPresented: $showingFileViewer) {
             if let entry = selectedEntryForView, let data = fileContentData { FileHexView(fileName: entry.name, data: data) }
        }
        .sheet(isPresented: $showingAboutView) {
            AboutView()
        }
        .alert("Notice", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "An unknown error occurred.")
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack {
            if selectedFile == nil {
                WelcomeView()
            } else {
                fileListView
            }
        }
        .navigationTitle(selectedFile?.lastPathComponent ?? "ADFinder")
        .toolbar { mainToolbar }
        .onDrop(of: [ContentView.adfUType, .fileURL], isTargeted: $isDetailViewTargetedForDrop) { providers in
            handleDrop(providers: providers)
        }
        .overlay(
            isDetailViewTargetedForDrop ?
                RoundedRectangle(cornerRadius: 10).stroke(Color.accentColor, lineWidth: 3).background(Color.accentColor.opacity(0.2)).padding(5)
                : nil
        )
        .overlay {
            if isLoadingFileContent {
                 LoadingSpinnerView(isLoading: $isLoadingFileContent, onCancel: {
                    loadingTask?.cancel()
                    isLoadingFileContent = false
                    loadingTask = nil
                 })
            }
        }
        .onChange(of: selectedFile) { _, newValue in
             if let newFile = newValue {
                 processDroppedURL(newFile)
             } else {
                 currentEntries = []
             }
        }
    }

    private var fileListView: some View {
        List(selection: $selectedEntryID) {
            if !adfService.currentPath.isEmpty {
                Button(action: goUpDirectory) {
                    Label(".. (Up one level)", systemImage: "arrow.up.left.circle.fill")
                }
                .selectionDisabled(true)
            }

            ForEach(currentEntries) { entry in
                FileRowView(entry: entry)
                    .onTapGesture(count: 2) { handleEntryTap(entry) }
                    .contextMenu {
                         Button("View Info") { showInfoAlert(for: entry) }
                         if entry.type == .file {
                             Button("View Content (Hex)") { viewFileContent(entry) }
                         }
                    }
                    .tag(entry.id)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .refreshable { loadDirectoryContents() }
    }
    
    private var mainToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if selectedFile != nil {
                Button(action: {
                    newFolderName = ""
                    showingNewFolderAlert = true
                }) {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
                
                Menu {
                    Button(action: {}) { Label("Hex Editor", systemImage: "number") }
                    Button(action: {}) { Label("Txt Editor", systemImage: "text.quote") }
                } label: {
                    Label("Edit", systemImage: "doc.text.magnifyingglass")
                }
                .disabled(selectedEntry?.type != .file)

                Button(action: {}) { Label("Export", systemImage: "square.and.arrow.up") }
                    .disabled(selectedEntryID == nil)

                Button(action: {}) { Label("Rename", systemImage: "pencil") }
                    .disabled(selectedEntryID == nil)

                Button(role: .destructive, action: {
                    if let entry = selectedEntry { entryToDelete = entry }
                }) {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedEntryID == nil)
            }
        }
    }
    
    // MARK: - Functions
    
    private func loadDirectoryContents() {
        guard selectedFile != nil else {
            currentEntries = []
            return
        }
        currentEntries = adfService.listCurrentDirectory()
        selectedEntryID = nil
    }

    private func goUpDirectory() {
        if adfService.goUpDirectory() {
            loadDirectoryContents()
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
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

    private func processDroppedURL(_ url: URL) {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { url.stopAccessingSecurityScopedResource() } }

        if adfService.openADF(filePath: url.path) {
            loadDirectoryContents()
        } else {
            showAlert(message: "Failed to open or mount ADF: \"\(url.lastPathComponent)\". Check console for ADFlib errors.")
            selectedFile = nil
        }
    }

    private func handleEntryTap(_ entry: AmigaEntry) {
        switch entry.type {
        case .directory:
            if adfService.navigateToDirectory(entry.name) { loadDirectoryContents() }
            else { showAlert(message: "Could not enter directory: \(entry.name)") }
        case .file:
            viewFileContent(entry)
        default:
            showAlert(message: "Cannot open item of type: \(entry.type)")
        }
    }
    
    private func viewFileContent(_ entry: AmigaEntry) {
        selectedEntryForView = entry
        isLoadingFileContent = true
        loadingTask = Task {
            let data = adfService.readFileContent(entry: entry)
            await MainActor.run {
                guard !Task.isCancelled else { return }
                self.fileContentData = data
                self.isLoadingFileContent = false
                if data != nil { self.showingFileViewer = true }
                else { self.showAlert(message: "Could not read content for file: \(entry.name)") }
            }
        }
    }
    
    private func createFolder(name: String) {
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
    
    private func deleteEntry(_ entry: AmigaEntry, force: Bool) {
        if let errorMessage = adfService.deleteEntryRecursively(entry: entry, force: force) {
            showAlert(message: "Failed to delete \"\(entry.name)\": \(errorMessage)")
        } else {
            loadDirectoryContents()
        }
    }
    
    private func showAlert(message: String) {
        self.alertMessage = message
        self.showingAlert = true
    }
    
    private func showInfoAlert(for entry: AmigaEntry) {
        var info = "Name: \(entry.name)\nType: \(entry.type)\nSize: \(entry.size) bytes"
        if let date = entry.date { info += "\nDate: \(date.formatted(date: .long, time: .standard))" }
        if let comment = entry.comment, !comment.isEmpty { info += "\nComment: \(comment)" }
        info += "\nProtection: \(formatProtectionBits(entry.protectionBits))"
        showAlert(message: info)
    }
    
    private func formatProtectionBits(_ bits: UInt32) -> String {
        let canRead = (bits & FIBF_READ_SWIFT) != 0; let canWrite = (bits & FIBF_WRITE_SWIFT) != 0
        let canExecute = (bits & FIBF_EXECUTE_SWIFT) != 0; let canDelete = (bits & FIBF_DELETE_SWIFT) != 0
        let hold = (bits & FIBF_HOLD_SWIFT) != 0; let script = (bits & FIBF_SCRIPT_SWIFT) != 0
        let pure = (bits & FIBF_PURE_SWIFT) != 0; let archive = (bits & FIBF_ARCHIVE_SWIFT) != 0
        return "R\(canRead ? "✔" : "-")W\(canWrite ? "✔" : "-")E\(canExecute ? "✔" : "-")D\(canDelete ? "✔" : "-") [hspa:\(hold ? "H" : "-")\(script ? "S" : "-")\(pure ? "P" : "-")\(archive ? "A" : "-")]"
    }
}
