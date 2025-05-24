//
//  ADFService.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import Foundation
import SwiftUI

@Observable
class ADFService {
    private var adfDevice: UnsafeMutablePointer<AdfDevice>?
    private var adfVolume: UnsafeMutablePointer<AdfVolume>?
    private var adflibInitialized = false

    var currentVolumeName: String? // This will be updated by populateDiskInfo
    var currentPath: [String] = []

    // Properties for Disk Information (Feature 2)
    // Initialize with placeholder values
    var filesystemType: String = "N/A"
    var isBootable: Bool = false
    var volumeLabel: String = "N/A"
    var creationDateString: String = "N/A"
    var diskSizeString: String = "N/A"
    var usedSizeString: String = "N/A"
    var freeSizeString: String = "N/A"
    var percentFullString: String = "N/A"


    init() {
        if adfLibInit() == ADF_RC_OK {
            adflibInitialized = true
            if register_dump_driver_helper() != ADF_RC_OK {
                print("ADFService: Warning - Failed to add dump device driver via helper.")
            }
        } else {
            print("ADFService: Error - Failed to initialize ADFLib.")
        }
    }

    deinit {
        closeADF() // Ensures resources are freed
        if adflibInitialized {
            adfLibCleanUp()
        }
    }

    private func getADFLibError(context: String) -> String {
        return "ADFLib operation failed: \(context)."
    }

    private func resetDiskInfo() {
        filesystemType = "N/A"
        isBootable = false
        volumeLabel = "N/A"
        creationDateString = "N/A"
        diskSizeString = "N/A"
        usedSizeString = "N/A"
        freeSizeString = "N/A"
        percentFullString = "N/A"
        currentVolumeName = nil // Also reset this as it's part of disk info
    }

    func openADF(filePath: String) -> Bool {
        guard adflibInitialized else {
            print("ADFService: ADFLib not initialized.")
            return false
        }
        closeADF() // Resets state including disk info

        print("ADFService: Attempting to open ADF with path: \"\(filePath)\"")

        self.adfDevice = filePath.withCString { cFilePath -> UnsafeMutablePointer<AdfDevice>? in
            return adfDevOpen(cFilePath, AdfAccessMode(rawValue: UInt32(ACCESS_MODE_READONLY_SWIFT)))
        }

        if self.adfDevice == nil {
            print(getADFLibError(context: "adfDevOpen for \"\(filePath)\""))
            return false
        }
        
        if adfDevMount(self.adfDevice) != ADF_RC_OK {
            print(getADFLibError(context: "adfDevMount"))
            adfDevClose(self.adfDevice)
            self.adfDevice = nil
            return false
        }
        
        // Assuming only one volume (partition 0) for typical ADFs
        self.adfVolume = adfVolMount(self.adfDevice, 0, AdfAccessMode(rawValue: UInt32(ACCESS_MODE_READONLY_SWIFT)))
        if self.adfVolume == nil {
            print(getADFLibError(context: "adfVolMount"))
            adfDevUnMount(self.adfDevice) // Clean up device if volume mount fails
            adfDevClose(self.adfDevice)
            self.adfDevice = nil
            return false
        }
        
        currentPath = [] // Reset path for the new disk
        populateDiskInfo() // Populate disk info after successful mount

        // currentVolumeName is set within populateDiskInfo from the volume's actual label
        print("ADFService: Successfully opened ADF. Volume: \(self.currentVolumeName ?? "N/A")")
        return true
    }

