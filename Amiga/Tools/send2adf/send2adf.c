#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <errno.h>
#include <time.h>
#include <stdarg.h>
#include <libgen.h>

// For directory handling and stat
#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>
#include <getopt.h>

/*
 * ADFlib headers from your working copy.
 * Ensure these paths are correct for your build environment (e.g., via -I flags).
 */
#include "adflib.h"
#include "adf_env.h"
#include "adf_dev.h"
#include "adf_vol.h"
#include "adf_file.h"
#include "adf_blk.h"
#include "adf_types.h"
#include "adf_err.h"
#include "adf_dev_flop.h"
#include "adf_dev_drivers.h"
#include "adf_dev_driver_dump.h"
#include "adf_dir.h"

// ANSI Color Codes
#define ANSI_COLOR_CYAN    "\x1b[36m"
#define ANSI_COLOR_RESET   "\x1b[0m"
#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_GREEN   "\x1b[32m"
#define ANSI_COLOR_YELLOW  "\x1b[33m"

// Global verbosity level
int verbosity_level = 0;

// Version information
#define VERSION_MAJOR "0"
#define VERSION_MINOR "5" 

// Forward declarations
static bool add_host_file_to_adf(struct AdfVolume *vol, const char *host_filepath, const char *amiga_filename);
static bool add_host_directory_to_adf_recursive(struct AdfVolume *vol, const char *host_dirpath, const char *current_amiga_path_for_log);


void debug_printf(int required_level, const char *format, ...) {
    if (verbosity_level >= required_level) {
        va_list args;
        if (required_level == 1 && verbosity_level == 1) { 
            fprintf(stderr, ANSI_COLOR_YELLOW "[INFO]  " ANSI_COLOR_RESET);
        } else if (verbosity_level >= 2) { 
             fprintf(stderr, ANSI_COLOR_YELLOW "[DEBUG] " ANSI_COLOR_RESET);
        }
        va_start(args, format);
        vfprintf(stderr, format, args);
        va_end(args);
    }
}

char* get_build_date() {
    static char build_date_str[9];
    time_t t = time(NULL);
    struct tm *tm_info = localtime(&t);
    strftime(build_date_str, sizeof(build_date_str), "%Y%m%d", tm_info);
    return build_date_str;
}

void print_usage(const char *prog_name) {
    char* build_date = get_build_date();
    printf(ANSI_COLOR_CYAN "Create ADF Images by x.com/WINDRAGO. Version %s.%s build (%s)\n" ANSI_COLOR_RESET,
           VERSION_MAJOR, VERSION_MINOR, build_date);
    printf("Usage: %s -o <output.adf> -N <volname> [-v] <file_or_dir1> [file_or_dir2 ...]\n", prog_name);
    printf("Options:\n");
    printf("  -o, --output  <filename>   Specify the output ADF filename (required).\n");
    printf("  -N, --volname <name>       Specify the volume name for the ADF (required).\n");
    printf("  -v, --verbose              Enable verbose messages. Use -vv for extensive debug.\n");
    printf("  -h, --help                 Display this help message.\n");
    printf("If a directory is provided as input, its contents will be added recursively.\n");
    printf("Example:\n");
    printf("  %s -o mydisk.adf -N MyVolume -vv fileA.txt my_project_dir\n", prog_name);
}

char* get_amiga_basename(const char *path) {
    char *path_copy = strdup(path);
    if (!path_copy) {
        perror("strdup failed in get_amiga_basename");
        return NULL;
    }
    char *bname = basename(path_copy);
    char *result = strdup(bname); 
    free(path_copy);
    if(!result){
        perror("strdup failed for basename result");
    }
    return result; 
}

