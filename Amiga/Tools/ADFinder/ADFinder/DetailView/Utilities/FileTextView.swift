//
//  FileTextView.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/14/25.
//

import SwiftUI

struct FileTextView: View {
    let fileName: String
    
    @Binding var textContent: String
    @Environment(\.dismiss) var dismiss
    
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Editing: \(fileName)")
                    .font(.headline)
                    .padding()
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .padding()
                Button("Save") {
                    onSave()
                    dismiss()
                }
                .keyboardShortcut("s", modifiers: .command)
                .padding()
            }
            .background(.thinMaterial)

            Divider()

            TextEditor(text: $textContent)
                .font(.system(.body, design: .monospaced))
                .padding(5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}
