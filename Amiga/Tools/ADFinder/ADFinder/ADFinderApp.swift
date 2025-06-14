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
    
    static let adfUType = UTType("public.retro.adf")!
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            AmigaMenuCommands()
            
            CommandGroup(replacing: .importExport) {
                Button("Open ADF...") {
                    NotificationCenter.default.post(name: .openAdfFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
        
        Settings {
            PreferencesView()
        }
    }
}
