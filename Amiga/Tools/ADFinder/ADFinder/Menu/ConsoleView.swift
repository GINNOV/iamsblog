//
//  ConsoleView.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/15/25.
//

import SwiftUI

struct ConsoleView: View {
    // Access the shared log store from the environment.
    @Environment(LogStore.self) private var logStore
    
    // A computed property to join all log entries into a single string.
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

            // The main text view for logs
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    Text(logText)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(5)
                        .id("logContent") // An ID to allow scrolling to the bottom
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
