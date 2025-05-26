## **The Journey to a Working `send2adf.c`**

Creating a program that interacts with a library like [ADFLib](https://github.com/adflib/ADFlib/tree/v0.10.2/examples), especially when dealing with low-level disk image manipulation is something that I have never done. The successful creation of `send2adf.c` was a testament of patience and learning on the spot. 

The only reason why I started this journey was because I wanted a quick way to test amiga code via vAmiga. I know that amitools offers **xdftool** but I wanted to have more control and possibly expanding it over time.

Naturally I did a search to see if anyone had already done something and I found this [repo](https://github.com/troydm/file2adf) but it didn't work. It compiled but wasn't mounting the disk and failing with an error that I couldn't trace.

## How it Works (Internally)

1.  **Initialization**:
    * Parses command-line arguments.
    * Initializes the ADFlib environment.
    * Adds the "dump" device driver (used by ADFlib to treat a host file as a block device).
2.  **ADF Creation**:
    * Creates a new device representation for the output ADF file (`adfDevCreate`).
    * Formats this device as an Amiga floppy disk with the specified volume name and OFS filesystem (`adfCreateFlop`).
3.  **Mounting**:
    * Mounts the newly created device (`adfDevMount`).
    * Mounts the primary volume (partition 0) from the device to make it active (`adfVolMount`).
4.  **Adding Files/Directories**:
    * For each host file/directory provided:
        * Resets the ADF's current directory to the root (`adfToRootDir`).
        * **If it's a file**: Adds it directly to the current ADF directory (root) using `adfFileOpen` and `adfFileWrite`.
        * **If it's a directory**:
            * Creates the top-level directory in the current ADF directory (root) using `adfCreateDir`.
            * Changes the ADF's current directory into this new directory (`adfChangeDir`).
            * Recursively processes the host directory's contents:
                * Subdirectories are created using `adfCreateDir` in the current ADF directory.
                * The ADF current directory is changed into new subdirectories (`adfChangeDir`) before further recursion and changed back to the parent (`adfParentDir`) afterwards.
                * Files are added using `adfFileOpen` and `adfFileWrite` in the current ADF directory.
5.  **Cleanup**:
    * Unmounts the volume and device.
    * Closes the device.
    * Cleans up the ADFlib environment.


## The details of how I got it to work
This will be likely boring material to the most but just in case you are me in the future, struggling to find something that no AI had figure out, here's a summary of the issues we (my kitty helped...) encountered and how they were addressed:

### **1\. Initial Compilation Hurdles**

* **Missing Header Declarations**: Early on, many errors were due to the C compiler not finding the declarations for ADFLib functions (e.g., `adfInit`, `adfCreateDumpDevice`, `FS_OFS`). This was resolved by:  
  * Ensuring the Makefile's include paths (`-I/usr/local/adflib/include/adf`) were correct.  
  * Systematically adding the necessary individual ADFLib header files (e.g., `adflib.h`, `adf_env.h`, `adf_dev.h`, `adf_vol.h`, `adf_file.h`, `adf_blk.h`, `adf_types.h`, `adf_err.h`, `adf_dev_driver_dump.h`, `adf_dev_drivers.h`, `adf_dev_flop.h`) to `send2adf.c`. This ensured all function prototypes, structure definitions, and constants were visible to the compiler.  
* **Incorrect Function Arguments/Types**: We also adjusted arguments for functions like `adfFileWrite` (ensuring correct parameter order and types) and used the correct structure types (e.g., `struct AdfFile`). The filesystem type constant for OFS was identified as `ADF_DOSFS_OFS` (defined in `adf_blk.h`). The file opening mode was corrected to use the `AdfFileMode` enum (e.g., `ADF_FILE_MODE_WRITE`).

### **2\. Runtime: Device Creation Failures (`adfDevCreate`)**

After the code compiled, we faced runtime errors where `adfDevCreate("dump", ...)`—the function to create a file-backed ADF device—was failing:

* **Permissions and Paths**: Initial thoughts went to OS-level file permission issues or problems with relative versus absolute paths for the output ADF file. Your diligent testing confirmed that you had write permissions and that using absolute paths did not resolve the core problem, pointing to an issue within the library's interaction with the filesystem.  
* **Architecture Mismatch (A Key Insight\!)**: You astutely suggested that the ADFLib might not have been compiled correctly for Apple Silicon (ARM64). An x86\_64 library running under Rosetta 2 can indeed lead to subtle failures in low-level operations. Recompiling ADFLib natively for ARM64 was a crucial step forward.  
* **Driver Registration (`adfAddDeviceDriver`)**: Even with a natively compiled ARM64 library, `adfDevCreate("dump", ...)` sometimes failed. We discovered through experimentation that explicitly registering the "dump" device driver using `adfAddDeviceDriver(&adfDeviceDriverDump)` after library initialization (`adfLibInit()`) was necessary for `adfDevCreate` to succeed reliably in your environment. This suggested that the default library initialization might not always register all built-in drivers effectively across all library versions or platforms, or that explicit registration provides greater certainty.

### **3\. Runtime: Volume Formatting and Mounting – The Core Challenge**

This was the most complex part. Once the device (ADF file) was created, making the volume on it correctly formatted and ready for file operations proved tricky:

* **Choosing the Right Formatting Function**: We initially experimented with `adfVolCreate`, which is a lower-level function. However, for creating a standard, formatted floppy disk image, `adfCreateFlop(device, volName, fsType)` emerged as the more appropriate higher-level function. It's designed to handle the intricacies of writing the bootblock, root block, and bitmap for the specified filesystem.  
* **The "Volume Not Mounted" Error and Checksum Issues**: This was a persistent and misleading set of errors.  
  1. Even after `adfCreateFlop` reported success, subsequent calls to `adfFileOpen` (which internally calls `adfVolReadBlock`) would often fail, either stating the "volume not mounted" or, if we bypassed that check, with an "invalid checksum" error (specifically for block 0, the bootblock).  
  2. The "volume not mounted" error indicated that the `AdfVolume` structure (obtained from `device->volList[0]` after `adfCreateFlop` or via `adfVolMount`) didn't have its internal `mounted` flag set to true, or that other internal states were inconsistent.  
  3. The "invalid checksum" error was a more fundamental problem, indicating that `adfCreateFlop` was not correctly writing the initial disk structures with valid checksums in your specific ADFLib build/environment.  
* **The Correct Mounting Sequence (The Breakthrough)**: The ADFLib examples (`unadf.c`, `adfformat.c`, `adfinfo.c`) provided the crucial clues. For a newly created and formatted device, the correct sequence to make a volume usable for file I/O is:  
  1. `adfCreateFlop(device, ...)`: This formats the device, creating the basic volume structure. It populates `device->volList[0]` (for a single-volume floppy).  
  2. `adfDevMount(device)`: This function is essential. It "activates" the device, scanning for its partitions/volumes (including the one just created by `adfCreateFlop`). It reads critical information like the root block and bitmap for each volume and makes them fully known and accessible to ADFLib.  
  3. `volume = adfVolMount(device, 0, ADF_ACCESS_MODE_READWRITE)`: After the device is mounted, this call specifically mounts partition number 0 (our entire floppy volume) in the desired access mode. It returns a pointer to the `AdfVolume` structure that is now fully recognized by ADFLib as "mounted" (i.e., `volume->mounted` should be true) and ready for I/O. This specific call, with the correct arguments, was the final piece of the puzzle for mounting.

### **How the Working Code Operates:**

The final, successful version of `send2adf.c` follows this robust sequence:

1. **Initialization**:  
   * `adfLibInit()`: Initializes the core ADFLib library.  
   * `adfAddDeviceDriver(&adfDeviceDriverDump)`: Explicitly registers the "dump" driver. This was found to be necessary for `adfDevCreate` to reliably find and use the "dump" driver in your environment.  
2. **Device Creation**:  
   * `struct AdfDevice *device = adfDevCreate("dump", output_adf_filename, 80, 2, 11);`: Creates the raw ADF file on disk, telling ADFLib to treat this file as a block device with standard Amiga double-density floppy geometry.  
3. **Volume Formatting**:  
   * `adfCreateFlop(device, disk_name, ADF_DOSFS_OFS);`: Formats the raw device as an Amiga floppy disk with the specified volume label (`disk_name`) and filesystem type (`ADF_DOSFS_OFS`). This writes the bootblock, an empty root block, and initializes the block allocation bitmap. `device->volList[0]` now points to an `AdfVolume` structure for this new volume.  
4. **Device and Volume Mounting (Crucial for Read/Write Readiness)**:  
   * `adfDevMount(device)`: "Activates" the device, making ADFLib aware of the volume(s) on it (in this case, the one just created by `adfCreateFlop`). This step reads essential metadata from the disk image.  
   * `struct AdfVolume *volume = adfVolMount(device, 0, ADF_ACCESS_MODE_READWRITE);`: Specifically mounts partition 0 (the entire floppy) of the device in read/write mode. This returns the `AdfVolume` pointer that is now fully prepared for file operations. The internal `volume->mounted` flag should now be true.  
5. **File Operations**:  
   * `fopen(input_file_path, "rb")`: Opens the host system file for reading.  
   * `adfFileOpen(volume, amiga_filename, ADF_FILE_MODE_WRITE)`: Opens (creates) a new file on the *mounted* Amiga `volume`.  
   * A loop uses `fread` to read from the host file and `adfFileWrite` to write to the Amiga file on the ADF.  
   * `adfFileClose(amiga_file_ptr)` and `fclose(host_file_ptr)`: Close the files.  
6. **Cleanup**:  
   * `adfVolUnMount(volume)`: Unmounts the Amiga volume.  
   * `adfDevUnMount(device)`: Unmounts the device.  
   * `adfDevClose(device)`: Closes the ADF file device.  
   * `adfLibCleanUp()`: Releases resources used by ADFLib.

This detailed sequence ensures that each layer of ADFLib (library, device, volume) is correctly initialized, created, formatted, and mounted before file operations are attempted. The success with your recompiled "devel" branch of ADFLib, combined with this precise sequence of API calls, finally allowed the program to function as intended.

that's it. (well... it was a lot of pain :-)