// amiga_filename is the simple name of the file, to be created in the current ADF directory
static bool add_host_file_to_adf(struct AdfVolume *vol, const char *host_filepath, const char *amiga_filename) {
    // Construct full conceptual amiga path for logging
    // char full_amiga_path_log[FILENAME_MAX] = "";
    // Note: adfGetPathName is not a standard ADFlib function, this is conceptual for logging.
    // If you have a way to get current path from 'vol', use it. Otherwise, log simple name.
    // For now, we'll just use the simple name for logging consistency with creation.
    // If adfGetCurrentPath(vol, path_buffer, size) existed, it would be useful here.
    debug_printf(1, "Processing host file: '%s' -> ADF as '%s' (in current ADF dir)\n", host_filepath, amiga_filename);

    debug_printf(2, "Opening host file '%s' for reading...\n", host_filepath);
    FILE *host_file_ptr = fopen(host_filepath, "rb");
    if (!host_file_ptr) {
        fprintf(stderr, ANSI_COLOR_RED "Error: " ANSI_COLOR_RESET "Could not open host input file '%s': %s\n", host_filepath, strerror(errno));
        return false;
    }
    debug_printf(2, "Host file '%s' opened.\n", host_filepath);

    debug_printf(2, "Opening Amiga file '%s' in current ADF volume directory for writing...\n", amiga_filename);
    struct AdfFile *amiga_file_ptr = adfFileOpen(vol, amiga_filename, ADF_FILE_MODE_WRITE);
    if (!amiga_file_ptr) {
        fprintf(stderr, ANSI_COLOR_RED "Error: Could not create/open Amiga file '%s' in current ADF directory. ADFLib error occurred.\n" ANSI_COLOR_RESET, amiga_filename);
        fclose(host_file_ptr);
        return false;
    }
    debug_printf(2, "Amiga file '%s' opened in current ADF volume directory.\n", amiga_filename);

    unsigned char buffer[1024 * 4];
    size_t bytes_read;
    uint32_t bytes_written_total = 0;
    bool success = true;

    debug_printf(2, "Copying '%s' to ADF as '%s'...\n", host_filepath, amiga_filename);
    while ((bytes_read = fread(buffer, 1, sizeof(buffer), host_file_ptr)) > 0) {
        uint32_t current_bytes_written = adfFileWrite(amiga_file_ptr, (uint32_t)bytes_read, buffer);
        bytes_written_total += current_bytes_written;
        if (current_bytes_written != (uint32_t)bytes_read) {
            fprintf(stderr, ANSI_COLOR_RED "Warning: Failed to write all %zu bytes to Amiga file '%s' (wrote %u). Disk full? ADFLib error occurred.\n" ANSI_COLOR_RESET,
                    bytes_read, amiga_filename, current_bytes_written);
            success = false;
            break;
        }
    }
    if (ferror(host_file_ptr)) {
        fprintf(stderr, ANSI_COLOR_RED "Warning: Error reading host file '%s'\n" ANSI_COLOR_RESET, host_filepath);
        success = false;
    }
    debug_printf(2, "Finished copying data. Total bytes written: %u\n", bytes_written_total);

    debug_printf(2, "Closing Amiga file '%s'...\n", amiga_filename);
    adfFileClose(amiga_file_ptr); 
    debug_printf(2, "Closing host file '%s'...\n", host_filepath);
    fclose(host_file_ptr);

    if (success) {
        debug_printf(1, "Successfully added '%s' to ADF as '%s' (in current ADF dir).\n", host_filepath, amiga_filename);
    }
    return success;
}

