// File: Sources/SwiftLibIFF/IFF.swift
import Clibiff

public struct IFF {
    public static func read(filePath: String) -> UnsafeMutablePointer<IFF_Chunk>? {
        return IFF_read(filePath)
    }
    
    public static func free(chunk: UnsafeMutablePointer<IFF_Chunk>) {
        IFF_free(chunk, nil)
    }
}