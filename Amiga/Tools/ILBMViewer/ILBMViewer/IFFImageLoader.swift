//
//  IFFImageLoader.swift
//  ILBMViewer
//
//  Created by Mario Esposito on 6/18/25.
//

import Foundation
import CoreGraphics
import SwiftUI // For UIImage/NSImage conversion later
import CLibIFF // <-- This is our C library package!

class IFFImageLoader {

    /// Loads an IFF file from a URL and attempts to decode it into a CGImage.
    func loadImage(from url: URL) -> CGImage? {
        // 1. Use the C library to read the IFF file structure into memory.
        //    IFF_read returns a pointer to the top-level IFF chunk.
        guard let iffChunk = IFF_read(url.path, nil) else {
            print("Failed to read IFF file at path: \(url.path)")
            return nil
        }
        
        // 2. Use `defer` to ensure the memory allocated by the C library is always freed.
        defer {
            IFF_free(iffChunk, nil)
        }

        // 3. Search for the 'ILBM' (Interleaved Bitmap) FORM. This identifies it as an image.
        guard let ilbmForm = IFF_searchForms(iffChunk, "ILBM", nil) else {
            print("No ILBM form found in the IFF file.")
            return nil
        }

        // 4. Extract the Bitmap Header ('BMHD') chunk to get image dimensions.
        guard let bmhdChunk = IFF_search(ilbmForm, "BMHD"),
              // Safely access the C struct data from the pointer.
              let bmhdData = bmhdChunk.pointee.chunk_data else {
            print("BMHD chunk not found or is empty.")
            return nil
        }
        let bmhd = bmhdData.assumingMemoryBound(to: IFF_BodyBMHD.self).pointee
        let width = Int(bmhd.w)
        let height = Int(bmhd.h)
        let bitplanes = Int(bmhd.nPlanes)
        
        print("Found ILBM: \(width)x\(height) with \(bitplanes) bitplanes.")

        // 5. Extract the Color Map ('CMAP') chunk for the image's palette.
        guard let cmapChunk = IFF_search(ilbmForm, "CMAP"),
              let cmapData = cmapChunk.pointee.chunk_data else {
            print("CMAP chunk not found or is empty.")
            return nil
        }
        let colorCount = cmapChunk.pointee.chunk_size / 3
        var palette: [(r: UInt8, g: UInt8, b: UInt8)] = []
        for i in 0..<colorCount {
            let offset = i * 3
            let r = cmapData.load(fromByteOffset: offset, as: UInt8.self)
            let g = cmapData.load(fromByteOffset: offset + 1, as: UInt8.self)
            let b = cmapData.load(fromByteOffset: offset + 2, as: UInt8.self)
            palette.append((r, g, b))
        }
        
        // 6. Find the 'BODY' chunk, which contains the raw, planar pixel data.
        guard let bodyChunk = IFF_search(ilbmForm, "BODY"),
              let bodyData = bodyChunk.pointee.chunk_data else {
            print("BODY chunk not found or is empty.")
            return nil
        }
        
        // 7. De-interleave the planar image data into a modern "chunky" RGBA format.
        //    This is the most complex part, converting Amiga's format to one Core Graphics can use.
        var pixelData = [UInt8](repeating: 0, count: width * height * 4) // RGBA buffer

        let bytesPerRowInPlane = (width + 15) / 16 * 2

        for y in 0..<height {
            for x in 0..<width {
                var colorIndex: UInt8 = 0
                for plane in 0..<bitplanes {
                    let byteOffset = y * bytesPerRowInPlane * bitplanes + plane * bytesPerRowInPlane + (x / 8)
                    let bitInByte = 7 - (x % 8)
                    let byteValue = bodyData.load(fromByteOffset: byteOffset, as: UInt8.self)
                    
                    if (byteValue >> bitInByte) & 1 == 1 {
                        colorIndex |= (1 << plane)
                    }
                }
                
                let pixelIndex = (y * width + x) * 4
                if Int(colorIndex) < palette.count {
                    let color = palette[Int(colorIndex)]
                    pixelData[pixelIndex]     = color.r // Red
                    pixelData[pixelIndex + 1] = color.g // Green
                    pixelData[pixelIndex + 2] = color.b // Blue
                    pixelData[pixelIndex + 3] = 255     // Alpha (fully opaque)
                }
            }
        }
        
        // 8. Create a CGImage from our generated raw RGBA pixel buffer.
        return createCGImage(from: pixelData, width: width, height: height)
    }

    /// Helper function to create a CGImage from a raw RGBA byte array.
    private func createCGImage(from pixelData: [UInt8], width: Int, height: Int) -> CGImage? {
        let bitsPerComponent = 8
        let bitsPerPixel = 32 // 4 components (R,G,B,A) * 8 bits each
        let bytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let provider = CGDataProvider(data: Data(pixelData) as CFData) else {
            return nil
        }

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}
