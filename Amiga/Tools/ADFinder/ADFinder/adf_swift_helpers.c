//
//  adf_swift_helpers.c
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//

#include "adf_swift_helpers.h"
#include <stddef.h> // For NULL
#include <stdio.h>  // For vsnprintf
#include <stdarg.h> // For va_list, va_start, va_end
#include <stdlib.h> // For malloc, free

// Declaring the Swift function that our C shim will call.
extern void swift_log_bridge(const char* msg);

static void c_variadic_log_handler(const char* format, ...) {
    va_list args;
    va_start(args, format);

    // Determine required size
    va_list args_copy;
    va_copy(args_copy, args);
    int len = vsnprintf(NULL, 0, format, args_copy);
    va_end(args_copy);

    if (len >= 0) {
        char* buffer = malloc(len + 1);
        if (buffer) {
            vsnprintf(buffer, len + 1, format, args);
            // Call the actual Swift logging function
            swift_log_bridge(buffer);
            free(buffer);
        }
    }
    va_end(args);
}

void setup_logging(void) {
    // Pass the C shim function pointer to ADFLib
    adfEnvSetFct(c_variadic_log_handler, c_variadic_log_handler, c_variadic_log_handler, NULL);
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

// Implementation for the driver registration helper
ADF_RETCODE register_dump_driver_helper(void) {
    return adfAddDeviceDriver(&adfDeviceDriverDump);
}