    private func populateDiskInfo() {
        guard let vol = self.adfVolume else {
            resetDiskInfo()
            return
        }

        // Filesystem Type
        var fsTempType = ""
        if adfVolIsFFS(vol) == true { // Explicitly compare with true for clarity
            fsTempType = "FFS"
        } else {
            fsTempType = "OFS"
        }
        if adfVolHasINTL(vol) == true {
            fsTempType += " INTL"
        }
        if adfVolHasDIRCACHE(vol) == true {
            fsTempType += " DIRCACHE"
        }
        self.filesystemType = fsTempType.trimmingCharacters(in: .whitespaces)


        // Volume Label (from AdfVolume struct)
        if let volNameCStr = vol.pointee.volName {
            self.volumeLabel = String(cString: volNameCStr)
        } else {
            self.volumeLabel = "Unnamed"
        }
        self.currentVolumeName = self.volumeLabel // Keep currentVolumeName consistent


        // Bootable status (from BootBlock)
        var bootBlock = AdfBootBlock() // Note: AdfBootBlock is a C struct
        if adfReadBootBlock(vol, &bootBlock) == ADF_RC_OK {
            // A common check for bootable is if dosType starts with "DOS"
            // The dosType field is char dosType[4];
            let dosTypeBytes = [bootBlock.dosType.0, bootBlock.dosType.1, bootBlock.dosType.2]
            let dosTypeString = String(cString: dosTypeBytes.map { UInt8(bitPattern: $0) } + [0]) // Ensure null termination for safety
            isBootable = (dosTypeString == "DOS")
        } else {
            isBootable = false
            print("ADFService: Failed to read boot block for bootable status.")
        }

        // Creation Date (from RootBlock)
        let rootBlockSector = adfVolCalcRootBlk(vol)
        var rootBlock = AdfRootBlock() // Note: AdfRootBlock is a C struct
        if adfReadRootBlock(vol, UInt32(rootBlockSector), &rootBlock) == ADF_RC_OK {
            // Using cDays, cMins, cTicks for creation date as per sketch
            var components = DateComponents()
            components.year = 1978 // Amiga epoch start
            components.month = 1
            components.day = 1
            
            if let amigaEpoch = Calendar.current.date(from: components) {
                var totalSeconds = TimeInterval(rootBlock.cDays * 24 * 60 * 60)
                totalSeconds += TimeInterval(rootBlock.cMins * 60)
                totalSeconds += TimeInterval(rootBlock.cTicks) / 50.0 // 50 ticks per second
                let creationDate = amigaEpoch.addingTimeInterval(totalSeconds)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MMM-yy HH:mm:ss" // e.g., 28-Sep-95 14:54:01
                creationDateString = dateFormatter.string(from: creationDate)
            } else {
                creationDateString = "Date Calc Error"
            }
        } else {
            creationDateString = "N/A (RootBlock Error)"
            print("ADFService: Failed to read root block for creation date.")
        }

        // Size information
        // adfVolGetSizeInBlocks returns int32_t, adfCountFreeBlocks returns int32_t
        let totalBlocks = Int64(adfVolGetSizeInBlocks(vol)) // Use Int64 for calculations to avoid overflow
        let freeBlocks = Int64(adfCountFreeBlocks(vol))
        let usedBlocks = totalBlocks - freeBlocks
        let blockSize = Int64(vol.pointee.datablockSize) // Typically 512

        if blockSize > 0 {
            let totalSizeKB = (totalBlocks * blockSize) / 1024
            let usedSizeKB = (usedBlocks * blockSize) / 1024
            let freeSizeKB = (freeBlocks * blockSize) / 1024
            
            diskSizeString = "\(totalSizeKB) KB"
            usedSizeString = "\(usedSizeKB) KB"
            freeSizeString = "\(freeSizeKB) KB"

            if totalBlocks > 0 {
                let percent = Double(usedBlocks) * 100.0 / Double(totalBlocks)
                percentFullString = String(format: "%.0f%%", percent)
            } else {
                percentFullString = "0%"
            }
        } else {
            diskSizeString = "N/A"; usedSizeString = "N/A"; freeSizeString = "N/A"; percentFullString = "N/A";
            print("ADFService: Invalid block size from volume.")
        }
    }


    func closeADF() {
        if let vol = self.adfVolume {
            adfVolUnMount(vol)
            self.adfVolume = nil
        }
        if let dev = self.adfDevice {
            adfDevUnMount(dev)
            adfDevClose(dev)
            self.adfDevice = nil
        }
        resetDiskInfo() // Reset info when closing
        currentPath = []
        print("ADFService: ADF closed.")
    }

    private func navigateToInternalPath() -> Bool {
        guard let vol = self.adfVolume else { return false }
        if adfToRootDir(vol) != ADF_RC_OK {
            print(getADFLibError(context: "adfToRootDir"))
            return false
        }
        for dirName in currentPath {
            if !dirName.withCString({ cDirName -> Bool in adfChangeDir(vol, cDirName) == ADF_RC_OK }) {
                print(getADFLibError(context: "adfChangeDir to \(dirName)"))
                adfToRootDir(vol)
                return false
            }
        }
        return true
    }

