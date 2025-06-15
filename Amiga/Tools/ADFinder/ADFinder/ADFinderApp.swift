//
//  ADFinderApp.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct ADFinderApp: App {
    @AppStorage("rememberWindowSize") private var rememberWindowSize = false
    @AppStorage("autoEnableTabs") private var autoEnableTabs = false
    
    @State private var recentFilesService = RecentFilesService()

    static let adfUType = UTType("public.retro.adf")!
    
    var body: some Scene {
        WindowGroup {
            ContentView(recentFilesService: recentFilesService)
        }
        .commands {
            AmigaMenuCommands()
            
            CommandGroup(replacing: .importExport) {
                Button("Open ADF...") {
                    NotificationCenter.default.post(name: .openAdfFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            
            CommandGroup(after: .importExport) {
                Menu("Open Recent") {
                    // Dynamically create a menu item for each recent file.
                    ForEach(recentFilesService.recentFiles, id: \.self) { url in
                        Button(url.lastPathComponent) {
                            // Post a notification with the URL to open.
                            NotificationCenter.default.post(name: .openSpecificAdfFile, object: url)
                        }
                    }
                    
                    // Add the "Clear Menu" item if the list is not empty.
                    if !recentFilesService.recentFiles.isEmpty {
                        Divider()
                        Button("Clear Menu") {
                            recentFilesService.clearRecents()
                        }
                    }
                }
            }
        }
        
        Settings {
            PreferencesView()
        }
    }
}
