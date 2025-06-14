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
    @State var currentEntries: [AmigaEntry] = []
    @State var selectedEntryID: AmigaEntry.ID?
    @State var alertMessage: String?
    @State var showingAlert = false
    
    @State var confirmationConfig: ConfirmationConfig?
    @State var inputDialogConfig: InputDialogConfig?
    @State var infoDialogConfig: InfoDialogConfig? // AI_REVIEW: New state for the info dialog.
    
    @State var forceFlag: Bool = false
    @State var showingAboutView = false
    @State var showingFileViewer = false
    @State var selectedEntryForView: AmigaEntry?
    @State var fileContentData: Data?
    @State private var showingFileImporter = false
    @State var isLoadingFileContent = false
    @State var loadingTask: Task<Void, Never>?
    @State private var isDetailViewTargetedForDrop = false
    @State var sortOrder: SortOrder = .nameAscending
    @State var showingFileExporter = false
    @State var adfDocumentToSave: ADFDocument?

    // A computed property to easily get the full AmigaEntry for the selected ID.
    var selectedEntry: AmigaEntry? {
        guard let selectedEntryID = selectedEntryID else { return nil }
        return currentEntries.first { $0.id == selectedEntryID }
    }
    
    private var detailActions: DetailToolbar.Actions {
        .init(
            newADF: {
                presentConfirmation(config: .newADF(action: createNewAdf))
            },
            saveADF: saveAdf,
            addFile: { showingFileImporter = true },
            newFolder: {
                inputDialogConfig = NewFolderDialogConfig.config { newName in
                    createFolder(name: newName)
                }
            },
            editVolumeName: {
                inputDialogConfig = RenameVolumeDialogConfig.config(currentName: adfService.volumeLabel) { newName in
                    if let errorMessage = adfService.renameVolume(newName: newName) {
                        showAlert(message: "Failed to rename volume: \(errorMessage)")
                    }
                }
            },
            // AI_REVIEW: This wires up the Get Info action.
            getInfo: {
                if let entry = selectedEntry {
                    infoDialogConfig = InfoDialogConfig(entry: entry)
                }
            },
            viewContent: {
                if let entry = selectedEntry { viewFileContent(entry) }
            },
            export: exportSelectedItem,
            rename: {
                if let entry = selectedEntry {
                    inputDialogConfig = RenameEntryDialogConfig.config(entry: entry) { newName in
                        renameEntry(entry: entry, newName: newName)
                    }
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
            sortedDirectories = directories.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            sortedFiles = files.sorted { $0.size < $1.size }
        case .sizeDescending:
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
        .confirmationSheet(config: $confirmationConfig, forceFlag: $forceFlag)
        .inputDialogSheet(config: $inputDialogConfig)
        .infoDialogSheet(config: $infoDialogConfig) // AI_REVIEW: Add the sheet modifier here.
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
        .focusedSceneValue(\.amigaActions, detailActions)
        .focusedSceneValue(\.isFileOpen, selectedFile != nil)
        .focusedSceneValue(\.isEntrySelected, selectedEntry != nil)
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
                    showInfoAlert: { entry in infoDialogConfig = InfoDialogConfig(entry: entry) }, // AI_REVIEW: Updated context menu action.
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
                actions: detailActions
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
