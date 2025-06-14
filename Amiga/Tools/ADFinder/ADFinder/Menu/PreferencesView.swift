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
        Form {
            Section(header: Text("General")) {
                Toggle("Auto enable tabs", isOn: $autoEnableTabs)
                Toggle("Remember window size", isOn: $rememberWindowSize)
            }
            
            Divider()
            
            Section(header: Text("Updates")) {

                Link("Show new feature list on GitHub", destination: URL(string: "https://github.com/GINNOV/littlethings/tree/master/Amiga/Tools/ADFinder")!)
            }
        }
        .padding(20)
        .frame(width: 350, height: 150)
    }
}

#Preview {
    PreferencesView()
}
