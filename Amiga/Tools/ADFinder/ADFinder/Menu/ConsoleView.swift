//
//  ConsoleView.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/15/25.
//

import SwiftUI

struct ConsoleView: View {
    @Environment(LogStore.self) private var logStore
    
    private var logText: String {
        logStore.entries.joined()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with title and Clear button
            HStack {
                Text("ADFlib Console Log")
                    .font(.headline)
                    .padding(.leading)
                Spacer()
                Button("Clear") {
                    logStore.clear()
                }
                .padding()
            }
            .frame(height: 40)
            .background(.thinMaterial)

            
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    Text(logText)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(5)
                        .textSelection(.enabled)
                        .id("logContent") // ID for auto-scrolling
                }
                .onChange(of: logStore.entries) {
                    // Automatically scroll to the bottom when new entries are added.
                    withAnimation {
                        proxy.scrollTo("logContent", anchor: .bottom)
                    }
                }
            }
        }
        .frame(minWidth: 600, idealWidth: 800, minHeight: 300, idealHeight: 500)
    }
}
