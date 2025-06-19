//
//  IFFImageLoader.swift
//  ILBMViewer
//
//  Created by Mario Esposito on 6/18/25.
//

// Add this extension to your IFFImageLoader.swift file
extension String {
    /// Converts a 4-character string into a UInt32 FourCC code.
    var fourCC: UInt32 {
        guard self.count == 4 else { return 0 }
        var result: UInt32 = 0
        for scalar in self.unicodeScalars {
            result = (result << 8) | (scalar.value & 0xFF)
        }
        return result
    }
}
