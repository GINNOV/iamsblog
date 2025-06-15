//
//  ContentView.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var adfService = ADFService()
    @Bindable var recentFilesService: RecentFilesService

    @State private var selectedFile: URL?

    static let adfUType = UTType("public.retro.adf")!

    var body: some View {
        NavigationSplitView {
        
            SidebarView(
                adfService: adfService,
                recentFilesService: recentFilesService,
                selectedFile: $selectedFile
            )
        } detail: {
            
            DetailView(
                adfService: adfService,
                recentFilesService: recentFilesService,
                selectedFile: $selectedFile
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSpecificAdfFile)) { notification in
            if let url = notification.object as? URL {
                self.selectedFile = url
            }
        }
    }
}
