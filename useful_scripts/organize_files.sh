#!/bin/zsh

# Script to organize files alphabetically into separate folders
# Usage: ./organize_files.sh [--organize] [--root /path/to/directory] [--parallel N]

# Default settings
PREVIEW=true
SRC_DIR="/Volumes/ME/Amiga/BS1/" # Changed // to /
PARALLEL_JOBS=1 # Default to single-threaded

# Function to display help message
show_help() {
    echo "Usage: $(basename "$0") [--organize] [--root /path/to/directory] [--parallel N]"
    echo ""
    echo "Organizes files in the source directory into subfolders (A-Z, non_alphabetic)."
    echo "By default, the script runs in preview mode and targets '$SRC_DIR'."
    echo ""
    echo "Options:"
    echo "  --organize      Actually organize the files (default is preview mode)."
    echo "  --root DIR      Specify the source directory to organize files in."
    echo "  --parallel N    Use N parallel jobs for organizing (requires GNU Parallel)."
    echo "  --help          Show this help message and exit."
    echo ""
    echo "If no arguments are provided, this help message is displayed."
}

# If no arguments are provided, show help and exit
if [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi

# Check command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --organize)
            PREVIEW=false
            shift
            ;;
        --root)
            if [[ -n "$2" && "$2" != --* ]]; then
                SRC_DIR="$2"
                shift 2
            else
                echo "Error: --root requires a directory path." >&2
                show_help >&2
                exit 1
            fi
            ;;
        --parallel)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                PARALLEL_JOBS="$2"
                if [[ "$PARALLEL_JOBS" -eq 0 ]]; then
                    echo "Error: --parallel requires a number greater than 0." >&2
                    show_help >&2
                    exit 1
                fi
                shift 2
            else
                echo "Error: --parallel requires a positive number." >&2
                show_help >&2
                exit 1
            fi
            ;;
        --help)
            show_help
            exit 0
            ;;
        *) # Catch-all for unknown options or misplaced arguments
            if [[ "$1" == --* ]]; then # It starts with --, so it's likely an attempt at an option
                echo "Error: Unknown option: $1" >&2
            else # It doesn't start with --, so it's a misplaced argument
                echo "Error: Unexpected argument '$1'." >&2
                echo "If '$1' is intended as the target directory, please use the --root option, e.g., '--root \"$1\"'." >&2
            fi
            show_help >&2
            exit 1
            ;;
    esac
done

# Check if the source directory exists
if [[ ! -d "$SRC_DIR" ]]; then
    echo "Error: Source directory '$SRC_DIR' does not exist." >&2
    exit 1
fi

# Check for required tools
if [[ "$PREVIEW" == false ]]; then
    if ! command -v rsync &> /dev/null; then
        echo "Error: rsync is required but not installed." >&2
        exit 1
    fi

    if [[ $PARALLEL_JOBS -gt 1 ]]; then
        if ! command -v parallel &> /dev/null; then
            echo "Error: GNU Parallel is required for parallel processing but not installed." >&2
            echo "Install with: brew install parallel (macOS) or apt-get install parallel (Linux)" >&2
            exit 1
        fi
    fi
fi

