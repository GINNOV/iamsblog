//
//  AboutView.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

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
            if let nsImage = NSApp.applicationIconImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
            } else {
                Image(systemName: "magnifyingglass.circle.fill")
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

            Text("An Amiga Disk File (ADF) Finder")
                .font(.caption)

            Divider()

            Text("Created by Mario Esposito")
                .font(.caption)

            VStack(alignment: .leading, spacing: 6) {
                Text("Contributions:")
                    .font(.caption.weight(.semibold))

                Text("🔌 Powered by ADFLib.")
                Text("🎨 Some icons by thiings.co")
                Text("❣️ Lots of love from the community that finds bugs and gives suggestions.")
            }
            .font(.caption)
            .padding(.bottom)

            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(30)
        .frame(minWidth: 320, idealWidth: 350)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
