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
    @State private var selectedFile: URL?

    static let adfUType = UTType("public.retro.adf")!

    var body: some View {
        NavigationSplitView {
            SidebarView(
                adfService: adfService,
                selectedFile: $selectedFile
            )
        } detail: {
            DetailView(
                adfService: adfService,
                selectedFile: $selectedFile
            )
        }
    }
}
