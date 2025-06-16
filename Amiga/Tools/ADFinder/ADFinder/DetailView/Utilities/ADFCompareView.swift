//
//  ADFCompareView.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/15/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ADFCompareView: View {
    @State private var compareService = ADFCompareService()
    @State private var sourceURL: URL?
    @State private var destURL: URL?

    var body: some View {
        VStack {
            // Top section with drop targets and compare button
            HStack(spacing: 20) {
                FileDropTarget(title: "Source Disk", url: $sourceURL) { url in
                    if !compareService.load(url: url, for: .source) {
                        // Handle error if needed
                    }
                }
                
                FileDropTarget(title: "Destination Disk", url: $destURL) { url in
                    if !compareService.load(url: url, for: .destination) {
                        // Handle error if needed
                    }
                }
            }
            .frame(height: 120)

            Button("Compare", action: compareService.compare)
                .disabled(sourceURL == nil || destURL == nil)
                .keyboardShortcut(.defaultAction)
                .padding()

            Divider()

            // Results section
            if let result = compareService.comparisonResult {
                ComparisonResultsView(result: result)
            } else {
                Text("Drop two ADF files above and click Compare.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .navigationTitle("ADF Disk Comparator")
    }
}

// A reusable view for the drag-and-drop area.
private struct FileDropTarget: View {
    let title: String
    @Binding var url: URL?
    let onDrop: (URL) -> Void
    @State private var isTargeted = false

    var body: some View {
        VStack {
            Image(systemName: url == nil ? "doc.badge.plus" : "doc.text.fill")
                .font(.largeTitle)
                .foregroundColor(isTargeted ? Color.accentColor : .secondary)
            
            Text(url?.lastPathComponent ?? title)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isTargeted ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isTargeted ? Color.accentColor : .gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5]))
        )
        // AI_REVIEW: This is the definitive fix. This implementation now mirrors the
        // proven, working drag-and-drop handler from the main DetailView, which
        // correctly handles various data representations from Finder. #END_REVIEW
        .onDrop(of: [ContentView.adfUType, .fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else {
                return false
            }

            // Check for our custom ADF type first.
            if provider.hasItemConformingToTypeIdentifier(ContentView.adfUType.identifier) {
                provider.loadItem(forTypeIdentifier: ContentView.adfUType.identifier, options: nil) { (item, error) in
                    DispatchQueue.main.async {
                        var finalURL: URL?
                        if let data = item as? Data {
                            finalURL = URL(dataRepresentation: data, relativeTo: nil)
                        } else if let url = item as? URL {
                            finalURL = url
                        }
                        
                        if let finalURL = finalURL {
                            self.url = finalURL
                            onDrop(finalURL)
                        }
                    }
                }
                return true
            }

            // Fall back to the generic file URL type.
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                _ = provider.loadObject(ofClass: URL.self) { (url, error) in
                    DispatchQueue.main.async {
                        if let url = url {
                            self.url = url
                            onDrop(url)
                        }
                    }
                }
                return true
            }
            
            return false
        }
    }
}


// A view to display the graphical comparison results.
private struct ComparisonResultsView: View {
    let result: ComparisonResult
    private let columns = [GridItem(.adaptive(minimum: 12), spacing: 2)]

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(0..<result.sectorStates.count, id: \.self) { index in
                        Rectangle()
                            .fill(result.sectorStates[index].color)
                            .frame(width: 12, height: 12)
                            .help("Sector \(index): \(result.sectorStates[index].description)")
                    }
                }
                .padding()
            }
            
            // Legend and summary
            HStack(spacing: 15) {
                LegendItem(color: .green, label: "Identical")
                LegendItem(color: .red, label: "Different (\(result.differentSectors))")
                LegendItem(color: .blue, label: "Source Only (\(result.sourceOnlySectors))")
                LegendItem(color: .yellow, label: "Destination Only (\(result.destinationOnlySectors))")
            }
            .padding(.top, 5)
        }
    }
}

// A small helper view for the legend.
private struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(color)
                .frame(width: 15, height: 15)
            Text(label)
                .font(.caption)
        }
    }
}
