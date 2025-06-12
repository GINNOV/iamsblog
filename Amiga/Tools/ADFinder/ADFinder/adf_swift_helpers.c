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

ADF_RETCODE create_blank_adf_c(const char* path, const char* volName) {
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

    ADF_RETCODE rc = adfCreateFlop(device, mutableVolName, ADF_DOSFS_OFS);
    
    free(mutableVolName);
    adfDevClose(device);
    
    return rc;
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
