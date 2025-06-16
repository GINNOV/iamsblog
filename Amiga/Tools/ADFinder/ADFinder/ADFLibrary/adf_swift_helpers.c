//
//  adf_swift_helpers.c
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

#include "adf_swift_helpers.h"
#include "adf_env.h"
#include "adf_dev_flop.h"
#include "adf_blk.h"
#include "adf_err.h"
#include "adf_file.h"
#include "adf_raw.h"
#include <stddef.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>


extern void swift_log_bridge(const char* msg);

static void c_variadic_log_handler(const char* format, ...) {
    va_list args;
    va_start(args, format);

    va_list args_copy;
    va_copy(args_copy, args);
    int len = vsnprintf(NULL, 0, format, args_copy);
    va_end(args_copy);

    if (len >= 0) {
        char* buffer = malloc(len + 1);
        if (buffer) {
            vsnprintf(buffer, len + 1, format, args);
            swift_log_bridge(buffer);
            free(buffer);
        }
    }
    va_end(args);
}

void setup_logging(void) {
    adfEnvSetFct(c_variadic_log_handler, c_variadic_log_handler, c_variadic_log_handler, NULL);
}

void adf_set_vol_name(struct AdfVolume* vol, const char* newName) {
    if (vol == NULL) {
        return;
    }
    if (vol->volName != NULL) {
        free(vol->volName);
    }
    vol->volName = strdup(newName);
}

ADF_RETCODE create_blank_adf_c(const char* path, const char* volName, uint8_t fsType) {
    char* mutablePath = strdup(path);
    if (!mutablePath) { return ADF_RC_MALLOC; }

    struct AdfDevice *device = adfDevCreate("dump", mutablePath, 80, 2, 11);
    free(mutablePath);
    
    if (!device) {
        return ADF_RC_FOPEN;
    }
    
    char* mutableVolName = strdup(volName);
    if (!mutableVolName) {
        adfDevClose(device);
        return ADF_RC_MALLOC;
    }

    ADF_RETCODE rc = adfCreateFlop(device, mutableVolName, fsType);
    free(mutableVolName);
    
    adfDevClose(device);
    
    return rc;
}

ADF_RETCODE add_file_to_adf_c(
    struct AdfVolume* vol,
    const char* amigaPath,
    const uint8_t* buffer,
    uint32_t bufferSize
) {
    if (!vol || !amigaPath || !buffer) {
        return ADF_RC_NULLPTR;
    }

    struct AdfFile* file = adfFileOpen(vol, amigaPath, ADF_FILE_MODE_WRITE);
    if (!file) {
        return ADF_RC_ERROR;
    }
    
    uint32_t bytesWritten = adfFileWrite(file, bufferSize, buffer);
    
    adfFileClose(file);
    
    if (bytesWritten != bufferSize) {
        return ADF_RC_VOLFULL;
    }
    
    return ADF_RC_OK;
}


uint32_t get_AdfEntry_year(const struct AdfEntry* entry) { return entry ? entry->year : 0; }
uint32_t get_AdfEntry_month(const struct AdfEntry* entry) { return entry ? entry->month : 0; }
uint32_t get_AdfEntry_days(const struct AdfEntry* entry) { return entry ? entry->days : 0; }
uint32_t get_AdfEntry_hour(const struct AdfEntry* entry) { return entry ? entry->hour : 0; }
uint32_t get_AdfEntry_mins(const struct AdfEntry* entry) { return entry ? entry->mins : 0; }
uint32_t get_AdfEntry_secs(const struct AdfEntry* entry) { return entry ? entry->secs : 0; }
uint32_t get_AdfEntry_access(const struct AdfEntry* entry) { return entry ? entry->access : 0; }
uint32_t get_AdfEntry_size(const struct AdfEntry* entry) { return entry ? entry->size : 0; }
int32_t  get_AdfEntry_type(const struct AdfEntry* entry) { return entry ? entry->type : 0; }
const char* get_AdfEntry_name_ptr(const struct AdfEntry* entry) { return entry ? entry->name : NULL; }
const char* get_AdfEntry_comment_ptr(const struct AdfEntry* entry) {
    if (entry && entry->comment[0] != '\0') { return entry->comment; }
    return NULL;
}

ADF_RETCODE register_dump_driver_helper(void) {
    return adfAddDeviceDriver(&adfDeviceDriverDump);
}

// : The logic here is now corrected. Checksum is validated BEFORE byte swapping. #END_REVIEW
ADF_RETCODE parse_boot_block(const uint8_t* data, struct AdfBootBlock* boot) {
    if (!data || !boot) return ADF_RC_NULLPTR;
    
    // 1. Copy the raw bytes. The data is still in big-endian (network) order.
    memcpy(boot, data, sizeof(struct AdfBootBlock));
    
    // 2. Validate the checksum on the original big-endian data.
    if (boot->checkSum != adfBootSum((uint8_t*)boot)) {
        return ADF_RC_BLOCKSUM;
    }
    
    // 3. Now that the block is validated, swap to host byte order for use in Swift.
    adfSwapEndian((uint8_t*)boot, ADF_SWBL_BOOT);
    
    return ADF_RC_OK;
}

// : The logic here is now corrected. Checksum is validated BEFORE byte swapping. #END_REVIEW
ADF_RETCODE parse_root_block(const uint8_t* adf_data, uint32_t block_size, uint32_t root_block_sector, struct AdfRootBlock* root) {
    if (!adf_data || !root) return ADF_RC_NULLPTR;
    
    const uint8_t* root_block_ptr = adf_data + (root_block_sector * block_size);
    // 1. Copy the raw bytes. Data is still in big-endian order.
    memcpy(root, root_block_ptr, sizeof(struct AdfRootBlock));
    
    // 2. Validate the checksum on the original big-endian data.
    if (root->checkSum != adfNormalSum((uint8_t*)root, offsetof(struct AdfRootBlock, checkSum), sizeof(struct AdfRootBlock))) {
        return ADF_RC_BLOCKSUM;
    }
    
    // 3. Checksum is valid. Now swap to host byte order for use in Swift.
    adfSwapEndian((uint8_t*)root, ADF_SWBL_ROOT);
    
    return ADF_RC_OK;
}