// current_amiga_path_for_log is for logging the conceptual full path being built.
static bool add_host_directory_to_adf_recursive(struct AdfVolume *vol, const char *host_dirpath, const char *current_amiga_path_for_log) {
    debug_printf(1, "Recursively processing host directory '%s' -> to ADF path context '%s/'\n", host_dirpath, current_amiga_path_for_log);
    DIR *dir = opendir(host_dirpath);
    if (!dir) {
        fprintf(stderr, ANSI_COLOR_RED "Error: " ANSI_COLOR_RESET "Could not open host directory '%s': %s\n", host_dirpath, strerror(errno));
        return false;
    }

    struct dirent *entry;
    bool all_success = true;
    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

        char host_entry_path[FILENAME_MAX]; 
        snprintf(host_entry_path, sizeof(host_entry_path), "%s/%s", host_dirpath, entry->d_name);
        
        // Construct the conceptual full Amiga path for logging
        char next_amiga_path_for_log[FILENAME_MAX];
        if (strlen(current_amiga_path_for_log) == 0) {
            strncpy(next_amiga_path_for_log, entry->d_name, sizeof(next_amiga_path_for_log) -1);
             next_amiga_path_for_log[sizeof(next_amiga_path_for_log)-1] = '\0';
        } else {
            snprintf(next_amiga_path_for_log, sizeof(next_amiga_path_for_log), "%s/%s", current_amiga_path_for_log, entry->d_name);
        }


        struct stat entry_stat;
        if (stat(host_entry_path, &entry_stat) == -1) {
            fprintf(stderr, ANSI_COLOR_RED "Error: " ANSI_COLOR_RESET "Could not stat host path '%s': %s\n", host_entry_path, strerror(errno));
            all_success = false;
            continue;
        }

        if (S_ISDIR(entry_stat.st_mode)) {
            // entry->d_name is the simple name of the directory to create in current ADF dir
            debug_printf(2, "Creating Amiga directory '%s' (simple name: '%s') in current ADF directory (sector %u).\n", 
                         next_amiga_path_for_log, entry->d_name, (unsigned int)vol->curDirPtr);
            
            if (adfCreateDir(vol, vol->curDirPtr, entry->d_name) != ADF_RC_OK) {
                fprintf(stderr, ANSI_COLOR_RED "Error: Failed to create Amiga directory '%s'. ADFLib error occurred.\n" ANSI_COLOR_RESET, next_amiga_path_for_log);
                all_success = false;
            } else {
                debug_printf(2, "Successfully created Amiga directory '%s'. Changing into it.\n", next_amiga_path_for_log);
                if (adfChangeDir(vol, entry->d_name) == ADF_RC_OK) {
                    debug_printf(2, "Changed ADF current directory to '%s'. Recursing into host '%s'.\n", next_amiga_path_for_log, host_entry_path);
                    if (!add_host_directory_to_adf_recursive(vol, host_entry_path, next_amiga_path_for_log)) {
                        all_success = false; 
                    }
                    debug_printf(2, "Returning from recursion of '%s'. Changing to parent ADF directory.\n", next_amiga_path_for_log);
                    if (adfParentDir(vol) != ADF_RC_OK) {
                        fprintf(stderr, ANSI_COLOR_RED "Error: Failed to return to parent ADF directory from '%s'.\n" ANSI_COLOR_RESET, next_amiga_path_for_log);
                        // This is a more serious issue, might affect subsequent operations
                        all_success = false; 
                        // break; // Optionally stop all processing if context is lost
                    } else {
                        debug_printf(2, "Returned to parent ADF directory of '%s'.\n", next_amiga_path_for_log);
                    }
                } else {
                    fprintf(stderr, ANSI_COLOR_RED "Error: Failed to change into newly created Amiga directory '%s'.\n" ANSI_COLOR_RESET, next_amiga_path_for_log);
                    all_success = false;
                }
            }
        } else if (S_ISREG(entry_stat.st_mode)) {
            // entry->d_name is the simple filename to create in current ADF dir
            if (!add_host_file_to_adf(vol, host_entry_path, entry->d_name)) {
                all_success = false; 
            }
        } else {
            debug_printf(1, "Skipping non-regular file/directory: '%s'\n", host_entry_path);
        }
    }
    closedir(dir);
    debug_printf(1, "Exiting recursive processing for host directory '%s' (ADF context: '%s/')\n", host_dirpath, current_amiga_path_for_log);
    return all_success;
}


