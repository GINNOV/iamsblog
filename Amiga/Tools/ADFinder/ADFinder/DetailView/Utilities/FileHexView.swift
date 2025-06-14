//
//  FileHexView.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import SwiftUI

struct FileHexView: View {
    let fileName: String
    let data: Data
    
    @State private var selectedByteIndex: Int?
    @State private var showExportMessage: Bool = false
    @State private var messageOpacity: Double = 1.0

    private struct HexLine: Identifiable {
        let id = UUID()
        let offset: String
        let hex: [String]
        let ascii: [String]
        let byteIndices: [Int] // Indices of bytes in the data
    }
    
    private var lines: [HexLine] {
        var result: [HexLine] = []
        let bytesPerRow = 16
        for i in stride(from: 0, to: data.count, by: bytesPerRow) {
            let chunk = data[i..<min(i + bytesPerRow, data.count)]
            let offsetStr = String(format: "%08x", i)
            let hexValues = chunk.map { String(format: "%02hhx", $0) }
            let asciiValues = chunk.map { byteToAscii($0) }
            let indices = Array(i..<min(i + bytesPerRow, data.count))
            result.append(HexLine(offset: offsetStr, hex: hexValues, ascii: asciiValues, byteIndices: indices))
        }
        return result
    }

    private func byteToAscii(_ byte: UInt8) -> String {
        if byte >= 32 && byte <= 126 {
            return String(UnicodeScalar(byte))
        } else {
            return "."
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Content of \(fileName)")
                .font(.headline)
                .padding(.bottom, 8)

            // Header for columns
            HStack(alignment: .top, spacing: 8) {
                Text("Offset")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)
                    .frame(width: 60, alignment: .leading)

                Text("Hex Data")
                    .font(.system(.caption, design: .monospaced))
                    .frame(width: 300, alignment: .leading)

                Text("ASCII")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.cyan)
                    .frame(minWidth: 140, maxWidth: .infinity, alignment: .leading) // Reordered: minWidth before maxWidth
            }
            .padding(.bottom, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(lines) { line in
                        HStack(alignment: .top, spacing: 8) {
                            // Offset column
                            Text(line.offset)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                                .frame(width: 60, alignment: .leading)
                            
                            // Hex column
                            HStack(spacing: 4) {
                                ForEach(Array(line.hex.enumerated()), id: \.offset) { (index, hex) in
                                    Text(hex)
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(.horizontal, 1)
                                        .background(
                                            selectedByteIndex == line.byteIndices[index]
                                                ? Color.blue.opacity(0.3)
                                                : Color.clear
                                        )
                                        .onTapGesture {
                                            selectedByteIndex = line.byteIndices[index]
                                        }
                                }
                            }
                            .frame(width: 300, alignment: .leading)
                            
                            // ASCII column
                            HStack(spacing: 0) {
                                ForEach(Array(line.ascii.enumerated()), id: \.offset) { (index, ascii) in
                                    Text(ascii)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.cyan)
                                        .background(
                                            selectedByteIndex == line.byteIndices[index]
                                                ? Color.blue.opacity(0.3)
                                                : Color.clear
                                        )
                                        .onTapGesture {
                                            selectedByteIndex = line.byteIndices[index]
                                        }
                                }
                            }
                            .frame(minWidth: 140, maxWidth: .infinity, alignment: .leading) // Reordered: minWidth before maxWidth
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                HStack {
                    Text("ESC to close.")
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(action: exportHexContent) {
                        Text("EXPORT")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Capsule().fill(Color.blue))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.top, 8)

                // Export message with fade-out animation
                if showExportMessage {
                    Text("File exported to Downloads folder")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .opacity(messageOpacity)
                        .animation(.easeOut(duration: 0.5), value: messageOpacity)
                }
            }
        }
        .padding(8)
        .frame(minWidth: 540, minHeight: 400)
    }

    // Function to export the hex content to a .txt file in the Downloads folder
    func exportHexContent() {
        // Format the content as a string
        var content = "Hex dump of \(fileName):\n\n"
        content += "Offset    Hex Data                                      ASCII\n"
        content += String(repeating: "-", count: 60) + "\n"
        
        for line in lines {
            let hexString = line.hex.joined(separator: " ")
            // Pad hex string to ensure consistent length (16 bytes = 47 characters with spaces)
            let paddedHex = hexString.padding(toLength: 47, withPad: " ", startingAt: 0)
            let asciiString = line.ascii.joined()
            content += "\(line.offset)  \(paddedHex)  \(asciiString)\n"
        }
        
        // Write to a .txt file in the Downloads folder
        let fileNameWithoutExtension = fileName.components(separatedBy: ".").first ?? fileName
        let exportFileName = "\(fileNameWithoutExtension)_hex.txt"
        
        // Get the Downloads directory
        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            print("Failed to locate Downloads directory")
            return
        }
        
        let fileURL = downloadsURL.appendingPathComponent(exportFileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Exported hex content to \(fileURL.path)")
            
            // Show export message and trigger fade-out
            showExportMessage = true
            messageOpacity = 1.0 // Reset opacity
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    messageOpacity = 0
                }
                // Hide the message after fade-out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showExportMessage = false
                }
            }
        } catch {
            print("Failed to export hex content to Downloads: \(error.localizedDescription)")
        }
    }
}
