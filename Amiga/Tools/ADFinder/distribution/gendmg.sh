#!/bin/bash

# Exit on error
set -e

# Default parameters
APP_PATH="$HOME/Downloads/ADFinder.app"
DMG_PATH="$HOME/Downloads/ADFinder.dmg" # Will be modified with version and build
README_PATH=""
BACKGROUND_IMAGE="./dmg_assets/dmg-background.png"
VOLUME_ICON="./dmg_assets/dmg-icon.icns"
VOLUME_NAME="App Installer"
WINDOW_POS_X=200
WINDOW_POS_Y=120
WINDOW_WIDTH=1200
WINDOW_HEIGHT=600
ICON_SIZE=100
APP_POS_X=200
APP_POS_Y=190
README_POS_X=400
README_POS_Y=190
APP_LINK_POS_X=600
APP_LINK_POS_Y=185
MIN_SPACE_MB=1024

# Usage function
usage() {
    echo "Usage: $0 --readme <readme_path> [--app <app_path>] [--dmg <dmg_path>] [--background <background_path>] [--volicon <volicon_path>]"
    echo "Required:"
    echo "  --readme <readme_path>   Path to the README file to include in the DMG"
    echo "Optional:"
    echo "  --app <app_path>         Path to the app (default: $APP_PATH)"
    echo "  --dmg <dmg_path>         Path to the output DMG (default: $DMG_PATH)"
    echo "  --background <path>      Path to the background image (default: $BACKGROUND_IMAGE)"
    echo "  --volicon <path>         Path to the volume icon (default: $VOLUME_ICON)"
    echo "Example:"
    echo "  ./gendmg.sh --readme dmg_assets/README.md --app ~/Downloads/ADFinder/ADFinder.app --dmg ../../releases/ADFinder.dmg --background dmg_assets/dmg-background.png --volicon dmg_assets/dmg-icon.icns" # Your example
    exit 1
}

# Parse parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --app) APP_PATH="$2"; shift ;;
        --dmg) DMG_PATH="$2"; shift ;;
        --readme) README_PATH="$2"; shift ;;
        --background) BACKGROUND_IMAGE="$2"; shift ;;
        --volicon) VOLUME_ICON="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

# Validate required parameters
if [ -z "$README_PATH" ]; then
    echo "Error: --readme parameter is required"
    usage
fi

# Derive app name dynamically
APP_NAME=$(basename "$APP_PATH")
VOLUME_NAME="${APP_NAME%.app} Installer"

# Extract app version and build number from Info.plist
INFO_PLIST="$APP_PATH/Contents/Info.plist"
if [ ! -f "$INFO_PLIST" ]; then
    echo "Error: Info.plist not found at $INFO_PLIST"
    exit 1
fi

# Get CFBundleShortVersionString (version) and CFBundleVersion (build number)
APP_VERSION=$(defaults read "$INFO_PLIST" CFBundleShortVersionString 2>/dev/null)
if [ -z "$APP_VERSION" ]; then
    echo "Error: Could not retrieve CFBundleShortVersionString from $INFO_PLIST"
    exit 1
fi
BUILD_NUMBER=$(defaults read "$INFO_PLIST" CFBundleVersion 2>/dev/null)
if [ -z "$BUILD_NUMBER" ]; then
    echo "Error: Could not retrieve CFBundleVersion from $INFO_PLIST"
    exit 1
fi

# Modify DMG_PATH to include version and build number (e.g., ADFinder-1.0_387.dmg)
DMG_DIR=$(dirname "$DMG_PATH")
DMG_BASE=$(basename "$DMG_PATH" .dmg)
DMG_PATH="$DMG_DIR/${DMG_BASE}-${APP_VERSION}_${BUILD_NUMBER}.dmg"

# Debug: Print parameters
echo "APP_NAME: $APP_NAME"
echo "APP_PATH: $APP_PATH"
echo "APP_VERSION: $APP_VERSION"
echo "BUILD_NUMBER: $BUILD_NUMBER"
echo "DMG_PATH: $DMG_PATH"
echo "README_PATH: $README_PATH"
echo "BACKGROUND_IMAGE: $BACKGROUND_IMAGE"
echo "VOLUME_ICON: $VOLUME_ICON"
echo "VOLUME_NAME: $VOLUME_NAME"
echo "WINDOW_POS: ($WINDOW_POS_X, $WINDOW_POS_Y)"
echo "WINDOW_SIZE: ($WINDOW_WIDTH, $WINDOW_HEIGHT)"
echo "ICON_SIZE: $ICON_SIZE"
echo "APP_POS: ($APP_POS_X, $APP_POS_Y)"
echo "README_POS: ($README_POS_X, $README_POS_Y)"
echo "APP_LINK_POS: ($APP_LINK_POS_X, $APP_LINK_POS_Y)"

# Verify inputs
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
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

# Check if DMG already exists
if [ -f "$DMG_PATH" ]; then
    read -p "DMG file already exists at $DMG_PATH. Overwrite? (y/N) " answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Check disk space
DMG_DIR=$(dirname "$DMG_PATH")
AVAILABLE_SPACE=$(df -P "$DMG_DIR" | tail -1 | awk '{print $4}' | awk '{print $1 / 1024}') # MB
if (( $(echo "$AVAILABLE_SPACE < $MIN_SPACE_MB" | bc -l) )); then
    echo "Error: Insufficient disk space. At least $MIN_SPACE_MB MB is required, but only ${AVAILABLE_SPACE} MB is available."
    exit 1
fi

# Verify create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo "Error: create-dmg not found. Installing via Homebrew..."
    brew install create-dmg || { echo "Failed to install create-dmg"; exit 1; }
fi

# Self-sign the app
echo "Self-signing the app..."
codesign --sign - --force --deep "$APP_PATH" || {
    echo "Warning: Code signing failed. Continuing without signature."
}

# Create temporary source folder
TEMP_DIR=$(mktemp -d)
echo "TEMP_DIR: $TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

# Copy app and README
cp -R "$APP_PATH" "$TEMP_DIR/"
README_FILENAME=$(basename "$README_PATH")
cp "$README_PATH" "$TEMP_DIR/$README_FILENAME"

# Verify source folder contents
ls "$TEMP_DIR/"

# Create DMG
if ! create-dmg \
    --volname "$VOLUME_NAME" \
    --volicon "$VOLUME_ICON" \
    --background "$BACKGROUND_IMAGE" \
    --window-pos "$WINDOW_POS_X" "$WINDOW_POS_Y" \
    --window-size "$WINDOW_WIDTH" "$WINDOW_HEIGHT" \
    --icon-size "$ICON_SIZE" \
    --icon "$APP_NAME" "$APP_POS_X" "$APP_POS_Y" \
    --icon "$README_FILENAME" "$README_POS_X" "$README_POS_Y" \
    --hide-extension "$APP_NAME" \
    --app-drop-link "$APP_LINK_POS_X" "$APP_LINK_POS_Y" \
    --no-internet-enable \
    "$DMG_PATH" \
    "$TEMP_DIR"; then
    echo "Error: Failed to create DMG"
    exit 1
fi

echo "DMG created at: $DMG_PATH"