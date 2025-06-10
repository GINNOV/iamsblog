#!/bin/bash

# Exit on error
set -e

# Project settings
PROJECT_NAME="ADFinder"
PROJECT_PATH="../${PROJECT_NAME}.xcodeproj"
SCHEME="${PROJECT_NAME}"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="./build"
APP_PATH="${EXPORT_PATH}/${PROJECT_NAME}.app"
DMG_BASE_PATH="../releases/${PROJECT_NAME}.dmg"
README_PATH="dmg_assets/README.md"
BACKGROUND_IMAGE="dmg_assets/dmg-background.png"
VOLUME_ICON="dmg_assets/dmg-icon.icns"
EXPORT_OPTIONS_PLIST="../exportOptions.plist"
MIN_SPACE_MB=1024

# Usage function
usage() {
    echo "Usage: $0 [--project <project_path>] [--scheme <scheme>] [--configuration <configuration>]"
    echo "Example: $0 --project ../${PROJECT_NAME}.xcodeproj --scheme ${PROJECT_NAME} --configuration Release"
    exit 1
}

# Parse parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --project) PROJECT_PATH="$2"; shift ;;
        --scheme) SCHEME="$2"; shift ;;
        --configuration) CONFIGURATION="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

# Get absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
README_PATH="${SCRIPT_DIR}/${README_PATH}"
BACKGROUND_IMAGE="${SCRIPT_DIR}/${BACKGROUND_IMAGE}"
VOLUME_ICON="${SCRIPT_DIR}/${VOLUME_ICON}"
EXPORT_OPTIONS_PLIST="${SCRIPT_DIR}/${EXPORT_OPTIONS_PLIST}"
DMG_DIR="${SCRIPT_DIR}/../releases"
DMG_BASE_PATH="${DMG_DIR}/${PROJECT_NAME}.dmg"
PROJECT_PATH="${SCRIPT_DIR}/${PROJECT_PATH}"

# Validate inputs
for file in "$PROJECT_PATH" "$README_PATH" "$BACKGROUND_IMAGE" "$VOLUME_ICON" "$EXPORT_OPTIONS_PLIST" "./gendmg.sh"; do
    if [ ! -e "$file" ]; then
        echo "Error: File not found at $file"
        exit 1
    fi
done

# Ensure releases directory exists
mkdir -p "$DMG_DIR" || { echo "Error: Failed to create $DMG_DIR"; exit 1; }

# Check disk space
AVAILABLE_SPACE=$(df -P "$DMG_DIR" | tail -1 | awk '{print $4}' | awk '{print $1 / 1024}')
if (( $(echo "$AVAILABLE_SPACE < $MIN_SPACE_MB" | bc -l) )); then
    echo "Error: Insufficient disk space. Need $MIN_SPACE_MB MB, got ${AVAILABLE_SPACE} MB."
    exit 1
fi

# Clean build directory
echo "Cleaning build directory..."
rm -rf "$EXPORT_PATH"
mkdir -p "$EXPORT_PATH"

# Build and archive
echo "Archiving $SCHEME..."
xcodebuild archive \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    -skipPackagePluginValidation \
    -skipMacroValidation \
    || { echo "Error: Archive failed"; exit 1; }

# Export the app
echo "Exporting app to $EXPORT_PATH..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
    -skipPackagePluginValidation \
    -skipMacroValidation \
    || { echo "Error: Export failed"; exit 1; }

# Verify app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: Exported app not found at $APP_PATH"
    exit 1
fi

# Create DMG
echo "Creating DMG with gendmg.sh..."
bash ./gendmg.sh \
    --readme "$README_PATH" \
    --app "$APP_PATH" \
    --dmg "$DMG_BASE_PATH" \
    --background "$BACKGROUND_IMAGE" \
    --volicon "$VOLUME_ICON" \
    || { echo "Error: DMG creation failed"; exit 1; }

echo "Build and packaging complete."