//
//  ContentView.swift
//  ILBMViewer
//
//  Created by Mario Esposito on 6/18/25.
//

import SwiftUI
import UniformTypeIdentifiers // Needed for the file picker

struct ContentView: View {
    @State private var selectedImage: Image?
    @State private var isFileImporterPresented = false
    @State private var errorAlertMessage: String?
    
    // The loader instance and the manager for our recent files list
    private let imageLoader = IFFImageLoader()
    @StateObject private var recentFilesManager = RecentFilesManager()

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Amiga IFF Viewer")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Image Display Area
            ZStack {
                if let selectedImage {
                    selectedImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    // Placeholder view
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.15))
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Select an IFF image to display")
                        .foregroundColor(.gray)
                        .offset(y: 60)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color(white: 0.1))
            .cornerRadius(16)
            
            // Button controls
            HStack {
                // Main button to open the file picker
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("Open IFF File", systemImage: "folder.fill")
                }
                .buttonStyle(.borderedProminent)

                // Menu for recent files
                Menu {
                    if recentFilesManager.files.isEmpty {
                        Text("No Recent Files")
                    } else {
                        ForEach(recentFilesManager.files, id: \.self) { fileURL in
                            Button(fileURL.lastPathComponent) {
                                loadImage(from: fileURL)
                            }
                        }
                    }
                } label: {
                    Label("Recents", systemImage: "clock.fill")
                }
                .buttonStyle(.bordered)
                .disabled(recentFilesManager.files.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding()
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [UTType(filenameExtension: "iff")!, UTType(filenameExtension: "lbm")!],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    loadImage(from: url)
                }
            case .failure(let error):
                errorAlertMessage = "Failed to open file: \(error.localizedDescription)"
            }
        }
        .alert("Error", isPresented: .constant(errorAlertMessage != nil), actions: {
            Button("OK", role: .cancel) { errorAlertMessage = nil }
        }, message: {
            Text(errorAlertMessage ?? "An unknown error occurred.")
        })
    }
    
    /// Main logic to load and process a URL.
    private func loadImage(from url: URL) {
        // Start accessing the file. This is crucial for sandboxed apps.
        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard let cgImage = imageLoader.loadImage(from: url) else {
            errorAlertMessage = "Could not decode IFF image: \(url.lastPathComponent). The file may be corrupt or in an unsupported format."
            return
        }
        
        // Convert the CGImage to a SwiftUI Image and update the view
        #if os(macOS)
        selectedImage = Image(nsImage: NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height)))
        #else
        selectedImage = Image(uiImage: UIImage(cgImage: cgImage))
        #endif
        
        // Add the successfully opened file to the recents list
        recentFilesManager.add(url: url)
    }
}

#Preview {
    ContentView()
}
