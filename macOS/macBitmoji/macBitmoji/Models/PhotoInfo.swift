//
//  macBitmoji Edition
//
//
//  PhotoInfo.swift
//  macBitmoji
//
//  Created by Mario Esposito on 4/7/20.
//

import Cocoa

class PhotoInfo {
    var url: URL?
    var thumbnail: NSImage?
    
    init(with url: URL) {
        self.url = url
    }
}
