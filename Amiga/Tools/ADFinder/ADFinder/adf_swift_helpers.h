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
#include "adf_env.h"

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
#endif /* ADF_SWIFT_HELPERS_H */

