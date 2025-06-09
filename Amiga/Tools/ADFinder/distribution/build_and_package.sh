#!/bin/bash

# Exit on error
set -e

# Project settings
PROJECT_NAME="ADFinder"
PROJECT_PATH="${PROJECT_NAME}.xcodeproj" # or .xcworkspace
SCHEME="${PROJECT_NAME}"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="./build"
APP_PATH="${EXPORT_PATH}/${PROJECT_NAME}.app"
DMG_BASE_PATH="./releases/${PROJECT_NAME}.dmg"
README_PATH="README.md"
BACKGROUND_IMAGE="dmg_assets/dmg-background.png"
VOLUME_ICON="dmg_assets/dmg-icon.icns"
EXPORT_OPTIONS_PLIST="exportOptions.plist"
MIN_SPACE_MB=1024 # Match gendmg.sh requirement

# Usage function
usage() {
    echo "Usage: $0 [--project <project_path>] [--scheme <scheme>] [--configuration <configuration>]"
    echo "Optional:"
    echo "  --project <project_path>  Xcode project or workspace (default: $PROJECT_PATH)"
    echo "  --scheme <scheme>         Build scheme (default: $SCHEME)"
    echo "  --configuration <config>  Build configuration (default: $CONFIGURATION)"
    echo "Example:"
    echo "  $0 --project ${PROJECT_NAME}.xcodeproj --scheme ${PROJECT_NAME} --configuration Release"
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

# Validate inputs
if [ ! -e "$PROJECT_PATH" ]; then
    echo "Error: Project not found at $PROJECT_PATH"
    exit 1
fi
if [ ! -f "$README_PATH" ]; then
    echo "Error: README file not found at $README_PATH"
    exit 1
fi
if [ ! -f "$BACKGROUND_IMAGE" ]; then
    echo "Error: Background image not found at $BACKGROUND_IMAGE"
    exit 1
fi
if [ ! -f "$VOLUME_ICON" ]; then
    echo "Error: Volume icon not found at $VOLUME_ICON"
    exit 1
fi
if [ ! -f "./distribution/gendmg.sh" ]; then
    echo "Error: gendmg.sh not found at ./distribution/gendmg.sh"
    exit 1
fi
if [ ! -f "$EXPORT_OPTIONS_PLIST" ]; then
    echo "Error: Export options plist not found at $EXPORT_OPTIONS_PLIST"
    exit 1
fi

# Check disk space
DMG_DIR=$(dirname "$DMG_BASE_PATH")
AVAILABLE_SPACE=$(df -P "$DMG_DIR" | tail -1 | awk '{print $4}' | awk '{print $1 / 1024}') # MB
if (( $(echo "$AVAILABLE_SPACE < $MIN_SPACE_MB" | bc -l) )); then
    echo "Error: Insufficient disk space. At least $MIN_SPACE_MB MB is required, but only ${AVAILABLE_SPACE} MB is available."
    exit 1
fi

# Clean build directory
echo "Cleaning build directory..."
rm -rf "$EXPORT_PATH"
mkdir -p "$EXPORT_PATH" "$DMG_DIR"

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
bash ./distribution/gendmg.sh \
    --readme "$README_PATH" \
    --app "$APP_PATH" \
    --dmg "$DMG_BASE_PATH" \
    --background "$BACKGROUND_IMAGE" \
    --volicon "$VOLUME_ICON" \
    || { echo "Error: DMG creation failed"; exit 1; }

echo "Build and packaging complete."