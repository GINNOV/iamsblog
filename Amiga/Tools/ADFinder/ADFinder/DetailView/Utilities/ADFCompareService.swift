//
//  ADFCompareService.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/15/25.
//

import SwiftUI

/// Represents the comparison state of a single sector.
enum SectorState: Identifiable {
    case identical
    case different
    case sourceOnly
    case destinationOnly
    
    var id: Self { self }
    
    var color: Color {
        switch self {
        case .identical: return .green.opacity(0.7)
        case .different: return .red
        case .sourceOnly: return .blue.opacity(0.7)
        case .destinationOnly: return .yellow.opacity(0.7)
        }
    }
    
    var description: String {
        switch self {
        case .identical: "Identical"
        case .different: "Different"
        case .sourceOnly: "Source Only"
        case .destinationOnly: "Destination Only"
        }
    }
}

/// A struct to hold the result of a full disk comparison.
struct ComparisonResult {
    let sectorStates: [SectorState]
    let totalSectors: Int
    let differentSectors: Int
    let sourceOnlySectors: Int
    let destinationOnlySectors: Int
    let sourceBootBlock: AdfBootBlock?
    let destBootBlock: AdfBootBlock?
    let sourceRootBlock: AdfRootBlock?
    let destRootBlock: AdfRootBlock?
}


@Observable
class ADFCompareService {
    var sourceData: Data?
    var destinationData: Data?
    var comparisonResult: ComparisonResult?
    
    private let sectorSize = 512
    
    /// Loads data from a URL for either the source or destination disk.
    func load(url: URL, for target: Target) -> Bool {
        print("ADFCompareService: Attempting to load URL: \(url.path) for target: \(target)")
        // Securely access the file's data.
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
                print("ADFCompareService: Stopped accessing security-scoped resource.")
            }
        }
        
        // : Replaced try? with a do-catch block for detailed error logging.
        // This will tell us exactly why the file data isn't loading. #END_REVIEW
        let data: Data
        do {
            data = try Data(contentsOf: url)
            print("ADFCompareService: Successfully loaded \(data.count) bytes.")
        } catch {
            print("ADFCompareService: FAILED to load data from URL. Error: \(error.localizedDescription)")
            return false
        }
        
        switch target {
        case .source:
            self.sourceData = data
        case .destination:
            self.destinationData = data
        }
        
        // Clear previous results when a file changes.
        self.comparisonResult = nil
        return true
    }
    
    /// Specifies which disk to load (source or destination).
    enum Target {
        case source
        case destination
    }
    
    /// Performs the sector-by-sector comparison.
    func compare() {
        guard let sourceData = sourceData, let destinationData = destinationData else {
            print("ADFCompareService.compare: Cannot compare, one or both data sources are nil.")
            return
        }
        
        print("ADFCompareService.compare: Starting comparison...")
        
        let sourceBoot = parseBootBlock(from: sourceData)
        let sourceRoot = parseRootBlock(from: sourceData, bootBlock: sourceBoot)
        
        let destBoot = parseBootBlock(from: destinationData)
        let destRoot = parseRootBlock(from: destinationData, bootBlock: destBoot)
        
        let sourceSectors = sourceData.count / sectorSize
        let destSectors = destinationData.count / sectorSize
        let maxSectors = max(sourceSectors, destSectors)
        
        var states: [SectorState] = []
        var diffCount = 0
        var sourceOnlyCount = 0
        var destOnlyCount = 0
        
        for i in 0..<maxSectors {
            let sourceStart = i * sectorSize
            let destStart = i * sectorSize
            
            let isSourceSectorValid = sourceStart + sectorSize <= sourceData.count
            let isDestSectorValid = destStart + sectorSize <= destinationData.count
            
            if isSourceSectorValid && isDestSectorValid {
                let sourceChunk = sourceData[sourceStart..<(sourceStart + sectorSize)]
                let destChunk = destinationData[destStart..<(destStart + sectorSize)]
                
                if sourceChunk == destChunk {
                    states.append(.identical)
                } else {
                    states.append(.different)
                    diffCount += 1
                }
            } else if isSourceSectorValid {
                states.append(.sourceOnly)
                sourceOnlyCount += 1
            } else {
                states.append(.destinationOnly)
                destOnlyCount += 1
            }
        }
        
        self.comparisonResult = ComparisonResult(
            sectorStates: states,
            totalSectors: maxSectors,
            differentSectors: diffCount,
            sourceOnlySectors: sourceOnlyCount,
            destinationOnlySectors: destOnlyCount,
            sourceBootBlock: sourceBoot,
            destBootBlock: destBoot,
            sourceRootBlock: sourceRoot,
            destRootBlock: destRoot
        )
        print("ADFCompareService.compare: Comparison finished.")
    }
    
    private func parseBootBlock(from data: Data) -> AdfBootBlock? {
        var boot = AdfBootBlock()
        let result = data.withUnsafeBytes { ptr -> ADF_RETCODE in
            guard let baseAddress = ptr.baseAddress else { return ADF_RC_ERROR }
            return parse_boot_block(baseAddress.assumingMemoryBound(to: UInt8.self), &boot)
        }
        return result == ADF_RC_OK ? boot : nil
    }
    
    private func parseRootBlock(from data: Data, bootBlock: AdfBootBlock?) -> AdfRootBlock? {
        guard let boot = bootBlock else { return nil }
        var root = AdfRootBlock()
        let result = data.withUnsafeBytes { ptr -> ADF_RETCODE in
            guard let baseAddress = ptr.baseAddress else { return ADF_RC_ERROR }
            return parse_root_block(baseAddress.assumingMemoryBound(to: UInt8.self), UInt32(sectorSize), UInt32(boot.rootBlock), &root)
        }
        return result == ADF_RC_OK ? root : nil
    }
}
