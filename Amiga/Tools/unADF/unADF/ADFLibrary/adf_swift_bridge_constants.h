//
//  adf_swift_bridge_constants.h
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

#ifndef ADF_SWIFT_BRIDGE_CONSTANTS_H
#define ADF_SWIFT_BRIDGE_CONSTANTS_H

#include <stdint.h>
#include "adf_blk.h" // For ADF_DOSFS_* and protection constants

// AdfAccessMode enum cases
static const unsigned int ACCESS_MODE_READONLY_SWIFT  = 1;
static const unsigned int ACCESS_MODE_READWRITE_SWIFT = 0;

// AdfFileMode enum cases
static const unsigned int ADF_FILE_MODE_READ_SWIFT  = 0x01;
static const unsigned int ADF_FILE_MODE_WRITE_SWIFT = 0x02;

static const uint32_t FIBF_HOLD_SWIFT    = (1 << 7);
static const uint32_t FIBF_SCRIPT_SWIFT  = (1 << 6);
static const uint32_t FIBF_PURE_SWIFT    = (1 << 5);
static const uint32_t FIBF_ARCHIVE_SWIFT = (1 << 4);

// The H, S, P, A, R, W, E, D flags are *protection* bits (set = disallowed for R, W, E, D).
static const uint32_t ACCMASK_H_SWIFT = (1 << 7); // Hold protection
static const uint32_t ACCMASK_S_SWIFT = (1 << 6); // Script protection
static const uint32_t ACCMASK_P_SWIFT = (1 << 5); // Pure protection
static const uint32_t ACCMASK_A_SWIFT = (1 << 4); // Archive protection
static const uint32_t ACCMASK_R_SWIFT = (1 << 3); // Read protection
static const uint32_t ACCMASK_W_SWIFT = (1 << 2); // Write protection
static const uint32_t ACCMASK_E_SWIFT = (1 << 1); // Execute protection
static const uint32_t ACCMASK_D_SWIFT = (1 << 0); // Delete protection

static const int32_t ST_FILE_SWIFT  = -3;
static const int32_t ST_DIR_SWIFT   =  2;
static const int32_t ST_LFILE_SWIFT = -4;
static const int32_t ST_LDIR_SWIFT  =  4;

static const int32_t ADF_RC_OK_SWIFT = 0;

static const uint8_t FS_TYPE_OFS_SWIFT = ADF_DOSFS_OFS;
static const uint8_t FS_TYPE_FFS_SWIFT = ADF_DOSFS_FFS;

static const int HT_SIZE_SWIFT = 72;

#endif /* ADF_SWIFT_BRIDGE_CONSTANTS_H */
