//
//  AboutView.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI // Added import

struct AboutView: View {
    @Environment(\.dismiss) var dismiss // To close the sheet

    // These will get the values from your app's Info.plist
    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
    }
    var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A"
    }
    var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "ADFinder"
    }

    var body: some View {
        VStack(spacing: 15) {
            // You can add your app icon to Assets.xcassets and use Image("YourAppIconName")
            // For now, using a system image or the app's actual icon.
            if let nsImage = NSApp.applicationIconImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
            } else {
                Image(systemName: "magnifyingglass.circle.fill") // Fallback system image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.accentColor)
            }
            
            Text(appName)
                .font(.title2.weight(.semibold))
            
            Text("Version \(appVersion) (Build \(buildNumber))")
                .font(.callout)
                .foregroundColor(.secondary)
            
            Text("An Amiga Disk File (ADF) Browser")
                .font(.caption)
            
            Divider()
            
            Text("Created by Mario Esposito")
                .font(.caption)
            
            Text("Powered by ADFLib")
                .font(.caption)
                .padding(.bottom)

            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction) // Allows Esc key to close
        }
        .padding(30)
        .frame(minWidth: 320, idealWidth: 350, minHeight: 300, idealHeight: 350)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
