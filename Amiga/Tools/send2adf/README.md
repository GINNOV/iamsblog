# send2adf - Amiga Disk File (ADF) Creation Tool

`send2adf` is a **command-line** utility for creating Amiga Disk File (.adf) images. It allows you to add multiple files and **directories** from your host system into a new ADF image, preserving directory structures. This tool leverages the [ADFlib](https://github.com/lclevy/ADFlib) library for ADF manipulation. It's for macOS Apple Silicon but it's C so if you know what you have to do, it can work everywhere.

## Features

* Create new 880KB OFS (Original File System) ADF images.
* Specify a custom volume name for the ADF.
* Add multiple individual files to the ADF.
* Add entire directories recursively, maintaining their structure within the ADF.
* Verbose output modes for debugging:
    * `-v`: Standard info output.
    * `-vv`: Verbose debug output, showing every major stage of the disk packaging.

## Dependencies

* **ADFlib**: Without their work I would still cheasiling bits and bytes together. So thank you for  making the [ADFlib](https://github.com/lclevy/ADFlib) folks.
* The provided Makefile can help clone and build ADFlib if it's not already present in a local `./adflib` directory.
* A C compiler (e.g., GCC or Clang, Xcode will do it).
* Standard POSIX build tools (`make`, `autoreconf` for ADFlib).

## Building

I have provided the compiled version if you don't want to deal with the building of the code but if you do, all you have to do is to launch make and the makefile will do the rest. Including buildng the ADFLib if you don't already have it installed in your /usr/local/bin/adf

## Usage


send2adf -o <output.adf> -N  [-v|-vv] <file_or_dir1> [file_or_dir2 ...]


**Options:**

* `-o, --output <filename>`: **Required.** Specify the output ADF filename (e.g., `mydisk.adf`).
* `-N, --volname <name>`: **Required.** Specify the volume name for the ADF (e.g., `MyWorkDisk`).
* `<file_or_dir1> [file_or_dir2 ...]` : One or more host files or directories to add to the ADF. Directories will be added recursively.
* `-v, --verbose`: Enable verbose informational messages. Use `-vv` for extensive debug output.
* `-h, --help`: Display the help message.

**Examples:**

* Create an ADF with a single file:
```bash
    ./send2adf -o myDisk1.adf -N Workbench1 MyBootFile.bin
```

* Create an ADF with multiple files:
```bash
    ./send2adf -o myDisk1.adf -N Workbench1 MyBootFile.bin MyPixelImage.iff
```

* Create an ADF with multiple files and a directory, using very verbose output:
    ```bash
    ./send2adf -o gamedisk.adf -N MyGame -vv game_executable data/level1.dat assets_folder
    ```

* Display help:
    ```bash
    ./send2adf -h
    ```

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

## Notes for Developers

* The directory recursion uses POSIX-standard functions (`dirent.h`, `sys/stat.h`).
* Error handling for ADFlib operations is included, with more detailed messages available in verbose modes.
* The tool is designed to create standard 880KB OFS-formatted ADFs.
* Most important, I don't know what I am doing, so if you find something off share away 😅

## License

The `file2adf` tool is licensed under the **GNU General Public License v3.0 (GPLv3)**. This is in line with its dependency, ADFlib, which is also typically licensed under the GPL. You can find a copy of the GPLv3 license [here](https://www.gnu.org/licenses/gpl-3.0.en.html) or in a `LICENSE` file accompanying this project.

Under the GPL, you are free to use, study, share, and modify the software. This includes commercial use.

**Commercial Support and Custom Licensing:**

While `send2adf` is free to use commercially under the terms of the GPL, if you send me gifts or contribution I will take it 😇