    func listCurrentDirectory() -> [AmigaEntry] {
        guard let vol = self.adfVolume else { return [] }
        if !navigateToInternalPath() { return [] }
        
        let dirSector = vol.pointee.curDirPtr
        var entries: [AmigaEntry] = []
        
        let adfListHead: UnsafeMutablePointer<AdfList>? = adfGetDirEnt(vol, dirSector)
        
        if adfListHead == nil {
            print("ADFService: adfGetDirEnt returned nil for sector \(dirSector). (Empty directory or error)")
        }

        var currentAdfListNode = adfListHead
        while let currentNodePtr = currentAdfListNode {
            let currentNode = currentNodePtr.pointee
            if let entryDataVoidPtr = currentNode.content {
                let adfEntryOpaquePtr = entryDataVoidPtr.assumingMemoryBound(to: AdfEntry.self)
                
                let entryNamePtr = get_AdfEntry_name_ptr(adfEntryOpaquePtr)
                let name = entryNamePtr != nil ? String(cString: entryNamePtr!) : "Invalid Name"
                
                let entryTypeCInt = get_AdfEntry_type(adfEntryOpaquePtr)
                let type: EntryType
                switch entryTypeCInt {
                    case ST_FILE_SWIFT: type = .file
                    case ST_DIR_SWIFT: type = .directory
                    case ST_LFILE_SWIFT: type = .softLinkFile
                    case ST_LDIR_SWIFT: type = .softLinkDir
                    default: type = .unknown
                }
                
                var date: Date? = nil
                let year = Int(get_AdfEntry_year(adfEntryOpaquePtr))
                let month = Int(get_AdfEntry_month(adfEntryOpaquePtr))
                let day = Int(get_AdfEntry_days(adfEntryOpaquePtr))
                let hour = Int(get_AdfEntry_hour(adfEntryOpaquePtr))
                let minute = Int(get_AdfEntry_mins(adfEntryOpaquePtr))
                let second = Int(get_AdfEntry_secs(adfEntryOpaquePtr))

                if year >= 1900 && (month >= 1 && month <= 12) && (day >= 1 && day <= 31) {
                    var components = DateComponents()
                    components.year = year
                    components.month = month
                    components.day = day
                    components.hour = hour
                    components.minute = minute
                    components.second = second
                    date = Calendar.current.date(from: components)
                }

                var commentStr: String? = nil
                if let commentCStringPtr = get_AdfEntry_comment_ptr(adfEntryOpaquePtr) {
                     commentStr = String(cString: commentCStringPtr)
                }
                
                let entrySize = get_AdfEntry_size(adfEntryOpaquePtr)
                let entryAccess = get_AdfEntry_access(adfEntryOpaquePtr)
                
                entries.append(AmigaEntry(name: name, type: type, size: Int32(entrySize),
                                          protectionBits: entryAccess, date: date, comment: commentStr))
            }
            if currentNode.next == nil { break }
            currentAdfListNode = currentNode.next
        }
        if adfListHead != nil { adfFreeDirList(adfListHead) }
        
        return entries.sorted {
            if $0.type == .directory && $1.type != .directory { return true }
            if $0.type != .directory && $1.type == .directory { return false }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func navigateToDirectory(_ name: String) -> Bool {
        guard self.adfVolume != nil, !name.isEmpty, name != "." else { return false }
        
        if name == ".." {
            if currentPath.isEmpty { return false }
            currentPath.removeLast()
            return true
        } else {
            currentPath.append(name)
            return true
        }
    }

    func goUpDirectory() -> Bool {
         if currentPath.isEmpty { return false }
         currentPath.removeLast()
         return true
    }

    func readFileContent(entry: AmigaEntry) -> Data? {
        guard let vol = self.adfVolume, entry.type == .file else { return nil }
        if !navigateToInternalPath() {
            print(getADFLibError(context: "navigateToInternalPath for \(entry.name) before readFileContent"))
            return nil
        }
        var fileData = Data()
        let bufferSize: UInt32 = 4096
        var buffer = [UInt8](repeating: 0, count: Int(bufferSize))

        let adfFilePtr = entry.name.withCString { cFileName -> UnsafeMutablePointer<AdfFile>? in
            return adfFileOpen(vol, cFileName, AdfFileMode(rawValue: UInt32(ADF_FILE_MODE_READ_SWIFT)))
        }

        if adfFilePtr == nil {
            print(getADFLibError(context: "adfFileOpen for \(entry.name)"))
            return nil
        }
        defer { adfFileClose(adfFilePtr) }

        while true {
            let bytesRead = adfFileRead(adfFilePtr, bufferSize, &buffer)
            if bytesRead < 0 {
                print(getADFLibError(context: "adfFileRead for \(entry.name)"))
                return nil
            }
            if bytesRead == 0 {
                break
            }
            fileData.append(buffer, count: Int(bytesRead))
        }
        return fileData
    }
}
