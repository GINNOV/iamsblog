//
//  ContentView.swift
//  ILBMViewer
//
//  Created by Mario Esposito on 6/18/25.
//

import SwiftUI
import UniformTypeIdentifiers
import CoreGraphics

// --- Supporting Classes ---
// Placed here to ensure they are in scope and defined only once.

/// Decodes IFF image data. This is now a class with an INSTANCE method,
/// matching the structure required by your ContentView.
class IFFImageLoader {
    /// Loads data from a URL and attempts to create a CGImage.
    /// In a real app, this would involve complex parsing of the IFF format.
    func loadImage(from url: URL) -> CGImage? {
        // This is a placeholder implementation. A real IFF parser is complex
        // and would decode the BMHD, CMAP, and BODY chunks to build the image.
        // For now, we return a simple placeholder gradient to show success.
        
        // A minimal check to simulate reading width/height from a file.
        // We'll just create a fixed-size placeholder.
        guard let data = try? Data(contentsOf: url), data.count > 20 else { return nil }
        
        let width = 320
        let height = 200
        
        let bitsPerComponent = 8
        let bytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        
        // Draw a simple gradient to prove it worked.
        let colors = [CGColor(red: 0.1, green: 0.1, blue: 0.8, alpha: 1), CGColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1)] as CFArray
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) else {
            return nil
        }
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: width, y: height), options: [])
        
        return context.makeImage()
    }
}


// --- Main View ---

struct ContentView: View {
    @State private var selectedImage: Image?
    @State private var isFileImporterPresented = false
    @State private var errorAlertMessage: String?
    
    // --- FIX: These are now properly initialized with the classes defined above.
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
        
        // --- FIX: This now correctly calls the method on the INSTANCE `imageLoader`.
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
