//
//  ContentView.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI
import UniformTypeIdentifiers // Needed for UTType

struct ContentView: View {
    @State private var adfService = ADFService()
    @State private var showingFileImporter = false
    @State private var currentEntries: [AmigaEntry] = []
    @State private var selectedFile: URL?
    @State private var alertMessage: String?
    @State private var showingAlert = false
    
    @State private var selectedEntryForView: AmigaEntry?
    @State private var fileContentData: Data?
    @State private var showingFileViewer = false
    @State private var isLoadingFileContent = false
    @State private var loadingTask: Task<Void, Never>?
    
    @State private var isDetailViewTargetedForDrop = false
    
    static let adfUTType = UTType("public.retro.adf")!

    var currentPathString: String {
        (adfService.currentVolumeName ?? "No Volume") + ":" + (adfService.currentPath.isEmpty ? "" : adfService.currentPath.joined(separator: "/"))
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
                    DiskInfoView(adfService: adfService)
                        .padding(.top)
                }
            }
            .padding()
            .navigationSplitViewColumnWidth(min: 280, ideal: 300, max: 500)

        } detail: {
            // Main content view
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
                .onDrop(of: [.fileURL, Self.adfUTType], isTargeted: $isDetailViewTargetedForDrop) { providers in
                    return handleDrop(providers: providers)
                }
                .overlay(
                    isDetailViewTargetedForDrop ?
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.accentColor, lineWidth: 3)
                            .background(Color.accentColor.opacity(0.2))
                            .padding(5)
                        : nil
                )

                LoadingSpinnerView(
                    isLoading: $isLoadingFileContent,
                    onCancel: {
                        loadingTask?.cancel()
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
            AboutView()
        }
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        print("ContentView: Drop detected. Available types:", provider.registeredTypeIdentifiers)

        if provider.hasItemConformingToTypeIdentifier(Self.adfUTType.identifier) {
            provider.loadItem(forTypeIdentifier: Self.adfUTType.identifier, options: nil) { (item, error) in
                DispatchQueue.main.async {
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        print("ContentView: Successfully loaded file via custom UTI '\(Self.adfUTType.identifier)': \(url.path)")
                        self.processDroppedURL(url)
                    } else if let url = item as? URL {
                        print("ContentView: Loaded file as direct URL from custom UTI drop: \(url.path)")
                        self.processDroppedURL(url)
                    } else if error != nil {
                         self.showAlert(message: "Failed to load dropped file data: \(error!.localizedDescription)")
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
                    if let url = url {
                        print("ContentView: Successfully loaded file via fallback .fileURL type: \(url.path)")
                        self.processDroppedURL(url)
                    }
                }
            }
            return true
        }
        
        return false
    }

    func processDroppedURL(_ url: URL) {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        selectedFile = url
        
        if adfService.openADF(filePath: url.path) {
            loadDirectoryContents()
        } else {
            showAlert(message: "Failed to open or mount ADF: \"\(url.lastPathComponent)\". Check console for ADFlib errors.")
            selectedFile = nil
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
        isLoadingFileContent = true
        
        loadingTask = Task {
            let data = await Task.detached {
                return await adfService.readFileContent(entry: entry)
            }.value
            
            guard !Task.isCancelled else {
                isLoadingFileContent = false
                loadingTask = nil
                return
            }

            fileContentData = data
            isLoadingFileContent = false
            loadingTask = nil
            if data != nil {
                showingFileViewer = true
            } else {
                showAlert(message: "Could not read content for file: \(entry.name)")
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
        return "R\(canRead ? "✔" : "-")W\(canWrite ? "✔" : "-")E\(canExecute ? "✔" : "-")D\(canDelete ? "✔" : "-") [hspa:\(hold ? "H" : "-")\(script ? "S" : "-")\(pure ? "P" : "-")\(archive ? "A" : "-")]"
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
