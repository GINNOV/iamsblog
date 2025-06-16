//
//  BlockInspectorView.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/16/25.
//

import SwiftUI

struct BlockInspectorView: View {
    let diskName: String
    let bootBlock: AdfBootBlock?
    let rootBlock: AdfRootBlock?
    let geometry: (cylinders: Int, heads: Int, sectors: Int)

    var body: some View {
        // : Switched from a Form to a VStack with a ScrollView
        // for more precise layout control and a custom aesthetic. #END_REVIEW
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header for the entire inspector pane
                Text(diskName)
                    .font(.title2.bold())
                    .padding(.bottom, 5)

                // Geometry Section
                InspectorSection(header: "Geometry & Status") {
                    InfoRow(label: "Cylinders", value: "\(geometry.cylinders)")
                    InfoRow(label: "Heads", value: "\(geometry.heads)")
                    InfoRow(label: "Sectors", value: "\(geometry.sectors)")
                }

                // Boot Block Section
                InspectorSection(header: "Boot Block (Sectors 0 & 1)") {
                    if let boot = bootBlock {
                        InfoRow(label: "Disk Type", value: formatDosType(boot.dosType))
                        InfoRow(label: "Checksum", value: String(format: "0x%08X", boot.checkSum))
                        InfoRow(label: "Root Block", value: "\(boot.rootBlock)")
                    } else {
                        ErrorRow(message: "Could not be read or is invalid.")
                    }
                }
                
                // Root Block Section
                InspectorSection(header: "Root Block (Sector \(bootBlock?.rootBlock ?? 0))") {
                    if let root = rootBlock {
                        InfoRow(label: "Volume Name", value: withUnsafePointer(to: root.diskName) { ptr in
                            String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
                        })
                        InfoRow(label: "Creation Date", value: formatDate(days: root.cDays, mins: root.cMins, ticks: root.cTicks))
                        InfoRow(label: "Access Days", value: "\(root.days)")
                        InfoRow(label: "Access Mins", value: "\(root.mins)")
                        InfoRow(label: "Access Ticks", value: "\(root.ticks)")

                    } else {
                        ErrorRow(message: "Could not be read or is invalid.")
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
    
    private func formatDosType(_ dosType: (CChar, CChar, CChar, CChar)) -> String {
        let bytes = [dosType.0, dosType.1, dosType.2, 0]
        let fsType = dosType.3
        let typeString = String(cString: bytes.map { UInt8(bitPattern: $0) })
        
        var suffix = ""
        if (UInt8(bitPattern: fsType) & FS_TYPE_FFS_SWIFT) != 0 {
            suffix = "FFS"
        } else {
            suffix = "OFS"
        }
        
        return "\(typeString) (\(suffix))"
    }
    
    private func formatDate(days: Int32, mins: Int32, ticks: Int32) -> String {
        var components = DateComponents()
        components.year = 1978
        components.month = 1
        components.day = 1
        
        guard let amigaEpoch = Calendar.current.date(from: components) else {
            return "Date Calc Error"
        }
        
        var totalSeconds = TimeInterval(days * 24 * 60 * 60)
        totalSeconds += TimeInterval(mins * 60)
        totalSeconds += TimeInterval(ticks) / 50.0
        let creationDate = amigaEpoch.addingTimeInterval(totalSeconds)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MMM-yy HH:mm:ss"
        return dateFormatter.string(from: creationDate)
    }
}

// : A custom container view to provide consistent styling for each inspector section. #END_REVIEW
private struct InspectorSection<Content: View>: View {
    let header: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(header)
                .font(.headline)
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 5) {
                content
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.4))
            .cornerRadius(8)
        }
    }
}

// : A custom view for a standard label-value row, ensuring consistent alignment and styling. #END_REVIEW
private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label + ":")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .trailing)
            
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
}

// : A dedicated view to display errors consistently. #END_REVIEW
private struct ErrorRow: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "xmark.octagon.fill")
                .foregroundColor(.red)
            Text(message)
                .foregroundColor(.red)
        }
        .padding(.vertical, 5)
    }
}
