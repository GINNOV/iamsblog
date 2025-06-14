//
//  adf_swift_bridge_constants.h
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

#ifndef ADF_SWIFT_BRIDGE_CONSTANTS_H
#define ADF_SWIFT_BRIDGE_CONSTANTS_H

#include <stdint.h>
#include "adf_blk.h" // For ADF_DOSFS_* constants

// AdfAccessMode enum cases
static const unsigned int ACCESS_MODE_READONLY_SWIFT  = 1;
static const unsigned int ACCESS_MODE_READWRITE_SWIFT = 0;

// AdfFileMode enum cases
static const unsigned int ADF_FILE_MODE_READ_SWIFT  = 0x01;
static const unsigned int ADF_FILE_MODE_WRITE_SWIFT = 0x02;

static const uint32_t FIBF_READ_SWIFT    = (1 << 15);
static const uint32_t FIBF_WRITE_SWIFT   = (1 << 14);
static const uint32_t FIBF_EXECUTE_SWIFT = (1 << 13);
static const uint32_t FIBF_DELETE_SWIFT  = (1 << 12);
static const uint32_t FIBF_HOLD_SWIFT    = (1 << 7);
static const uint32_t FIBF_SCRIPT_SWIFT  = (1 << 6);
static const uint32_t FIBF_PURE_SWIFT    = (1 << 5);
static const uint32_t FIBF_ARCHIVE_SWIFT = (1 << 4);

// In AmigaDOS, if a protection bit is SET, the action is DISALLOWED.
static const uint32_t ACCMASK_D_SWIFT = (1 << 0); // Delete protection
static const uint32_t ACCMASK_W_SWIFT = (1 << 2); // Write protection

static const int32_t ST_FILE_SWIFT  = -3;
static const int32_t ST_DIR_SWIFT   =  2;
static const int32_t ST_LFILE_SWIFT = -4;
static const int32_t ST_LDIR_SWIFT  =  4;

static const int32_t ADF_RC_OK_SWIFT = 0;

static const uint8_t FS_TYPE_OFS_SWIFT = ADF_DOSFS_OFS;
static const uint8_t FS_TYPE_FFS_SWIFT = ADF_DOSFS_FFS;

#endif /* ADF_SWIFT_BRIDGE_CONSTANTS_H */
