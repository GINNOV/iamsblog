//
//  SidebarView.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @Bindable var adfService: ADFService
    @Bindable var recentFilesService: RecentFilesService
    @Binding var selectedFile: URL?
    
    @State private var showingFileImporter = false
    
    private var currentPathString: String {
        (adfService.currentVolumeName ?? "No Volume") + ":" + (adfService.currentPath.isEmpty ? "" : adfService.currentPath.joined(separator: "/"))
    }
    
    var body: some View {
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
                Text(selectedFile?.lastPathComponent ?? "N/A")
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.bottom, 5)
                Text("VOLUME:")
                    .font(.headline)
                Text(currentPathString)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.bottom, 5)
            }
            
            Spacer()
            
            if selectedFile != nil {
                DiskInfoView(adfService: adfService)
                    .padding(.top)
            }
        }
        .padding()
        .navigationSplitViewColumnWidth(min: 280, ideal: 300, max: 500)
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [ContentView.adfUType], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                selectedFile = url
            case .failure(let error):
                print("Failed to select file: \(error.localizedDescription)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAdfFile)) { _ in
            showingFileImporter = true
        }
    }
}
