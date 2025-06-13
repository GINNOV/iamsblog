//
//  Formatters.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/13/25.
//

import Foundation

// AI_REVIEW: This file is intended for helper functions that format data for display.
// This function was moved from DetailView to be a global utility.

/// Takes the protection bits from an Amiga file and formats them into a human-readable string.
/// - Parameter bits: The 32-bit integer representing the protection flags.
/// - Returns: A formatted string like "R✔W-E-D- [hspa:--P-]"
func formatProtectionBits(_ bits: UInt32) -> String {
    // In AmigaDOS, a SET bit means the action is DISALLOWED (protection is ON).
    // The C-level constants like ACCMASK_D_SWIFT represent these protection bits.
    // Therefore, if the bit is present, the corresponding action is NOT allowed.
    let canDelete = (bits & ACCMASK_D_SWIFT) == 0
    let canWrite = (bits & ACCMASK_W_SWIFT) == 0
    
    // The R and E bits in the 'access' field of an entry block are not standard
    // AmigaDOS protection bits. They are typically used for other purposes or are zero.
    // The primary protection flags are D, E, W, R for Owner, Group, Other.
    // The simplified view uses D(elete), W(rite), R(ead), E(xecute).
    // Let's assume for this view, we check the main 'fibf' style bits if they were there.
    // Since they aren't in the struct, we will just show Write/Delete from the access field.
    // The original code was checking constants like FIBF_READ_SWIFT, which don't seem to be
    // correctly populated from the AdfEntry struct. I am correcting this to reflect what's
    // available, which is primarily the Delete and Write protection from the `access` field.
    let rwed = "R?W\(canWrite ? "✔" : "-")E?D\(canDelete ? "✔" : "-")"
    
    // These are the "special" flags.
    let hold = (bits & FIBF_HOLD_SWIFT) != 0
    let script = (bits & FIBF_SCRIPT_SWIFT) != 0
    let pure = (bits & FIBF_PURE_SWIFT) != 0
    let archive = (bits & FIBF_ARCHIVE_SWIFT) != 0
    
    let hspa = "[hspa:\(hold ? "H" : "-")\(script ? "S" : "-")\(pure ? "P" : "-")\(archive ? "A" : "-")]"
    
    return "\(rwed) \(hspa)"
}
