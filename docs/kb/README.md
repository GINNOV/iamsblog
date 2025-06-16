# Amiga File System Protection Bits

## Overview
The Amiga File System (AFS), used by the Amiga operating system, includes a set of **protection bits** to control file and directory access permissions. These bits define what actions users or programs can perform, offering a simple yet flexible permission system. This README explains the protection bits, their meanings, and how they are used.

## Protection Bits
The Amiga file system uses **8 protection bits** per file or directory, often represented as a string of characters (e.g., `rwhedspa`) or a numeric value. Each bit corresponds to a specific permission or attribute. The bits are divided into two groups: **access permissions** and **special attributes**.

### Access Permissions
These four bits control basic access to the file or directory:
- **r (Read)**: Allows reading the file or listing the directory's contents.
- **w (Write)**: Permits modifying the file or adding/removing files in the directory.
- **e (Execute)**: Allows executing the file (for scripts or programs) or entering the directory.
- **d (Delete)**: Permits deleting the file or directory.

### Special Attributes
These four bits define additional properties:
- **h (Hold)**: Marks the file as "held" in memory (resident), used for system files.
- **s (Script)**: Indicates the file is a script (can be executed by the Amiga shell).
- **p (Pure)**: Marks an executable as re-entrant, meaning it can be shared between processes without reloading.
- **a (Archive)**: Indicates the file has been archived (used by backup tools to track changes).

### Representation
- **String format**: Protection bits are often displayed as a string like `rwhedspa`, where each position shows the presence (`r`, `w`, etc.) or absence (`-`) of a bit. For example, `rw-e----` means the file is readable, writable, and executable, with no special attributes.
- **Numeric format**: Each bit corresponds to a binary value, often shown as an octal number. For example, `rw-e----` might be represented as `0700` in octal.

## Usage
Protection bits are managed using AmigaOS commands, such as:
- **Protect**: Modifies protection bits for a file or directory.
  - Example: `Protect myfile.doc +rw` adds read and write permissions.
  - Example: `Protect myprogram p` sets the pure bit for an executable.
- **List**: Displays protection bits for files in a directory.
  - Example: `List mydir` shows files with their protection bits (e.g., `rwhedspa`).

### Example
```shell
> List example.txt
example.txt  rw-e----
> Protect example.txt +d
> List example.txt
example.txt  rw-ed---
```
In this example, the `Protect` command adds the delete permission to `example.txt`.

## Notes
- **Inheritance**: Directories can influence the protection bits of files created within them, but AmigaOS does not enforce strict inheritance like modern systems.
- **Compatibility**: Protection bits are specific to Amiga file systems (e.g., OFS, FFS). When transferring files to other systems, these attributes may be lost.
- **Security**: The protection bits provide basic access control but lack advanced features like user groups or ACLs found in modern file systems.

## References
- AmigaOS documentation for `Protect` and `List` commands.
- Amiga File System specifications (OFS/FFS).