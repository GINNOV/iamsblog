//
//  ContentView.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI
import UniformTypeIdentifiers // Needed for UTType

struct ContentView: View {
    @State private var adfService = ADFService() // Assumes ADFService is defined elsewhere
    @State private var showingFileImporter = false
    @State private var currentEntries: [AmigaEntry] = [] // Assumes AmigaEntry is defined elsewhere
    @State private var selectedFile: URL?
    @State private var alertMessage: String?
    @State private var showingAlert = false
    
    @State private var selectedEntryForView: AmigaEntry?
    @State private var fileContentData: Data?
    @State private var showingFileViewer = false
    @State private var isLoadingFileContent = false // State for loading spinner
    @State private var loadingTask: Task<Void, Never>? // Store the loading task for cancellation
    
    // For Drag and Drop
    @State private var isDetailViewTargetedForDrop = false // Specific to the detail view
    
    static let adfUTType = UTType(filenameExtension: "adf", conformingTo: .data) ?? .data

    var currentPathString: String {
        (adfService.currentVolumeName ?? "No Volume") + ":" + (adfService.currentPath.isEmpty ? "" : adfService.currentPath.joined(separator: "/")) + "/"
    }
    
    @State private var showingAboutView = false

    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(alignment: .leading) {
                HStack {
                       Image("disk_maker")
                           .resizable()
                           .scaledToFit()
                           .frame(width: 128, height: 128)
                       
                       Text("ADF.inder")
                           .font(.largeTitle)
                   }
                   .padding(.bottom)
                Button {
                    showingFileImporter = true
                } label: {
                    Label("Open ADF File", systemImage: "doc.badge.plus")
                }
                .padding(.bottom)

                if selectedFile != nil {
                     Text("Disk file:")
                        .font(.headline)
                     Text("\(selectedFile?.lastPathComponent ?? "N/A")")
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.bottom, 5)
                     Text("VOLUME:")
                        .font(.headline)
                     Text("\(currentPathString)")
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                if selectedFile != nil {
                    DiskInfoView(adfService: adfService) // Using the separate DiskInfoView
                        .padding(.top)
                }
            }
            .padding()
            .navigationSplitViewColumnWidth(min: 280, ideal: 300, max: 500)

        } detail: {
            // Main content view for file listing - THIS IS THE DROP TARGET
            ZStack {
                VStack {
                    if selectedFile == nil {
                        VStack {
                            Image(systemName: "archivebox.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.secondary)
                                .padding()
                            Text("Please open or drop an ADF file here.")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            if !adfService.currentPath.isEmpty {
                                Button {
                                    if adfService.goUpDirectory() {
                                        loadDirectoryContents()
                                    }
                                } label: {
                                    Label(".. (Up one level)", systemImage: "arrow.up.left.circle.fill")
                                }
                            }

                            ForEach(currentEntries) { entry in
                                HStack {
                                    Image(systemName: iconForEntry(entry.type))
                                        .foregroundColor(colorForEntry(entry.type))
                                    Text(entry.name)
                                    Spacer()
                                    if entry.type == .file {
                                        Text("\(entry.size) bytes")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture { handleEntryTap(entry) }
                                .contextMenu {
                                     Button("View Info") { showInfoAlert(for: entry) }
                                     if entry.type == .file {
                                         Button("View Content (Hex)") { viewFileContent(entry) }
                                     }
                                }
                            }
                        }
                        .listStyle(.inset(alternatesRowBackgrounds: true))
                        .refreshable { loadDirectoryContents() }
                    }
                }
                .navigationTitle(selectedFile?.lastPathComponent ?? "ADFinder")
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        Button { showingFileImporter = true } label: { Label("Open ADF", systemImage: "folder") }
                            .disabled(showingFileImporter)
                    }
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button { showingAboutView = true } label: { Label("About ADFinder", systemImage: "info.circle") }
                    }
                }
                .onDrop(of: [Self.adfUTType, .fileURL], isTargeted: $isDetailViewTargetedForDrop) { providers -> Bool in
                    handleDrop(providers: providers)
                }
                .overlay(
                    isDetailViewTargetedForDrop ?
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.accentColor, lineWidth: 3)
                            .background(Color.accentColor.opacity(0.2))
                            .padding(5)
                        : nil
                )

                // Use the new LoadingSpinnerView
                LoadingSpinnerView(
                    isLoading: $isLoadingFileContent,
                    onCancel: {
                        loadingTask?.cancel() // Cancel the loading task
                        isLoadingFileContent = false
                        loadingTask = nil
                    }
                )
            }
        }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [Self.adfUTType], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                processDroppedURL(url)
            case .failure(let error):
                showAlert(message: "Failed to select file: \(error.localizedDescription)")
            }
        }
        .alert(alertMessage ?? "Error", isPresented: $showingAlert) { Button("OK", role: .cancel) {} }
        .sheet(isPresented: $showingFileViewer) {
             if let entry = selectedEntryForView, let data = fileContentData { FileHexView(fileName: entry.name, data: data) }
        }
        .sheet(isPresented: $showingAboutView) {
            AboutView() // Using the separate AboutView
        }
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else {
            return false
        }

        print("ContentView: Drop detected. Provider: \(provider)")

        if provider.canLoadObject(ofClass: URL.self) {
            _ = provider.loadObject(ofClass: URL.self) { (item, error) in
                DispatchQueue.main.async {
                    guard let url = item else {
                        if let error = error {
                            self.showAlert(message: "Error loading dropped item as URL: \(error.localizedDescription)")
                            print("ContentView: Error loading dropped item as URL: \(error)")
                        } else {
                            self.showAlert(message: "Could not retrieve URL from dropped item.")
                            print("ContentView: Could not retrieve URL from dropped item.")
                        }
                        return
                    }
                    
                    print("ContentView: Dropped URL: \(url.path)")
                    if url.pathExtension.lowercased() == "adf" {
                        self.processDroppedURL(url)
                    } else {
                        self.showAlert(message: "Dropped file '\(url.lastPathComponent)' is not a recognized ADF file (requires .adf extension).")
                        print("ContentView: Dropped file is not an ADF: \(url.lastPathComponent)")
                    }
                }
            }
            return true
        } else {
            print("ContentView: Provider cannot load as URL.")
        }
        
        if provider.hasItemConformingToTypeIdentifier(Self.adfUTType.identifier) {
            print("ContentView: Provider conforms to adfUTType. Attempting to load data representation.")
            provider.loadDataRepresentation(forTypeIdentifier: Self.adfUTType.identifier) { (data, error) in
                DispatchQueue.main.async {
                    guard let data = data, let suggestedName = provider.suggestedName else {
                        if let error = error {
                            self.showAlert(message: "Error loading dropped data: \(error.localizedDescription)")
                            print("ContentView: Error loading dropped data: \(error)")
                        } else {
                             self.showAlert(message: "Could not retrieve data from dropped item.")
                             print("ContentView: Could not retrieve data from dropped item for adfUTType.")
                        }
                        return
                    }
                    print("ContentView: Dropped data for \(suggestedName). Saving to temporary file.")
                    let tempDir = FileManager.default.temporaryDirectory
                    let tempURL = tempDir.appendingPathComponent(suggestedName)
                    
                    do {
                        try data.write(to: tempURL, options: .atomic)
                        print("ContentView: Successfully saved dropped data to \(tempURL.path)")
                        self.processDroppedURL(tempURL)
                    } catch {
                        self.showAlert(message: "Could not save dropped data to a temporary file: \(error.localizedDescription)")
                        print("ContentView: Could not save dropped data to temp file: \(error)")
                    }
                }
            }
            return true
        } else {
            print("ContentView: Provider does not conform to adfUTType directly.")
        }
        
        return false
    }

    func processDroppedURL(_ url: URL) {
        print("ContentView: Processing URL: \(url.path)")
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        if !didStartAccessing {
            print("ContentView: Warning - Could not start accessing security-scoped resource for \(url.path). This might lead to fopen failure in ADFlib if sandbox is restrictive.")
        }

        selectedFile = url
        
        if adfService.openADF(filePath: url.path(percentEncoded: false)) {
            print("ContentView: ADFService successfully opened \(url.path)")
            loadDirectoryContents()
        } else {
            print("ContentView: ADFService failed to open \(url.path)")
            showAlert(message: "Failed to open or mount ADF: \"\(url.lastPathComponent)\". Check console for ADFlib errors. Common issues: file not found by ADFlib (permissions/sandbox) or corrupted ADF.")
            selectedFile = nil
        }
        
        if didStartAccessing {
            url.stopAccessingSecurityScopedResource()
        }
    }

    func loadDirectoryContents() { currentEntries = adfService.listCurrentDirectory() }
    func handleEntryTap(_ entry: AmigaEntry) {
        switch entry.type {
        case .directory:
            if adfService.navigateToDirectory(entry.name) { loadDirectoryContents() }
            else { showAlert(message: "Could not enter directory: \(entry.name)") }
        case .file: viewFileContent(entry)
        default: showAlert(message: "Cannot open item of type: \(entry.type)")
        }
    }
    func viewFileContent(_ entry: AmigaEntry) {
        selectedEntryForView = entry
        isLoadingFileContent = true // Show spinner
        
        // Run file reading asynchronously with cancellation support
        loadingTask = Task {
            do {
                let data = try await withCheckedThrowingContinuation { continuation in
                    let result = adfService.readFileContent(entry: entry)
                    continuation.resume(returning: result)
                }
                
                // Check if the task was cancelled
                try Task.checkCancellation()
                
                DispatchQueue.main.async {
                    isLoadingFileContent = false // Hide spinner
                    loadingTask = nil
                    fileContentData = data
                    if data != nil {
                        showingFileViewer = true
                    } else {
                        showAlert(message: "Could not read content for file: \(entry.name)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isLoadingFileContent = false // Hide spinner
                    loadingTask = nil
                    if error is CancellationError {
                        print("File loading cancelled for \(entry.name)")
                    } else {
                        showAlert(message: "Could not read content for file: \(entry.name)")
                    }
                }
            }
        }
    }
    func showAlert(message: String) { alertMessage = message; showingAlert = true }
    func showInfoAlert(for entry: AmigaEntry) {
        var info = "Name: \(entry.name)\nType: \(entry.type)\nSize: \(entry.size) bytes"
        if let date = entry.date { info += "\nDate: \(date.formatted(date: .long, time: .standard))" }
        if let comment = entry.comment, !comment.isEmpty { info += "\nComment: \(comment)" }
        info += "\nProtection: \(formatProtectionBits(entry.protectionBits))"
        showAlert(message: info)
    }
    func formatProtectionBits(_ bits: UInt32) -> String {
        let canRead = (bits & FIBF_READ_SWIFT) != 0; let canWrite = (bits & FIBF_WRITE_SWIFT) != 0
        let canExecute = (bits & FIBF_EXECUTE_SWIFT) != 0; let canDelete = (bits & FIBF_DELETE_SWIFT) != 0
        let hold = (bits & FIBF_HOLD_SWIFT) != 0; let script = (bits & FIBF_SCRIPT_SWIFT) != 0
        let pure = (bits & FIBF_PURE_SWIFT) != 0; let archive = (bits & FIBF_ARCHIVE_SWIFT) != 0
        return "R\(canRead ? "✔" : "-") W\(canWrite ? "✔" : "-") E\(canExecute ? "✔" : "-") D\(canDelete ? "✔" : "-") [H:\(hold ? "✔" : "-"), S:\(script ? "✔" : "-"), P:\(pure ? "✔" : "-"), A:\(archive ? "✔" : "-")]"
    }
    func iconForEntry(_ type: EntryType) -> String {
        switch type {
        case .file: return "doc.fill"; case .directory: return "folder.fill"
        case .softLinkFile, .softLinkDir: return "link"; default: return "questionmark.diamond.fill"
        }
    }
    func colorForEntry(_ type: EntryType) -> Color {
        switch type {
        case .file: return .blue; case .directory: return .orange
        case .softLinkFile, .softLinkDir: return .purple; default: return .gray
        }
    }
}
