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
    
    // The source of truth for the current directory's contents.
    @State var currentEntries: [AmigaEntry] = []
    
    // The ID of the currently selected file or folder in the list.
    @State var selectedEntryID: AmigaEntry.ID?
    
    // State for displaying alerts to the user.
    @State var alertMessage: String?
    @State var showingAlert = false

    // State for the "New Folder" dialog.
    @State var showingNewFolderAlert = false
    @State var newFolderName = ""

    // State for the generic confirmation dialog.
    @State var confirmationConfig: ConfirmationConfig?
    @State var forceFlag: Bool = false

    // State for the "Rename" dialog.
    @State var entryToRename: AmigaEntry?
    @State var newEntryName: String = ""

    // State for showing child views like the About screen or Hex Viewer.
    @State var showingAboutView = false
    @State var showingFileViewer = false
    @State var selectedEntryForView: AmigaEntry?
    @State var fileContentData: Data?
    @State private var showingFileImporter = false

    // State for managing long-running background tasks.
    @State var isLoadingFileContent = false
    @State var loadingTask: Task<Void, Never>?

    // State for drag & drop operations.
    @State private var isDetailViewTargetedForDrop = false
    
    // State for file list sorting.
    @State var sortOrder: SortOrder = .nameAscending

    @State var showingFileExporter = false
    @State var adfDocumentToSave: ADFDocument?

    // A computed property to easily get the full AmigaEntry for the selected ID.
    var selectedEntry: AmigaEntry? {
        guard let selectedEntryID = selectedEntryID else { return nil }
        // We search the unsorted list for the entry.
        return currentEntries.first { $0.id == selectedEntryID }
    }
    
    // Sorts the current entries based on the user's selection.
    // Directories are always sorted to the top.
    var sortedEntries: [AmigaEntry] {
        let directories = currentEntries.filter { $0.type == .directory }
        let files = currentEntries.filter { $0.type != .directory }

        let sortedDirectories: [AmigaEntry]
        let sortedFiles: [AmigaEntry]

        switch sortOrder {
        case .nameAscending:
            sortedDirectories = directories.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            sortedFiles = files.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            sortedDirectories = directories.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
            sortedFiles = files.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .sizeAscending:
            // Size doesn't apply to directories, so we just sort them by name.
            sortedDirectories = directories.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            sortedFiles = files.sorted { $0.size < $1.size }
        case .sizeDescending:
            // Size doesn't apply to directories, so we just sort them by name.
            sortedDirectories = directories.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            sortedFiles = files.sorted { $0.size > $1.size }
        }
        
        return sortedDirectories + sortedFiles
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            mainContent
        }
        .newFolderDialog(
            isPresented: $showingNewFolderAlert,
            newFolderName: $newFolderName,
            createAction: { createFolder(name: newFolderName) }
        )
        .renameDialog(
            entryToRename: $entryToRename,
            newEntryName: $newEntryName,
            renameAction: {
                if let entry = entryToRename {
                    renameEntry(entry: entry, newName: newEntryName)
                }
            }
        )
        .confirmationSheet(config: $confirmationConfig, forceFlag: $forceFlag)
        .sheet(isPresented: $showingFileViewer) {
             if let entry = selectedEntryForView, let data = fileContentData {
                 FileHexView(fileName: entry.name, data: data)
             }
        }
        .sheet(isPresented: $showingAboutView) {
            AboutView()
        }
        .alert("Notice", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "An unknown error occurred.")
        }
        .fileExporter(
            isPresented: $showingFileExporter,
            document: adfDocumentToSave,
            contentType: ContentView.adfUType
        ) { result in
            handleFileExport(result: result)
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.data],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result: result)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack {
            if selectedFile == nil {
                WelcomeView()
            } else {
                FileListView(
                    selectedEntryID: $selectedEntryID,
                    sortedEntries: sortedEntries,
                    currentPath: adfService.currentPath,
                    goUpDirectory: goUpDirectory,
                    handleEntryTap: handleEntryTap,
                    showInfoAlert: showInfoAlert,
                    viewFileContent: viewFileContent
                )
                .refreshable { loadDirectoryContents() }
            }
        }
        .navigationTitle(selectedFile?.lastPathComponent ?? "ADFinder")
        .toolbar {
            DetailToolbar(
                selectedFile: $selectedFile,
                sortOrder: $sortOrder,
                selectedEntry: selectedEntry,
                actions: .init(
                    newADF: {
                        presentConfirmation(config: .newADF(action: createNewAdf))
                    },
                    saveADF: saveAdf,
                    addFile: { showingFileImporter = true },
                    newFolder: {
                        newFolderName = ""
                        showingNewFolderAlert = true
                    },
                    viewContent: {
                        if let entry = selectedEntry { viewFileContent(entry) }
                    },
                    export: {

                    },
                    rename: {
                        if let entry = selectedEntry {
                            newEntryName = entry.name
                            entryToRename = entry
                        }
                    },
                    delete: {
                        if let entry = selectedEntry {
                            presentConfirmation(config: .delete(entry: entry, action: { force in
                                deleteEntry(entry, force: force)
                            }))
                        }
                    },
                    about: { showingAboutView = true }
                )
            )
        }
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
}
