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
        VStack(alignment: .leading) {
            Text(diskName)
                .font(.headline)
                .padding(.horizontal)
            
            Form {
                Section(header: Text("Geometry & Status")) {
                    InfoRow(label: "Cylinders", value: "\(geometry.cylinders)")
                    InfoRow(label: "Heads", value: "\(geometry.heads)")
                    InfoRow(label: "Sectors", value: "\(geometry.sectors)")
                }
                
                if let boot = bootBlock {
                    Section(header: Text("Boot Block (Sector 0 & 1)")) {
                        InfoRow(label: "Disk Type", value: formatDosType(boot.dosType))
                        InfoRow(label: "Checksum", value: String(format: "0x%08X", boot.checkSum))
                        InfoRow(label: "Root Block", value: "\(boot.rootBlock)")
                    }
                } else {
                    Section(header: Text("Boot Block")) {
                        Text("Could not be read or is invalid.").foregroundColor(.red)
                    }
                }
                
                if let root = rootBlock {
                    Section(header: Text("Root Block (Sector \(bootBlock?.rootBlock ?? 0))")) {
                        InfoRow(label: "Volume Name", value: withUnsafePointer(to: root.diskName) { ptr in
                            String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
                        })
                        InfoRow(label: "Creation Date", value: formatDate(days: root.cDays, mins: root.cMins, ticks: root.cTicks))
                    }
                } else {
                    Section(header: Text("Root Block")) {
                        Text("Could not be read or is invalid.").foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private func formatDosType(_ dosType: (CChar, CChar, CChar, CChar)) -> String {
        let bytes = [dosType.0, dosType.1, dosType.2, 0]
        let fsType = dosType.3
        let typeString = String(cString: bytes.map { UInt8(bitPattern: $0) })
        
        var suffix = ""
        // : This is the fix. The CChar (Int8) is cast to a UInt8
        // before the bitwise operation to resolve the type mismatch. #END_REVIEW
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

    private struct InfoRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label)
                    .frame(width: 100, alignment: .trailing)
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
}