# Function to display tree-like structure (currently unused in main logic)
display_tree() {
    local dir=$1
    local prefix=$2
    local files=()
    local dirs=()

    # Get all entries in the directory
    for entry in "$dir"/*; do
        if [[ -d "$entry" ]]; then
            dirs+=("$entry")
        elif [[ -f "$entry" ]]; then
            files+=("$entry")
        fi
    done

    # Display files first
    for file in "${files[@]}"; do
        echo "${prefix}├── $(basename "$file")"
    done

    # Display directories and their contents
    local last_idx=$((${#dirs[@]} - 1))
    local i=0
    for directory in "${dirs[@]}"; do
        local base_dir=$(basename "$directory")
        if [[ $i -eq $last_idx ]]; then
            echo "${prefix}└── $base_dir/"
            display_tree "$directory" "${prefix}    "
        else
            echo "${prefix}├── $base_dir/"
            display_tree "$directory" "${prefix}│   "
        fi
        ((i++))
    done
}

# Function to preview the organization without making changes (robust for spaces in filenames)
preview_organization() {
    echo "Preview of file organization for: $SRC_DIR"
    echo "$(basename "$SRC_DIR")/"

    local -A files_in_folder # Associative array: key=folder_name, value=array_of_filenames

    local letter
    for letter in {A..Z}; do
        files_in_folder[$letter]=()
    done
    files_in_folder[non_alphabetic]=()

    for file_path in "$SRC_DIR"/*; do
        if [[ -f "$file_path" ]]; then
            local filename=$(basename "$file_path")
            local first_char=$(echo "${filename:0:1}" | tr '[:lower:]' '[:upper:]')

            if [[ "$first_char" =~ [A-Z] ]]; then
                files_in_folder[$first_char]+=("$filename")
            else
                files_in_folder[non_alphabetic]+=("$filename")
            fi
        fi
    done

    local display_folder_order=({A..Z} "non_alphabetic")
    local last_folder_to_display=""
    # Determine the last folder that will actually be displayed (has files)
    for (( i=${#display_folder_order[@]}-1; i>=0; i-- )); do
        local folder_key_check="${display_folder_order[i]}"
        local -a check_files_array=("${(@)files_in_folder[$folder_key_check]}")
        if (( ${#check_files_array[@]} > 0 )); then
            last_folder_to_display="$folder_key_check"
            break
        fi
    done


    for folder_key in "${display_folder_order[@]}"; do
        local -a current_files_array=("${(@)files_in_folder[$folder_key]}")

        if (( ${#current_files_array[@]} > 0 )); then
            local branch_char="├──"
            local sub_branch_prefix="│   "
            if [[ "$folder_key" == "$last_folder_to_display" ]]; then
                branch_char="└──"
                sub_branch_prefix="    " # No vertical line for the last item's children
            fi

            local display_name="$folder_key"
            # if [[ "$folder_key" == "non_alphabetic" ]]; then # This check is redundant due to display_name
            #     display_name="non_alphabetic"
            # fi
            echo "${branch_char} $display_name/"

            local last_file_idx=$((${#current_files_array[@]} - 1))
            for (( j=0; j<${#current_files_array[@]}; j++ )); do
                local file_to_display="${current_files_array[j]}"
                local file_branch_char="├──"
                if [[ $j -eq $last_file_idx ]]; then
                    file_branch_char="└──"
                fi
                echo "${sub_branch_prefix}${file_branch_char} $file_to_display"
            done
        fi
    done
}


# Function to perform the actual organization
organize_files() {
    echo "Organizing files in $SRC_DIR..."

    for letter in {A..Z}; do
        mkdir -p "$SRC_DIR/$letter"
    done
    mkdir -p "$SRC_DIR/non_alphabetic"

    local total_files_to_move=0
    local files_to_process=()
    for file in "$SRC_DIR"/*; do
        if [[ -f "$file" ]]; then
            files_to_process+=("$file")
            ((total_files_to_move++))
        fi
    done

    if [[ $total_files_to_move -eq 0 ]]; then
        echo "No files found in the root of '$SRC_DIR' to organize."
        # Optionally remove empty letter/non_alphabetic folders if desired, or leave them.
        # For now, we leave them as they were created.
        echo "Organization complete (no files to move)."
        return
    fi
    
    local current=0
    for file in "${files_to_process[@]}"; do
        ((current++))
        local filename=$(basename "$file")
        local first_char=$(echo "${filename:0:1}" | tr '[:lower:]' '[:upper:]')
        local dest_dir=""

        if [[ "$first_char" =~ [A-Z] ]]; then
            dest_dir="$SRC_DIR/$first_char/"
        else
            dest_dir="$SRC_DIR/non_alphabetic/"
        fi

        echo "[$current/$total_files_to_move] Moving '$filename' to folder '$(basename "$dest_dir")'"
        # Using -v for verbose output from rsync, can be removed if too noisy
        # Using simpler rsync flags as -a is broad for a single file move
        rsync --remove-source-files "$file" "$dest_dir"
        # Or use mv:
        # mv "$file" "$dest_dir"

        if [[ $? -ne 0 ]]; then
            echo "Warning: Failed to move '$filename' to '$(basename "$dest_dir")'" >&2
        fi
    done

    echo "Organization complete!"
}

# Function to perform the actual organization with multiple threads using GNU Parallel
organize_files_parallel() {
    echo "Organizing files in $SRC_DIR using $PARALLEL_JOBS parallel jobs..."

    # Create alphabet folders and non_alphabetic folder
    local letter # Declare loop variable locally
    for letter in {A..Z}; do
        mkdir -p "$SRC_DIR/$letter"
    done
    mkdir -p "$SRC_DIR/non_alphabetic"

    local tmp_file
    tmp_file=$(mktemp) || { echo "Error: Failed to create temp file" >&2; exit 1; } # Ensure mktemp succeeds

    echo "Preparing file list for parallel processing..."
    # Loop through files in the source directory
    for file in "$SRC_DIR"/*; do
        if [[ -f "$file" ]]; then # Process only regular files
            local filename=$(basename "$file") # Get just the filename
            local first_char=$(echo "${filename:0:1}" | tr '[:lower:]' '[:upper:]') # Get capitalized first character
            local dest_dir_path="" # Initialize destination directory path

            # Determine destination directory based on the first character
            if [[ "$first_char" =~ [A-Z] ]]; then
                dest_dir_path="$SRC_DIR/$first_char/"
            else
                dest_dir_path="$SRC_DIR/non_alphabetic/"
            fi

            # Write the source file and destination directory to the temp file
            echo "$file:::$dest_dir_path" >> "$tmp_file"
        fi
    done

    local total_files_parallel=$(wc -l < "$tmp_file" | tr -d ' ') # Get a clean count of files
    echo "Found $total_files_parallel files to organize."

    if [[ $total_files_parallel -eq 0 ]]; then
        echo "No files to organize in the root of '$SRC_DIR'."
        rm "$tmp_file" # Clean up temp file
        # Optionally remove empty letter/non_alphabetic folders if desired here
        echo "Organization complete (no files to move)."
        return
    fi

    echo "Starting parallel move operation..."
    # Use GNU Parallel to process the file list
    # {1} will be the source file path from the temp file
    # {2} will be the destination directory path from the temp file
    <"$tmp_file" parallel --no-notice --progress --eta --jobs "$PARALLEL_JOBS" --colsep ":::" '
        file_to_move={1}    # Full path to the source file
        dest_folder={2}     # Full path to the destination directory

        # Get just the filename for the echo message
        fname=$(basename "$file_to_move")
        # Get just the last component of the destination directory for the echo message
        dest_basename=$(basename "$dest_folder")

        # Echo the operation (now with corrected fname and dest_basename)
        echo "Moving \"$fname\" to \"$dest_basename\""

        # Perform the move using rsync
        # Quotes around "$file_to_move" and "$dest_folder" are important here for the shell
        # to handle spaces or special characters in the paths correctly.
        rsync --remove-source-files "$file_to_move" "$dest_folder" || echo "Warning: Failed to move \"$fname\" to \"$dest_basename\"" >&2
    '

    local parallel_exit_code=$?
    if [[ $parallel_exit_code -ne 0 ]]; then
        echo "Warning: GNU Parallel reported some errors during processing (exit code: $parallel_exit_code)." >&2
    fi

    # Clean up the temporary file
    rm "$tmp_file"
    echo "Organization complete!"
}


# --- Main Execution Logic ---

if [[ "$PREVIEW" == true ]]; then
    preview_organization
else
    if [[ $PARALLEL_JOBS -gt 1 ]]; then
        organize_files_parallel
    else
        organize_files
    fi
fi