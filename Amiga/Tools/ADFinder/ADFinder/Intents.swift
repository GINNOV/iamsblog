//
//  Intents.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/15/25.
// This enables the integration with Shortcuts, however, it can be used unless
// you compile with an App Store approved certificate. To enable it you need to
// setup that and add Siri to the entitlement plist. I will add to the app store
// a compiled version if in future to workaround this stupidity.

import AppIntents
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Supporting Enum for Filesystem Type

/// This enum provides user-friendly choices for the filesystem type in the Shortcuts app.
enum FilesystemType: String, AppEnum {
    case ofs = "OFS"
    case ffs = "FFS"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Filesystem Type"
    static var caseDisplayRepresentations: [FilesystemType: DisplayRepresentation] = [
        .ofs: "OFS (Original File System)",
        .ffs: "FFS (Fast File System)"
    ]
}

// MARK: - Create ADF Intent

/// This intent allows users to create a new, blank ADF file via Shortcuts.
struct CreateADFIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Blank ADF"
    static var description: IntentDescription = "Creates a new, empty Amiga Disk File (ADF) with a specified volume name and filesystem type."
    static var openAppWhenRun: Bool = false // This action can run in the background.

    @Parameter(title: "Volume Name", default: "Workbench")
    var volumeName: String

    @Parameter(title: "Filesystem Type", default: .ofs)
    var fsType: FilesystemType
    
    static var parameterSummary: some ParameterSummary {
        Summary("Create a new ADF named \(\.$volumeName) with filesystem \(\.$fsType)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let adfService = ADFService()
        let fsTypeRaw: UInt8 = (fsType == .ffs) ? FS_TYPE_FFS_SWIFT : FS_TYPE_OFS_SWIFT
        
        guard let newAdfUrl = adfService.createNewBlankADF(volumeName: volumeName, fsType: fsTypeRaw) else {
            throw NSError(domain: "ADFServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create the blank ADF file. Check ADFinder logs for more details."])
        }
        
        // CORRECTED: The 'readImmediately' parameter is not valid in this initializer.
        let intentFile = IntentFile(fileURL: newAdfUrl)
        
        return .result(value: intentFile)
    }
}

// MARK: - Add Files to ADF Intent

/// This intent allows users to add one or more files to an existing ADF.
struct AddFilesToADFIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Files to ADF"
    static var description: IntentDescription = "Adds one or more files to an existing ADF disk image."
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "ADF File", supportedContentTypes: [UTType(filenameExtension: "adf")!])
    var adfFile: IntentFile
    
    @Parameter(title: "Files to Add")
    var filesToAdd: [IntentFile]
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$filesToAdd) to \(\.$adfFile)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let adfService = ADFService()
        
        guard let sourceAdfURL = adfFile.fileURL else {
            throw NSError(domain: "FileError", code: 8, userInfo: [NSLocalizedDescriptionKey: "The provided source ADF file is missing its URL."])
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let tempAdfURL = tempDir.appendingPathComponent(UUID().uuidString + ".adf")
        
        do {
            try FileManager.default.copyItem(at: sourceAdfURL, to: tempAdfURL)
        } catch {
            throw NSError(domain: "FileError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create a temporary copy of the ADF file: \(error.localizedDescription)"])
        }

        guard adfService.openADF(filePath: tempAdfURL.path) else {
            throw NSError(domain: "ADFServiceError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to open the specified ADF file."])
        }
        
        for file in filesToAdd {
            // CORRECTED: The .fileURL property is optional and must be unwrapped.
            guard let fileURLToAdd = file.fileURL else {
                // We'll skip any files that are missing a URL rather than throwing the whole operation.
                print("Warning: Skipping file '\(file.filename)' because its URL was missing.")
                continue
            }
            
            if let errorMessage = adfService.addFile(from: fileURLToAdd) {
                adfService.closeADF()
                throw NSError(domain: "ADFServiceError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to add file '\(file.filename)': \(errorMessage)"])
            }
        }
        
        adfService.closeADF()
        
        let resultFile = IntentFile(fileURL: tempAdfURL)
        return .result(value: resultFile)
    }
}

// MARK: - Rename Volume Intent

/// This intent changes the volume name (disk label) of an ADF.
struct RenameVolumeIntent: AppIntent {
    static var title: LocalizedStringResource = "Rename ADF Volume"
    static var description: IntentDescription = "Changes the volume name (label) of an ADF disk image."
    static var openAppWhenRun: Bool = false

    @Parameter(title: "ADF File", supportedContentTypes: [UTType(filenameExtension: "adf")!])
    var adfFile: IntentFile
    
    @Parameter(title: "New Volume Name")
    var newName: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Rename volume of \(\.$adfFile) to \(\.$newName)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let adfService = ADFService()
        
        // CORRECTED: The .fileURL property is optional and must be unwrapped.
        guard let sourceAdfURL = adfFile.fileURL else {
            throw NSError(domain: "FileError", code: 9, userInfo: [NSLocalizedDescriptionKey: "The provided source ADF file is missing its URL."])
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let tempAdfURL = tempDir.appendingPathComponent(UUID().uuidString + ".adf")
        
        do {
            try FileManager.default.copyItem(at: sourceAdfURL, to: tempAdfURL)
        } catch {
             throw NSError(domain: "FileError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to create a temporary copy of the ADF file: \(error.localizedDescription)"])
        }

        guard adfService.openADF(filePath: tempAdfURL.path) else {
            throw NSError(domain: "ADFServiceError", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to open the specified ADF file."])
        }
        
        if let errorMessage = adfService.renameVolume(newName: newName) {
            adfService.closeADF()
            throw NSError(domain: "ADFServiceError", code: 7, userInfo: [NSLocalizedDescriptionKey: "Failed to rename volume: \(errorMessage)"])
        }
        
        adfService.closeADF()

        let resultFile = IntentFile(fileURL: tempAdfURL)
        return .result(value: resultFile)
    }
}

// MARK: - App Shortcuts Provider

/// This structure registers all the defined intents with the system, making them available in the Shortcuts app.
struct ADFinderShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateADFIntent(),
            phrases: ["Create a new ADF in \(.applicationName)"],
            shortTitle: "Create Blank ADF",
            systemImageName: "doc.badge.plus"
        )
        
        AppShortcut(
            intent: AddFilesToADFIntent(),
            phrases: ["Add files to an ADF in \(.applicationName)"],
            shortTitle: "Add Files to ADF",
            systemImageName: "plus.circle"
        )
        
        AppShortcut(
            intent: RenameVolumeIntent(),
            phrases: ["Rename an ADF volume in \(.applicationName)"],
            shortTitle: "Rename ADF Volume",
            systemImageName: "pencil"
        )
    }
}
