//
//  macBitmoji Edition
//
//  PhotoHelper.swift
//
//  Created by Mario Esposito on 4/7/20.
//

import Cocoa

class PhotoHelper {
    // MARK: - Properties
    
    static let shared = PhotoHelper()
    
    private(set) var photosToProcess = [PhotoInfo]()
    
    private var progressHandler: ((_ current: Int) -> Void)?
    
    var queue: DispatchQueue?
    
    
    // MARK: - Init
    
    private init() {
        
    }
    
    
    // MARK: - Custom Methods
    
    func createThumbnails(for photos: [PhotoInfo],
                          desiredSize size: NSSize,
                          progress: @escaping (_ currentPhoto: Int) -> Void,
                          completion: @escaping () -> Void) {
        
        progressHandler = progress
        photosToProcess = photos
        
        queue = DispatchQueue(label: "createThumbnailsQueue", qos: .utility)
        queue?.async {
            self.createThumbnail(fromPhotoURLAt: 0, resizeTo: size) {
                completion()
            }
        }
    }
    
    
    func importPhotoURLs(from selectedURL: URL, to collection: inout [PhotoInfo]) {
        guard let enumerator = FileManager.default.enumerator(at: selectedURL,
                                                              includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
                                                              options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles],
                                                              errorHandler: nil) else { return }
                
        enumerator.forEach { (url) in
            guard let url = url as? URL else { return }
            do {
                guard let isDir = try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory else { return }
                if !isDir {
                    let allowedPhotoExtensions = ["png", "jpg", "jpeg", "JPG", "PNG"]
                    if allowedPhotoExtensions.contains(url.pathExtension) {
                        collection.append(PhotoInfo(with: url))
                    }
                }
                
            } catch { print(error.localizedDescription) }
        }
    }
    
    
    
    // MARK: - Private Methods
    
    private func createThumbnail(fromPhotoURLAt index: Int, resizeTo size: NSSize, completion: @escaping () -> Void) {
        if index < photosToProcess.count {
            createThumbnail(fromPhotoURLAt: index + 1, resizeTo: size) {
                self.queue?.asyncAfter(deadline: .now() + 0.001) {
                    
                    self.progressHandler?(self.photosToProcess.count - index)

                    let photoIndex = self.photosToProcess.count - index - 1
                    self.photosToProcess[photoIndex].thumbnail = self.resize(photoAt: self.photosToProcess[photoIndex].url, to: size)
                    
                    completion()
                }
            }
            
        } else {
            completion()
        }
    }
    
    
    private func resize(photoAt url: URL?, to size: NSSize) -> NSImage? {
        if let url = url, let photo = NSImage(contentsOf: url) {
            let ratio = photo.size.width > photo.size.height ? size.width / photo.size.width : size.height / photo.size.height
            var rect = NSRect(origin: .zero, size: NSSize(width: photo.size.width * ratio, height: photo.size.height * ratio))
            rect.origin = NSPoint(x: (size.width - rect.size.width)/2, y: (size.height - rect.size.height)/2)
            let thumbnail = NSImage(size: size)
            thumbnail.lockFocus()
            photo.draw(in: rect,
                       from: NSRect(origin: .zero, size: photo.size),
                       operation: .copy, fraction: 1.0)
            thumbnail.unlockFocus()
            return thumbnail
        }
        
        return nil
    }
    
}

