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
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            Image("prefs") // Using the existing 'prefs' asset.
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 15) {
                Text("General")
                    .font(.headline)
                
                Toggle("Auto enable tabs for new windows", isOn: $autoEnableTabs)
                Toggle("Remember window size and position", isOn: $rememberWindowSize)

                Divider()

                Text("Updates")
                    .font(.headline)
                
                Link("Check for new versions on GitHub...", destination: URL(string: "https://github.com/GINNOV/littlethings/tree/master/Amiga/Tools/ADFinder")!)
                    .foregroundColor(.accentColor)
                
                Spacer()
            }
        }
        .padding(20)
        .frame(width: 480, height: 180)
    }
}

#Preview {
    PreferencesView()
}
