//
//  adf_swift_helpers.c
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

#include "adf_swift_helpers.h"
#include <stddef.h> // For NULL

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

// Implementation for the driver registration helper
ADF_RETCODE register_dump_driver_helper(void) {
    // In C, passing &adfDeviceDriverDump is correct because adfDeviceDriverDump is a global
    // and adfAddDeviceDriver expects 'const struct AdfDeviceDriver *'.
    return adfAddDeviceDriver(&adfDeviceDriverDump);
}

