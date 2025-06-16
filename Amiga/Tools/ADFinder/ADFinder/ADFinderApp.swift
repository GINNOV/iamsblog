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
    @State private var logStore = LogStore.shared
    
    @Environment(\.openWindow) private var openWindow

    static let adfUType = UTType("public.retro.adf")!
    
    var body: some Scene {
        WindowGroup {
            ContentView(recentFilesService: recentFilesService)
                .environment(logStore)
        }
        .commands {
            AmigaMenuCommands()
            
                        CommandGroup(replacing: .appInfo) {
                Button("About ADFinder") {
                    // : Posting a notification is a clean way to trigger an action
                    // in a view that isn't directly in the hierarchy. #END_REVIEW
                    NotificationCenter.default.post(name: .showAboutWindow, object: nil)
                }
            }
            
            CommandGroup(replacing: .importExport) {
                Button("Open ADF...") {
                    NotificationCenter.default.post(name: .openAdfFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            
            CommandGroup(after: .importExport) {
                Menu("Open Recent") {
                    ForEach(recentFilesService.recentFiles, id: \.self) { url in
                        Button(url.lastPathComponent) {
                            NotificationCenter.default.post(name: .openSpecificAdfFile, object: url)
                        }
                    }
                    
                    if !recentFilesService.recentFiles.isEmpty {
                        Divider()
                        Button("Clear Menu") {
                            recentFilesService.clearRecents()
                        }
                    }
                }
            }

            CommandGroup(after: .windowList) {
                Button("Show ADFlib Console") {
                    openWindow(id: "console-window")
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                
                Button("Show Disk Comparator") {
                    openWindow(id: "compare-window")
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }
        
        Settings {
            PreferencesView()
        }
        
        Window("ADFlib Console", id: "console-window") {
            ConsoleView()
                .environment(logStore)
        }
        
        Window("ADF Disk Comparator", id: "compare-window") {
            ADFCompareView()
        }
    }
}
