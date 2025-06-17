//
//  PreferencesView.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI

struct PreferencesView: View {
    @AppStorage("autoEnableTabs") private var autoEnableTabs = false
    @AppStorage("rememberWindowSize") private var rememberWindowSize = false
    @AppStorage("downloadLocationBookmark") private var downloadLocationBookmark: Data?

    // State for displaying the resolved path
    @State private var downloadPath: String = ""

    var body: some View {
        
        HStack(alignment: .top, spacing: 20) {
            Image("prefs") // Using the existing 'prefs' asset.
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 15) {
                Text("General")
                    .font(.headline)
                
                Toggle("Auto enable tabs for new windows", isOn: $autoEnableTabs)
                Toggle("Remember window size and position", isOn: $rememberWindowSize)

                Divider()

                Text("Downloads")
                    .font(.headline)

                Text("Saved files will be placed here:")
                    .font(.caption)
                
                Text(downloadPath)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(5)

                HStack {
                    Button("Choose Location...") {
                        selectDownloadLocation()
                    }
                    Button("Reset to Default") {
                        downloadLocationBookmark = nil
                        updateDownloadPath()
                    }
                }

                Spacer()
            }
            .padding(.top, 5)
        }
        .padding(20)
        .frame(width: 520, height: 340)
        .onAppear(perform: updateDownloadPath)
    }

    private func updateDownloadPath() {
        if let bookmarkData = downloadLocationBookmark {
            do {
                var isStale = false
                // Resolve the URL from the bookmark data.
                let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                // If the bookmark data is stale, it's good practice to create a new one.
                if isStale {
                    self.downloadLocationBookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                }
                self.downloadPath = url.path
            } catch {
                // If the bookmark is invalid (e.g., the folder was deleted), reset to default.
                self.downloadPath = "Default (User's Downloads Folder)"
                self.downloadLocationBookmark = nil
            }
        } else {
            // No custom location is set, so display the default.
            self.downloadPath = "Default (User's Downloads Folder)"
        }
    }

    private func selectDownloadLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Choose Default Download Location"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                do {
                    // Create security-scoped bookmark data and save it to UserDefaults.
                    let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                    self.downloadLocationBookmark = bookmarkData
                    updateDownloadPath()
                } catch {
                    print("Error creating download location bookmark: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    PreferencesView()
}
