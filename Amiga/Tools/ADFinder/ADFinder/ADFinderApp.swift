
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
        
        Settings {
            PreferencesView()
        }
    }
}
