#!/bin/bash
# Take a simulator screenshot, resize for Claude API, save to project artifacts dir.
# Usage: screenshot.sh [filename]
# Output: Prints the absolute path to the saved screenshot and its dimensions.
# Screenshots are always resized to max 1568px on the longest side (Claude API limit).

set -euo pipefail

# Resolve project root by finding the parent that contains .claude/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(pwd)"
DIR="$SCRIPT_DIR"
while [ "$DIR" != "/" ]; do
    PARENT="$(dirname "$DIR")"
    if [ -d "$PARENT/.claude" ] && [[ "$SCRIPT_DIR" == "$PARENT/.claude"* ]]; then
        PROJECT_ROOT="$PARENT"
        break
    fi
    DIR="$PARENT"
done

SCREENSHOTS_DIR="$PROJECT_ROOT/.claude-ios/screenshots"
mkdir -p "$SCREENSHOTS_DIR"

FILENAME="${1:-screenshot_$(date +%Y%m%d_%H%M%S)}"
FILENAME="${FILENAME%.png}"
OUTPUT_PATH="$SCREENSHOTS_DIR/${FILENAME}.png"

# Check if any simulator is booted
if ! xcrun simctl list devices booted 2>/dev/null | grep -q "Booted"; then
    echo "ERROR: No simulator is currently booted." >&2
    echo "Boot one with: xcrun simctl boot <UDID>" >&2
    exit 1
fi

# Take the screenshot
if ! xcrun simctl io booted screenshot "$OUTPUT_PATH" 2>/dev/null; then
    echo "ERROR: Failed to take screenshot." >&2
    exit 1
fi

# Resize for Claude API (max 1568px on longest side)
if ! sips --resampleHeightWidthMax 1568 "$OUTPUT_PATH" >/dev/null 2>&1; then
    echo "WARNING: Failed to resize screenshot. File may be too large for Claude API." >&2
fi

# Report results
WIDTH=$(sips -g pixelWidth "$OUTPUT_PATH" 2>/dev/null | awk '/pixelWidth/{print $2}')
HEIGHT=$(sips -g pixelHeight "$OUTPUT_PATH" 2>/dev/null | awk '/pixelHeight/{print $2}')
SIZE=$(ls -lh "$OUTPUT_PATH" | awk '{print $5}')

echo "$OUTPUT_PATH"
echo "Dimensions: ${WIDTH}x${HEIGHT}px | Size: ${SIZE}"
