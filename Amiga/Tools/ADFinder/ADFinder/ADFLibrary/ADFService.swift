//
//  ADFService.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

import Foundation
import SwiftUI

@_cdecl("swift_log_bridge")
func swift_log_bridge(msg: UnsafePointer<CChar>?) {
    guard let msg = msg else { return }
    let logMessage = String(cString: msg)
    print("[ADFLib C-Log]: \(logMessage)", terminator: "")
}


@Observable
class ADFService {
    private var adfDevice: UnsafeMutablePointer<AdfDevice>?
    private var adfVolume: UnsafeMutablePointer<AdfVolume>?
    private var adflibInitialized = false

    var currentVolumeName: String?
    var currentPath: [String] = []

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
            print("ADFService: ADFLib Initialized OK.")
            
            setup_logging()
            print("ADFService: ADFLib logging redirected to Swift console via C shim.")

            if register_dump_driver_helper() != ADF_RC_OK {
                print("ADFService: Warning - Failed to add dump device driver via helper.")
            }
        } else {
            print("ADFService: Error - Failed to initialize ADFLib.")
        }
    }

    deinit {
        closeADF()
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
        currentVolumeName = nil
    }

    func openADF(filePath: String) -> Bool {
        guard adflibInitialized else {
            print("ADFService: ADFLib not initialized. Cannot open file.")
            return false
        }
        closeADF()

        print("ADFService: Attempting to open ADF with path: \"\(filePath)\" in ReadWrite mode.")

        self.adfDevice = filePath.withCString { cFilePath -> UnsafeMutablePointer<AdfDevice>? in
            return adfDevOpenWithDriver("dump", cFilePath, AdfAccessMode(rawValue: UInt32(ACCESS_MODE_READWRITE_SWIFT)))
        }

        if self.adfDevice == nil {
            print("ADFService: adfDevOpenWithDriver returned nil. Check C-Log above for details.")
            return false
        }
        
        print("ADFService: adfDevMount OK. Mounting device...")
        if adfDevMount(self.adfDevice) != ADF_RC_OK {
            print("ADFService: adfDevMount failed. Check C-Log above.")
            adfDevClose(self.adfDevice)
            self.adfDevice = nil
            return false
        }
        
        print("ADFService: adfDevMount OK. Mounting volume 0...")
        self.adfVolume = adfVolMount(self.adfDevice, 0, AdfAccessMode(rawValue: UInt32(ACCESS_MODE_READWRITE_SWIFT)))
        if self.adfVolume == nil {
            print("ADFService: adfVolMount failed. Check C-Log above.")
            adfDevUnMount(self.adfDevice)
            adfDevClose(self.adfDevice)
            self.adfDevice = nil
            return false
        }
        
        currentPath = []
        populateDiskInfo()

        print("ADFService: Successfully opened and mounted ADF. Volume: \(self.currentVolumeName ?? "N/A")")
        return true
    }

    private func populateDiskInfo() {
        guard let vol = self.adfVolume else {
            resetDiskInfo()
            return
        }

        var fsTempType = ""
        if adfVolIsFFS(vol) == true {
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

        if let volNameCStr = vol.pointee.volName {
            self.volumeLabel = String(cString: volNameCStr)
        } else {
            self.volumeLabel = "Unnamed"
        }
        self.currentVolumeName = self.volumeLabel

        var bootBlock = AdfBootBlock()
        if adfReadBootBlock(vol, &bootBlock) == ADF_RC_OK {
            let dosTypeBytes = [bootBlock.dosType.0, bootBlock.dosType.1, bootBlock.dosType.2]
            let dosTypeString = String(cString: dosTypeBytes.map { UInt8(bitPattern: $0) } + [0])
            isBootable = (dosTypeString == "DOS")
        } else {
            isBootable = false
            print("ADFService: Could not read boot block.")
        }

        let rootBlockSector = adfVolCalcRootBlk(vol)
        var rootBlock = AdfRootBlock()
        if adfReadRootBlock(vol, UInt32(rootBlockSector), &rootBlock) == ADF_RC_OK {
            var components = DateComponents()
            components.year = 1978
            components.month = 1
            components.day = 1
            
            if let amigaEpoch = Calendar.current.date(from: components) {
                var totalSeconds = TimeInterval(rootBlock.cDays * 24 * 60 * 60)
                totalSeconds += TimeInterval(rootBlock.cMins * 60)
                totalSeconds += TimeInterval(rootBlock.cTicks) / 50.0
                let creationDate = amigaEpoch.addingTimeInterval(totalSeconds)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MMM-yy HH:mm:ss"
                creationDateString = dateFormatter.string(from: creationDate)
            } else {
                creationDateString = "Date Calc Error"
            }
        } else {
            creationDateString = "N/A (RootBlock Error)"
            print("ADFService: Failed to read root block.")
        }

        let totalBlocks = Int64(adfVolGetSizeInBlocks(vol))
        let freeBlocks = Int64(adfCountFreeBlocks(vol))
        let usedBlocks = totalBlocks - freeBlocks
        let blockSize = Int64(vol.pointee.blockSize)

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
        resetDiskInfo()
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
            // This is normal for an empty directory.
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
            if !navigateToInternalPath() {
                 print("ADFService: Failed to navigate up to parent directory.")
                 return false
            }
            return true
        } else {
            currentPath.append(name)
            if !navigateToInternalPath() {
                print("ADFService: Failed to navigate into '\(name)'.")
                currentPath.removeLast() // Revert path change
                return false
            }
            return true
        }
    }

    func goUpDirectory() -> Bool {
         if currentPath.isEmpty { return false }
         currentPath.removeLast()
         return navigateToInternalPath()
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
            if bytesRead == 0 {
                break
            }
            fileData.append(buffer, count: Int(bytesRead))
        }
        return fileData
    }
    
    func writeTextFile(entry: AmigaEntry, content: String) -> String? {
        guard let vol = self.adfVolume, entry.type == .file else { return "Invalid entry or volume." }
        if !navigateToInternalPath() {
            return getADFLibError(context: "navigateToInternalPath for \(entry.name) before writeTextFile")
        }

        // Pre-process the string to replace common macOS "smart" punctuation with plain ASCII.
        var processedContent = content
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "…", with: "...")
            .replacingOccurrences(of: "—", with: "--")
        
        // Normalize line endings to LF (\n), which is standard for AmigaDOS.
        processedContent = processedContent.replacingOccurrences(of: "\r\n", with: "\n")
        
        guard let data = processedContent.data(using: .isoLatin1) else {
            return "Failed to encode string to Amiga-compatible format."
        }
        
        let result = data.withUnsafeBytes { (bufferPtr: UnsafeRawBufferPointer) -> ADF_RETCODE in
            let unsafePointer = bufferPtr.baseAddress?.assumingMemoryBound(to: UInt8.self)
            
            return entry.name.withCString { cAmigaPath in
                return add_file_to_adf_c(vol, cAmigaPath, unsafePointer, UInt32(data.count))
            }
        }
        
        if result.rawValue == ADF_RC_OK_SWIFT {
            print("ADFService: Successfully wrote to '\(entry.name)'.")
            populateDiskInfo() // Refresh disk info, as size may have changed.
            return nil
        } else {
            print("ADFService: add_file_to_adf_c failed for '\(entry.name)'. Check C-Log for details.")
            return "ADFlib failed to write the file. The disk may be full."
        }
    }
    
    func addFile(from url: URL) -> String? {
        guard let vol = self.adfVolume else { return "Volume not mounted." }
        
        if !navigateToInternalPath() {
            return "Failed to navigate to current ADF directory."
        }
        
        guard let data = try? Data(contentsOf: url) else {
            return "Could not read data from local file."
        }
        
        let amigaPath = url.lastPathComponent
        
        let result = data.withUnsafeBytes { (bufferPtr: UnsafeRawBufferPointer) -> ADF_RETCODE in
            let unsafePointer = bufferPtr.baseAddress?.assumingMemoryBound(to: UInt8.self)
            
            return amigaPath.withCString { cAmigaPath in
                return add_file_to_adf_c(vol, cAmigaPath, unsafePointer, UInt32(data.count))
            }
        }
        
        if result.rawValue == ADF_RC_OK_SWIFT {
            print("ADFService: Successfully added '\(amigaPath)'.")
            populateDiskInfo()
            return nil
        } else {
            print("ADFService: add_file_to_adf_c failed for '\(amigaPath)'. Check C-Log for details.")
            return "ADFlib failed to write the file. The disk may be full."
        }
    }

    func createDirectory(name: String, force: Bool) -> String? {
        guard let vol = self.adfVolume else {
            return "Cannot create directory, volume is nil."
        }
        if !navigateToInternalPath() {
            return "Cannot create directory, failed to navigate to current path."
        }
        
        let parentSector = vol.pointee.curDirPtr
        
        if !force {
            var parentBlock = AdfEntryBlock()
            if adfReadEntryBlock(vol, parentSector, &parentBlock).rawValue != ADF_RC_OK_SWIFT {
                return "Could not read parent directory information to check permissions."
            }
            if (UInt32(parentBlock.access) & ACCMASK_W_SWIFT) != 0 {
                return "Parent directory is write-protected. (Use 'Force Operations' to override)."
            }
        }
        
        let success = name.withCString { cName -> Bool in
            return adfCreateDir(vol, parentSector, cName).rawValue == ADF_RC_OK_SWIFT
        }
        
        if success {
            populateDiskInfo()
            return nil
        } else {
            print("ADFService: adfCreateDir failed. Check C-Log for details.")
            return "ADFLib failed to create the directory."
        }
    }
    
    func deleteEntryRecursively(entry: AmigaEntry, force: Bool) -> String? {
        let originalPath = self.currentPath
        let result = _deleteRecursively(entryToDelete: entry, force: force)
        self.currentPath = originalPath
        if !navigateToInternalPath() {
            print("ADFService: CRITICAL - Failed to restore path to \(originalPath.joined(separator: "/")) after deletion operation.")
        }
        if result == nil {
            populateDiskInfo()
        }
        return result
    }

    private func _deleteRecursively(entryToDelete: AmigaEntry, force: Bool) -> String? {
        guard let vol = self.adfVolume else { return "Volume not mounted." }
        
        if !force && (entryToDelete.protectionBits & ACCMASK_D_SWIFT) != 0 {
            return "Entry '\(entryToDelete.name)' is delete-protected."
        }
        
        if entryToDelete.type == .directory {
            if !navigateToDirectory(entryToDelete.name) {
                return "Failed to navigate into directory '\(entryToDelete.name)' to empty it."
            }
            
            let children = listCurrentDirectory()
            for child in children {
                if let error = _deleteRecursively(entryToDelete: child, force: force) {
                    _ = goUpDirectory()
                    return error
                }
            }
            
            if !goUpDirectory() {
                 return "Failed to navigate out of directory '\(entryToDelete.name)' after emptying it. Cannot complete deletion."
            }
        }
        
        let parentSector = vol.pointee.curDirPtr
        let success = entryToDelete.name.withCString { cName -> Bool in
            return adfRemoveEntry(vol, parentSector, cName).rawValue == ADF_RC_OK_SWIFT
        }
        
        if success {
            print("ADFService: Successfully deleted '\(entryToDelete.name)'.")
            return nil
        } else {
            print("ADFService: adfRemoveEntry failed for '\(entryToDelete.name)'. Check C-Log for details.")
            return "ADFLib failed to delete '\(entryToDelete.name)'."
        }
    }

    func renameEntry(oldName: String, newName: String) -> String? {
        guard let vol = self.adfVolume else { return "Volume is not open." }
        if newName.isEmpty { return "New name cannot be empty." }
        
        if !navigateToInternalPath() {
            return "Failed to navigate to current path."
        }
        
        let parentSector = vol.pointee.curDirPtr
        let success = oldName.withCString { cOldName -> Bool in
            return newName.withCString { cNewName -> Bool in
                return adfRenameEntry(vol, parentSector, cOldName, parentSector, cNewName).rawValue == ADF_RC_OK_SWIFT
            }
        }
        
        if success {
            print("ADFService: Renamed '\(oldName)' to '\(newName)'.")
            return nil
        } else {
            print("ADFService: adfRenameEntry failed. Check C-Log for details.")
            return "ADFLib failed to rename the entry. A file with the new name may already exist."
        }
    }
    
    func renameVolume(newName: String) -> String? {
        guard let vol = self.adfVolume else { return "Volume not mounted." }

        let maxLen = Int(ADF_MAX_NAME_LEN)
        var finalName = newName
        if newName.count > maxLen {
            finalName = String(newName.prefix(maxLen))
        }
        if finalName.contains(":") || finalName.contains("/") {
            return "Volume name cannot contain ':' or '/'."
        }

        let rootBlockSector = adfVolCalcRootBlk(vol)
        var rootBlock = AdfRootBlock()
        guard adfReadRootBlock(vol, UInt32(rootBlockSector), &rootBlock) == ADF_RC_OK else {
            return "Failed to read the volume's root block."
        }

        rootBlock.nameLen = UInt8(finalName.count)
        let cName = finalName.cString(using: .utf8)!
        withUnsafeMutableBytes(of: &rootBlock.diskName) { buffer in
            buffer.baseAddress?.initializeMemory(as: UInt8.self, repeating: 0, count: buffer.count)
            
            cName.withUnsafeBytes { cNameBuffer in
                let count = min(buffer.count - 1, cNameBuffer.count)
                buffer.baseAddress!.copyMemory(from: cNameBuffer.baseAddress!, byteCount: count)
            }
        }
        
        guard adfWriteRootBlock(vol, UInt32(rootBlockSector), &rootBlock) == ADF_RC_OK else {
            return "Failed to write the updated root block."
        }

        finalName.withCString { cFinalName in
            adf_set_vol_name(vol, cFinalName)
        }

        populateDiskInfo()
        return nil
    }
    
    func exportEntry(entry: AmigaEntry, toDirectory destinationURL: URL) -> String? {
        let originalPath = self.currentPath
        let result = _exportRecursively(entry: entry, toDirectory: destinationURL)
        
        self.currentPath = originalPath
        if !navigateToInternalPath() {
            return "Critical Error: Failed to restore ADF path after export. Please reopen the ADF."
        }
        
        return result
    }

    private func _exportRecursively(entry: AmigaEntry, toDirectory destinationURL: URL) -> String? {
        let exportPath = destinationURL.appendingPathComponent(entry.name)
        
        if entry.type == .file {
            guard let fileData = readFileContent(entry: entry) else {
                return "Could not read content of file '\(entry.name)' from ADF."
            }
            do {
                try fileData.write(to: exportPath)
            } catch {
                return "Failed to write file '\(entry.name)' to local disk: \(error.localizedDescription)"
            }
        } else if entry.type == .directory {
            do {
                try FileManager.default.createDirectory(at: exportPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return "Failed to create local directory for '\(entry.name)': \(error.localizedDescription)"
            }
            
            if !navigateToDirectory(entry.name) {
                return "Failed to navigate into ADF directory '\(entry.name)'."
            }
            
            let children = listCurrentDirectory()
            for child in children {
                if let error = _exportRecursively(entry: child, toDirectory: exportPath) {
                    _ = goUpDirectory()
                    return error
                }
            }
            
            if !goUpDirectory() {
                return "Failed to navigate up from ADF directory '\(entry.name)'."
            }
        }
        
        return nil
    }

    func createNewBlankADF(volumeName: String, fsType: UInt8) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "blank_\(UUID().uuidString).adf"
        let tempURL = tempDir.appendingPathComponent(fileName)
        let tempPath = tempURL.path
        
        print("ADFService: Creating new blank ADF at: \(tempPath) with FS Type: \(fsType)")
        
        let success = tempPath.withCString { cPath in
            volumeName.withCString { cVolName in
                return create_blank_adf_c(cPath, cVolName, fsType).rawValue == ADF_RC_OK_SWIFT
            }
        }

        guard success else {
            print("ADFService: create_blank_adf_c helper failed.")
            return nil
        }
        
        if openADF(filePath: tempPath) {
            print("ADFService: Successfully created and opened new ADF.")
            return tempURL
        } else {
            print("ADFService: Failed to open the newly created ADF.")
            return nil
        }
    }
}
