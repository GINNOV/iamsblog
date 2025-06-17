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

            if let result = compareService.comparisonResult {
                TabView {
                    ComparisonResultsView(result: result)
                        .tabItem {
                            Label("Sector Map", systemImage: "square.grid.3x3.fill")
                        }

                    HStack(spacing: 0) {
                        BlockInspectorView(
                            diskName: "Source",
                            bootBlock: result.sourceBootBlock,
                            rootBlock: result.sourceRootBlock,
                            geometry: (80, 2, 11)
                        )
                        Divider()
                        BlockInspectorView(
                            diskName: "Destination",
                            bootBlock: result.destBootBlock,
                            rootBlock: result.destRootBlock,
                            geometry: (80, 2, 11)
                        )
                    }
                    .tabItem {
                        Label("Block Inspector", systemImage: "magnifyingglass")
                    }
                }
            } else {
                Text("Drop two ADF files above and click Compare.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .navigationTitle("ADF Disk Comparator")
        .frame(minWidth: 900, minHeight: 800)
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
        .onDrop(of: [ContentView.adfUType, .fileURL], isTargeted: $isTargeted) { providers -> Bool in
            guard let provider = providers.first else { return false }

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
    private let columns = 11
    private let spacing: CGFloat = 5
    private let boxSize: CGFloat = 28

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Legend and summary
            HStack(spacing: 15) {
                LegendItem(color: .green, label: "Identical")
                LegendItem(color: .red, label: "Different (\(result.differentSectors))")
                LegendItem(color: .blue, label: "Source Only (\(result.sourceOnlySectors))")
                LegendItem(color: .yellow, label: "Destination Only (\(result.destinationOnlySectors))")
                Spacer()
            }
            .padding([.horizontal, .bottom])

            Divider()
            
            ScrollView {
                
                HStack(alignment: .top, spacing: 20) {
                    let totalRows = (result.sectorStates.count + columns - 1) / columns
                    let midPoint = (totalRows + 1) / 2
                    
                    // Left Column
                    SectorGridColumn(
                        result: result,
                        rows: 0..<midPoint,
                        columns: columns,
                        boxSize: boxSize,
                        spacing: spacing
                    )
                    
                    // Right Column
                    SectorGridColumn(
                        result: result,
                        rows: midPoint..<totalRows,
                        columns: columns,
                        boxSize: boxSize,
                        spacing: spacing
                    )
                }
                .padding()
            }
        }
    }
}


private struct SectorGridColumn: View {
    let result: ComparisonResult
    let rows: Range<Int>
    let columns: Int
    let boxSize: CGFloat
    let spacing: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            // Column headers
            HStack(spacing: spacing) {
                Spacer().frame(width: 60)
                ForEach(0..<columns, id: \.self) { col in
                    Text(String(col))
                        .font(.system(size: 12, design: .monospaced).bold())
                        .frame(width: boxSize, height: boxSize)
                }
            }
            
            // Grid rows for this column
            ForEach(rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    Text("\(row * columns)")
                        .font(.system(size: 12, design: .monospaced).bold())
                        .frame(width: 60, alignment: .trailing)
                    
                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        if index < result.sectorStates.count {
                            Rectangle()
                                .fill(result.sectorStates[index].color)
                                .frame(width: boxSize, height: boxSize)
                                .help("Sector \(index): \(result.sectorStates[index].description)")
                        } else {
                            Spacer().frame(width: boxSize, height: boxSize)
                        }
                    }
                }
            }
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
