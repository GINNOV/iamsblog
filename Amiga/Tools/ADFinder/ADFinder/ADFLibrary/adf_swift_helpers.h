//
//  adf_swift_helpers.h
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

#ifndef ADF_SWIFT_HELPERS_H
#define ADF_SWIFT_HELPERS_H

#include "adf_types.h" // For uint32_t, int32_t, SECTNUM
#include "adf_dir.h"   // For the full definition of struct AdfEntry
#include "adf_env.h"   // For AdfLogFct type
#include "adf_vol.h"   // For struct AdfVolume
#include "adf_blk.h"   // For struct AdfBootBlock, AdfRootBlock

// For register_dump_driver_helper()
#include "adf_dev_drivers.h"
#include "adf_dev_driver_dump.h"

uint32_t get_AdfEntry_year(const struct AdfEntry* entry);
uint32_t get_AdfEntry_month(const struct AdfEntry* entry);
uint32_t get_AdfEntry_days(const struct AdfEntry* entry);
uint32_t get_AdfEntry_hour(const struct AdfEntry* entry);
uint32_t get_AdfEntry_mins(const struct AdfEntry* entry);
uint32_t get_AdfEntry_secs(const struct AdfEntry* entry);

uint32_t get_AdfEntry_access(const struct AdfEntry* entry);
uint32_t get_AdfEntry_size(const struct AdfEntry* entry);
int32_t  get_AdfEntry_type(const struct AdfEntry* entry);
const char* get_AdfEntry_name_ptr(const struct AdfEntry* entry);
const char* get_AdfEntry_comment_ptr(const struct AdfEntry* entry);

ADF_RETCODE register_dump_driver_helper(void);

void setup_logging(void);

void adf_set_vol_name(struct AdfVolume* vol, const char* newName);

// accepts a filesystem type parameter (OFS or FFS).
ADF_RETCODE create_blank_adf_c(const char* path, const char* volName, uint8_t fsType);

ADF_RETCODE add_file_to_adf_c(
    struct AdfVolume* vol,
    const char* amigaPath,
    const uint8_t* buffer,
    uint32_t bufferSize
);

ADF_RETCODE parse_boot_block(const uint8_t* data, struct AdfBootBlock* boot);
ADF_RETCODE parse_root_block(const uint8_t* adf_data, uint32_t block_size, uint32_t root_block_sector, struct AdfRootBlock* root);

#endif /* ADF_SWIFT_HELPERS_H */
