#!/bin/bash

# Exit on error
set -e

# Default parameters
APP_PATH="$HOME/Downloads/ADFinder.app"
DMG_PATH="$HOME/Downloads/ADFinder.dmg"
README_PATH=""
BACKGROUND_IMAGE="$HOME/Downloads/distribution/dmg-background.png"
VOLUME_ICON="$HOME/Downloads/distribution/dmg-icon.icns"
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
    echo "  $0 --readme ./distribution/README.md --app ./distribution/ADFinder.app --dmg ./distribution/ADFinder.dmg --background ./distribution/dmg-background.png --volicon ./distribution/dmg-icon.icns"
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

# Set volume name based on app name
VOLUME_NAME="${APP_NAME%.app} Installer"

# Debug: Print parameters
echo "APP_NAME: $APP_NAME"
echo "APP_PATH: $APP_PATH"
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

# Check disk space (require at least 1GB free)
REQUIRED_SPACE=$((1024 * 1024 * 1024)) # 1GB in bytes
AVAILABLE_SPACE=$(df -P "$HOME" | tail -1 | awk '{print $4}' | awk '{print $1 * 1024}') # Available space in bytes
if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    echo "Error: Insufficient disk space. At least 1GB is required, but only $((AVAILABLE_SPACE / 1024 / 1024))MB is available."
    exit 1
fi

# Verify create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo "Error: create-dmg not found. Installing via Homebrew..."
    brew install create-dmg || { echo "Failed to install create-dmg"; exit 1; }
fi

# Self-sign the app
echo "Self-signing the app..."
codesign --sign - --force --deep "$APP_PATH"

# Remove quarantine attribute
echo "Removing quarantine attribute..."
xattr -rc "$APP_PATH"

# Verify signing and quarantine removal
echo "Verifying signing..."
codesign -dv "$APP_PATH"
echo "Verifying quarantine removal..."
xattr "$APP_PATH"

# Create temporary source folder
TEMP_DIR=$(mktemp -d)
echo "TEMP_DIR: $TEMP_DIR"
cp -R "$APP_PATH" "$TEMP_DIR/"

# Copy the README file
README_FILENAME=$(basename "$README_PATH")
cp "$README_PATH" "$TEMP_DIR/$README_FILENAME"

# Verify source folder contents
ls "$TEMP_DIR/"

# Create DMG with create-dmg
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
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Clean up
rm -rf "$TEMP_DIR"

echo "DMG created at: $DMG_PATH"