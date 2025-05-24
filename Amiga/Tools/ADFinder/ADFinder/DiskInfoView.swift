//
//  DiskInfoView.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//


// DiskInfoView.swift
import SwiftUI

struct DiskInfoView: View {
    @Bindable var adfService: ADFService // Assuming ADFService is @Observable

    // Helper to format the grid items
    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading) // Consistent label width
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Disk Information").font(.headline).padding(.bottom, 4)
            
            infoRow(label: "FS Type:", value: adfService.filesystemType)
            infoRow(label: "Bootable:", value: adfService.isBootable ? "YES" : "NO")
            infoRow(label: "Label:", value: adfService.volumeLabel)
            infoRow(label: "Created:", value: adfService.creationDateString)
            infoRow(label: "Size:", value: adfService.diskSizeString)
            infoRow(label: "Used:", value: adfService.usedSizeString)
            infoRow(label: "Free:", value: adfService.freeSizeString)
            infoRow(label: "Full %:", value: adfService.percentFullString)
        }
        .font(.system(.caption, design: .monospaced))
        .padding(10)
        .background(Color(NSColor.windowBackgroundColor)) // Adapts to light/dark mode
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 1, y: 2)
    }
}

// Optional: Preview for DiskInfoView
struct DiskInfoView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock ADFService for previewing
        let mockService = ADFService()
        // You can set some mock data on mockService here if needed
        mockService.filesystemType = "FFS"
        mockService.isBootable = true
        mockService.volumeLabel = "Workbench3.1"
        mockService.creationDateString = "01-Jan-92 12:00:00"
        mockService.diskSizeString = "880 KB"
        mockService.usedSizeString = "700 KB"
        mockService.freeSizeString = "180 KB"
        mockService.percentFullString = "80%"
        
        return DiskInfoView(adfService: mockService)
            .padding()
            .frame(width: 300)
    }
}
