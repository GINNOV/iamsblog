//
//  DetailView.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct DetailView: View {
        @Environment(\.openWindow) private var openWindow
    @Bindable var adfService: ADFService
    @Bindable var recentFilesService: RecentFilesService
    @Binding var selectedFile: URL?

    @State var currentEntries: [AmigaEntry] = []
    @State var selectedEntryID: AmigaEntry.ID?
    @State var alertMessage: String?
    @State var showingAlert = false
    @State var confirmationConfig: ConfirmationConfig?
    @State var inputDialogConfig: InputDialogConfig?
    @State var infoDialogConfig: InfoDialogConfig?
    @State var newAdfConfig: NewADFDialogConfig?
    @State var setPermissionsConfig: SetPermissionsDialogConfig?
    @State var forceFlag: Bool = false
    @State var showingAboutView = false
    @State var showingFileViewer = false
    @State var selectedEntryForView: AmigaEntry?
    @State var fileContentData: Data?
    @State var showingTextViewer = false
    @State var selectedEntryForTextEdit: AmigaEntry?
    @State var textFileContent: String = ""
    @State private var showingFileImporter = false
    @State var isLoadingFileContent = false
    @State var loadingTask: Task<Void, Never>?
    @State private var isDetailViewTargetedForDrop = false
    @State var sortOrder: SortOrder = .nameAscending
    @State var showingFileExporter = false
    @State var adfDocumentToSave: ADFDocument?
    
    var selectedEntry: AmigaEntry? {
        guard let selectedEntryID = selectedEntryID else { return nil }
        return currentEntries.first { $0.id == selectedEntryID }
    }
    
    private var detailActions: DetailToolbar.Actions {
        .init(
            newADF: {
                newAdfConfig = NewADFDialogConfig(action: { volumeName, fsType in
                    createNewAdf(volumeName: volumeName, fsType: fsType)
                })
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
            getInfo: {
                if let entry = selectedEntry {
                    infoDialogConfig = InfoDialogConfig(entry: entry)
                }
            },
            setPermissions: {
                if let entry = selectedEntry {
                    setPermissionsConfig = SetPermissionsDialogConfig(
                        entryName: entry.name,
                        initialBits: entry.protectionBits,
                        action: { newBits in
                            if let errorMsg = adfService.setProtectionBits(for: entry, newBits: newBits) {
                                showAlert(message: "Failed to set permissions: \(errorMsg)")
                            }
                            loadDirectoryContents()
                        }
                    )
                }
            },
            viewContent: {
                if let entry = selectedEntry { viewFileContent(entry) }
            },
            viewAsText: {
                if let entry = selectedEntry { viewTextContent(entry) }
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
            about: { showingAboutView = true },
                        showConsole: { openWindow(id: "console-window") },
            showComparator: { openWindow(id: "compare-window") }
        )
    }
    
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

    var body: some View {
        ZStack {
            mainContent
        }
        .confirmationSheet(config: $confirmationConfig, forceFlag: $forceFlag)
        .inputDialogSheet(config: $inputDialogConfig)
        .infoDialogSheet(config: $infoDialogConfig)
        .newAdfDialogSheet(config: $newAdfConfig)
        .setPermissionsDialogSheet(config: $setPermissionsConfig)
        .sheet(isPresented: $showingFileViewer) {
            if let entry = selectedEntryForView, let data = fileContentData {
                FileHexView(fileName: entry.name, data: data)
            }
        }
        .sheet(isPresented: $showingTextViewer) {
            if let entry = selectedEntryForTextEdit {
                FileTextView(fileName: entry.name, textContent: $textFileContent) {
                    saveTextContent()
                }
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
            contentType: ContentView.adfUType,
            defaultFilename: adfDocumentToSave?.defaultFileName
        ) { result in
            handleFileExport(result: result)
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [UTType.data],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result: result)
        }
        .focusedSceneValue(\.amigaActions, detailActions)
        .focusedSceneValue(\.isFileOpen, selectedFile != nil)
        .focusedSceneValue(\.isEntrySelected, selectedEntry != nil)
                .onReceive(NotificationCenter.default.publisher(for: .showAboutWindow)) { _ in
            showingAboutView = true
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
                    showInfoAlert: { entry in infoDialogConfig = InfoDialogConfig(entry: entry) },
                    viewFileContent: viewFileContent,
                    viewAsText: viewTextContent,
                                        handleMove: handleMove,
                                        handleMoveToParent: handleMoveToParent
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
        .onDrop(of: [ContentView.adfUType, UTType.fileURL], isTargeted: $isDetailViewTargetedForDrop) { providers in
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
                recentFilesService.addRecentFile(newFile)
            } else {
                currentEntries = []
            }
        }
    }
}
