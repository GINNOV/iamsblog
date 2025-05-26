# Compiling file2adf with ADFlib on macOS (Apple Silicon & Intel)

This guide provides step-by-step instructions to compile the `file2adf` utility, which depends on the `ADFlib` library, on a macOS system. These instructions should work for both Apple Silicon (ARM64) and Intel (x86_64) Macs.

## Prerequisites

Before you begin, ensure you have the following installed:

1.  **Xcode Command Line Tools:**
    These tools include the Clang compiler, `make`, and other essential development utilities. If you haven't installed them yet, open Terminal and run:
    ```bash
    xcode-select --install
    ```

2.  **Homebrew:**
    Homebrew is a package manager for macOS that simplifies the installation of software. If you don't have it, install it by following the instructions on [brew.sh](https://brew.sh/).

3.  **Autoconf, Automake, Libtool, Gettext (via Homebrew):**
    These tools are required to generate the `configure` script for ADFlib. Install them using Homebrew:
    ```bash
    brew install autoconf automake libtool gettext
    ```
    You might also need to ensure `gettext` is in your PATH. Homebrew will usually provide instructions if this is needed (e.g., `echo 'export PATH="/opt/homebrew/opt/gettext/bin:$PATH"' >> ~/.zshrc`).

4.  **Zlib:**
    ADFlib depends on zlib. While macOS comes with a version, installing it via Homebrew ensures you have a compatible version for the build.
    ```bash
    brew install zlib
    ```

## Step 1: Download and Compile ADFlib

1.  **Clone the ADFlib Repository:**
```bash
git clone https://github.com/adflib/ADFlib.git
cd ADFlib
```

2.  **Generate the Configure Script:**
    Run the `autogen.sh` script. This might require you to `chmod +x autogen.sh` first if it's not executable.
    ```bash
    sh autogen.sh
    ```
    If this fails, ensure `autoconf`, `automake`, and `libtool` are correctly installed and in your PATH.

3.  **Create a Build Directory and Configure:**
    It's good practice to build in a separate directory.
    ```bash
    mkdir build
    cd build
    ```
    Now, run the `configure` script. We'll specify the architecture and an installation prefix.
    * For **Apple Silicon (ARM64) Macs**:
        ```bash
        ../configure CFLAGS="-arch arm64 -I/opt/homebrew/include" \
                     CXXFLAGS="-arch arm64 -I/opt/homebrew/include" \
                     LDFLAGS="-arch arm64 -L/opt/homebrew/lib" \
                     --prefix=/usr/local/adflib 
        ```
    * For **Intel (x86_64) Macs**:
        ```bash
        ../configure CFLAGS="-arch x86_64 -I/opt/homebrew/include" \
                     CXXFLAGS="-arch x86_64 -I/opt/homebrew/include" \
                     LDFLAGS="-arch x86_64 -L/opt/homebrew/lib" \
                     --prefix=/usr/local/adflib
        ```
    The `-I/opt/homebrew/include` and `-L/opt/homebrew/lib` flags help `configure` find Homebrew-installed dependencies like `zlib`. `/opt/homebrew/` is the default Homebrew prefix on Apple Silicon; for Intel, it's often `/usr/local/`. Adjust if your Homebrew prefix is different.
    The `--prefix=/usr/local/adflib` means ADFlib will be installed into `/usr/local/adflib`. You can choose a different location, but you'll need to adjust the `Makefile` for `file2adf` accordingly.

4.  **Compile ADFlib:**
    ```bash
    make
    ```
    You can use `make -jN` (where N is the number of CPU cores) to speed up compilation (e.g., `make -j4`).

5.  **Install ADFlib:**
    ```bash
    sudo make install
    ```
    This will copy the compiled library and header files to the directory specified by `--prefix` (e.g., `/usr/local/adflib`).

## Step 2: Compile `file2adf`

1.  **Navigate to your `file2adf` Project Directory:**
    This is the directory containing `file2adf.c` and the `Makefile`.
    ```bash
    cd /path/to/your/file2adf_project 
    ```

2.  **Ensure the `Makefile` is Correct:**
    The `Makefile` for `file2adf` should look like this (or similar to the one provided in the Canvas `makefile_file2adf`):

    ```makefile
    # Makefile for compiling file2adf.c and linking against ADFlib

    ADFLIB_PREFIX=/usr/local/adflib
    CC=cc
    CFLAGS=-O2 -I$(ADFLIB_PREFIX)/include/adf
    LDFLAGS=-L$(ADFLIB_PREFIX)/lib -Wl,-rpath,$(ADFLIB_PREFIX)/lib -ladf
    TARGET=file2adf
    SRC=file2adf.c
    OBJ=$(SRC:.c=.o)

    all: $(TARGET)

    $(TARGET): $(OBJ)
    	@echo "Linking $(TARGET)..."
    	$(CC) -o $(TARGET) $(OBJ) $(LDFLAGS)
    	@echo "$(TARGET) built successfully."

    $(OBJ): $(SRC)
    	@echo "Compiling $(SRC)..."
    	$(CC) $(CFLAGS) -c $(SRC) -o $(OBJ)

    clean:
    	@echo "Cleaning up..."
    	rm -f $(TARGET) $(OBJ)

    .PHONY: all clean
    ```
    Key points in this Makefile:
    * `ADFLIB_PREFIX` should match the `--prefix` used when installing ADFlib.
    * `CFLAGS` includes `-I$(ADFLIB_PREFIX)/include/adf` because ADFlib installs its headers in an `adf` subdirectory.
    * `LDFLAGS` includes `-L$(ADFLIB_PREFIX)/lib` to find the library and `-Wl,-rpath,$(ADFLIB_PREFIX)/lib` to help the executable find the dynamic library at runtime.

3.  **Compile `file2adf`:**
    ```bash
    make
    ```

4.  **Run `file2adf`:**
    If compilation is successful, you can run your program:
    ```bash
    ./file2adf [arguments]
    ```

## Troubleshooting

* **`adflib.h` not found:**
    * Ensure `sudo make install` for ADFlib completed successfully.
    * Verify that `adflib.h` exists in `/usr/local/adflib/include/adf/` (or your chosen prefix + `/include/adf/`).
    * Double-check the `CFLAGS` in your `file2adf` Makefile.
* **Linker errors (library not found, e.g., `-ladf`):**
    * Ensure `sudo make install` for ADFlib completed successfully.
    * Verify that `libadf.dylib` (or `libadf.a`) exists in `/usr/local/adflib/lib/`.
    * Double-check the `LDFLAGS` in your `file2adf` Makefile, especially the `-L` path.
* **`autogen.sh` errors:**
    * Make sure `autoconf`, `automake`, `libtool`, and `gettext` are installed via Homebrew and accessible in your PATH.
* **Permission errors during `sudo make install`:**
    * Ensure you are running the command with `sudo`. If installing to a system directory like `/usr/local/`, root privileges are required.

Good luck!