int main(int argc, char *argv[]) {
    char *output_filename = NULL;
    char *volume_name_arg = NULL; 
    int opt;

    static struct option long_options[] = {
        {"output",  required_argument, 0, 'o'},
        {"volname", required_argument, 0, 'N'},
        {"verbose", no_argument,       0, 'v'},
        {"help",    no_argument,       0, 'h'},
        {0, 0, 0, 0}
    };

    int option_index = 0;
    while ((opt = getopt_long(argc, argv, "o:N:vh", long_options, &option_index)) != -1) {
        switch (opt) {
            case 'o': output_filename = optarg; break;
            case 'N': volume_name_arg = optarg; break;
            case 'v': verbosity_level++; break;
            case 'h': print_usage(argv[0]); return EXIT_SUCCESS;
            default: print_usage(argv[0]); return EXIT_FAILURE;
        }
    }

    if (!output_filename || !volume_name_arg || optind >= argc) {
        if (!output_filename) fprintf(stderr, ANSI_COLOR_RED "Error: " ANSI_COLOR_RESET "Output ADF filename missing.\n");
        if (!volume_name_arg) fprintf(stderr, ANSI_COLOR_RED "Error: " ANSI_COLOR_RESET "Volume name missing.\n");
        if (optind >= argc) fprintf(stderr, ANSI_COLOR_RED "Error: " ANSI_COLOR_RESET "No input files or directories specified.\n");
        print_usage(argv[0]);
        return EXIT_FAILURE;
    }

    if (verbosity_level == 1) {
      debug_printf(1, "Verbose mode enabled.\n");
    } else if (verbosity_level >= 2) {
      debug_printf(2, "Extensive debug mode enabled (level %d).\n", verbosity_level);
    }
    
    if (argc - optind > 0) { 
        debug_printf(2, "First input item: %s%s\n", argv[optind], (argc - optind > 1) ? " (and others)" : "");
    }
    debug_printf(2, "Output ADF: %s\n", output_filename);
    debug_printf(2, "Volume name: %s\n", volume_name_arg);

    struct AdfDevice *device = NULL;
    struct AdfVolume *volume = NULL;
    bool adflib_initialized = false;

    debug_printf(2, "Initializing ADFlib with adfLibInit()...\n");
    if (adfLibInit() != ADF_RC_OK) {
        fprintf(stderr, ANSI_COLOR_RED "Error: Failed to initialize ADFLib.\n" ANSI_COLOR_RESET);
        return EXIT_FAILURE;
    }
    adflib_initialized = true;
    debug_printf(2, "ADFlib initialized.\n");

    debug_printf(2, "Explicitly adding dump device driver...\n");
    if (adfAddDeviceDriver(&adfDeviceDriverDump) != ADF_RC_OK) {
        fprintf(stderr, ANSI_COLOR_YELLOW "Warning: Failed to explicitly add dump device driver. Continuing anyway...\n" ANSI_COLOR_RESET);
    } else {
        debug_printf(2, "Dump device driver explicitly added successfully.\n");
    }

    debug_printf(2, "Attempting to create device with adfDevCreate(\"dump\", \"%s\", 80, 2, 11)\n", output_filename);
    device = adfDevCreate("dump", output_filename, 80, 2, 11); 
    if (!device) {
        fprintf(stderr, ANSI_COLOR_RED "Error: Failed to create ADF device '%s'. ADFLib error occurred.\n" ANSI_COLOR_RESET, output_filename);
        if (adflib_initialized) adfLibCleanUp();
        return EXIT_FAILURE;
    }
    debug_printf(2, "Device '%s' created successfully.\n", output_filename);

    debug_printf(2, "Creating floppy volume '%s' on device with adfCreateFlop()...\n", volume_name_arg);
    if (adfCreateFlop(device, volume_name_arg, ADF_DOSFS_OFS) != ADF_RC_OK) {
        fprintf(stderr, ANSI_COLOR_RED "Error: Failed to create/format floppy volume '%s'. ADFLib error occurred.\n" ANSI_COLOR_RESET, volume_name_arg);
        if (device) adfDevClose(device);
        if (adflib_initialized) adfLibCleanUp();
        return EXIT_FAILURE;
    }
    debug_printf(2, "Floppy volume '%s' created/formatted successfully by adfCreateFlop.\n", volume_name_arg);

    debug_printf(2, "Mounting device '%s' with adfDevMount()...\n", output_filename);
    if (adfDevMount(device) != ADF_RC_OK) {
        fprintf(stderr, ANSI_COLOR_RED "Error: Failed to mount device '%s'. ADFLib error occurred.\n" ANSI_COLOR_RESET, output_filename);
        if (device) adfDevClose(device);
        if (adflib_initialized) adfLibCleanUp();
        return EXIT_FAILURE;
    }
    debug_printf(2, "Device '%s' mounted successfully via adfDevMount.\n", output_filename);
    
    debug_printf(2, "Attempting to mount volume 0 from device '%s' with adfVolMount()...\n", output_filename);
    volume = adfVolMount(device, 0, ADF_ACCESS_MODE_READWRITE);
    if (!volume) {
        fprintf(stderr, ANSI_COLOR_RED "Error: Failed to mount volume 0 from device '%s'. ADFLib error occurred.\n" ANSI_COLOR_RESET, output_filename);
        if (device) adfDevUnMount(device); 
        if (device) adfDevClose(device);
        if (adflib_initialized) adfLibCleanUp();
        return EXIT_FAILURE;
    }
    const char *current_vol_name_display = volume->volName ? volume->volName : volume_name_arg;
    debug_printf(2, "Volume '%s' (from partition 0) mounted successfully via adfVolMount.\n", current_vol_name_display);
    if (volume->mounted) {
         debug_printf(2, "Volume '%s' reports itself as MOUNTED (volume->mounted is true) after adfVolMount.\n", current_vol_name_display);
    } else {
         debug_printf(2, ANSI_COLOR_RED "CRITICAL WARNING - Volume '%s' reports itself as NOT MOUNTED even after successful adfVolMount call.\n" ANSI_COLOR_RESET, current_vol_name_display);
    }

    bool all_items_success = true;
    for (int i = optind; i < argc; i++) {
        const char *host_item_path = argv[i];
        struct stat item_stat;

        debug_printf(2, "Processing top-level host item: '%s'\n", host_item_path);
        // Ensure ADF is at root for each top-level host item
        if (adfToRootDir(volume) != ADF_RC_OK) {
            fprintf(stderr, ANSI_COLOR_RED "Error: Failed to set ADF current directory to root before processing '%s'.\n" ANSI_COLOR_RESET, host_item_path);
            all_items_success = false;
            continue; 
        }
        debug_printf(2, "ADF current directory set to root (sector %u).\n", (unsigned int)volume->curDirPtr);


        if (stat(host_item_path, &item_stat) == -1) {
            fprintf(stderr, ANSI_COLOR_RED "Error: " ANSI_COLOR_RESET "Could not stat host path '%s': %s\n", host_item_path, strerror(errno));
            all_items_success = false;
            continue;
        }

        char *amiga_item_basename = get_amiga_basename(host_item_path);
        if (!amiga_item_basename) { 
            all_items_success = false;
            continue;
        }

        if (S_ISDIR(item_stat.st_mode)) {
            debug_printf(1, "Processing host directory: '%s' -> ADF as '%s/' (at root)\n", host_item_path, amiga_item_basename);
            // Create top-level directory in the root of the volume (vol->curDirPtr is root here)
            if (adfCreateDir(volume, volume->curDirPtr, amiga_item_basename) != ADF_RC_OK) {
                fprintf(stderr, ANSI_COLOR_RED "Error: Failed to create top-level Amiga directory '%s'. ADFLib error occurred.\n" ANSI_COLOR_RESET, amiga_item_basename);
                all_items_success = false;
            } else {
                debug_printf(2, "Successfully created top-level Amiga directory '%s'. Changing into it.\n", amiga_item_basename);
                if (adfChangeDir(volume, amiga_item_basename) == ADF_RC_OK) {
                    debug_printf(2, "Changed ADF current directory to '%s'. Recursing into host '%s'.\n", amiga_item_basename, host_item_path);
                    // Pass amiga_item_basename as the current Amiga path for logging purposes
                    if (!add_host_directory_to_adf_recursive(volume, host_item_path, amiga_item_basename)) {
                        all_items_success = false;
                    }
                    // After recursion, return to root for the next top-level item processing
                    debug_printf(2, "Returning ADF current directory to root after processing '%s'.\n", amiga_item_basename);
                    if (adfToRootDir(volume) != ADF_RC_OK) {
                         fprintf(stderr, ANSI_COLOR_RED "Error: Failed to return to root ADF directory after '%s'.\n" ANSI_COLOR_RESET, amiga_item_basename);
                         all_items_success = false; // Critical if context is lost
                    }
                } else {
                     fprintf(stderr, ANSI_COLOR_RED "Error: Failed to change into newly created Amiga directory '%s'.\n" ANSI_COLOR_RESET, amiga_item_basename);
                     all_items_success = false;
                }
            }
        } else if (S_ISREG(item_stat.st_mode)) {
            // Add file to the root of the ADF (vol->curDirPtr is root here)
            if (!add_host_file_to_adf(volume, host_item_path, amiga_item_basename)) {
                all_items_success = false;
            }
        } else {
            fprintf(stderr, ANSI_COLOR_YELLOW "Warning: " ANSI_COLOR_RESET "Skipping unsupported file type: '%s'\n", host_item_path);
        }
        free(amiga_item_basename); 
    }

    debug_printf(2, "Unmounting volume '%s'...\n", current_vol_name_display);
    if (volume) adfVolUnMount(volume);
    debug_printf(2, "Unmounting device '%s'...\n", output_filename);
    if (device) adfDevUnMount(device); 
    debug_printf(2, "Closing device '%s'...\n", output_filename);
    if (device) adfDevClose(device);

    debug_printf(2, "Cleaning up ADFlib environment...\n");
    if (adflib_initialized) adfLibCleanUp();

    if (all_items_success) {
        printf(ANSI_COLOR_GREEN "ADF file '%s' processed successfully with disk name '%s'.\n" ANSI_COLOR_RESET, output_filename, volume_name_arg);
        printf(ANSI_COLOR_GREEN "Processed %d input item(s).\n" ANSI_COLOR_RESET, argc - optind);
    } else {
        fprintf(stderr, ANSI_COLOR_RED "ADF creation completed with errors processing some items.\n" ANSI_COLOR_RESET);
        return EXIT_FAILURE; 
    }

    return EXIT_SUCCESS;
}
