#!/bin/bash
# Start or stop video recording on the iOS Simulator.
# Usage:
#   record.sh start [filename]   - Start recording
#   record.sh stop               - Stop recording
#   record.sh status             - Check recording status
# Videos are saved to .claude-ios/videos/ in the project root.

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

VIDEOS_DIR="$PROJECT_ROOT/.claude-ios/videos"
PID_FILE="$VIDEOS_DIR/.record_pid"
PATH_FILE="$VIDEOS_DIR/.record_path"
mkdir -p "$VIDEOS_DIR"

ACTION="${1:-help}"

case "$ACTION" in
    start)
        # Check if already recording
        if [ -f "$PID_FILE" ]; then
            OLD_PID=$(cat "$PID_FILE")
            if kill -0 "$OLD_PID" 2>/dev/null; then
                echo "ERROR: Already recording (PID $OLD_PID). Stop first with: record.sh stop" >&2
                exit 1
            else
                rm -f "$PID_FILE" "$PATH_FILE"
            fi
        fi

        # Check if simulator is booted
        if ! xcrun simctl list devices booted 2>/dev/null | grep -q "Booted"; then
            echo "ERROR: No simulator is currently booted." >&2
            exit 1
        fi

        FILENAME="${2:-recording_$(date +%Y%m%d_%H%M%S)}"
        FILENAME="${FILENAME%.mp4}"
        OUTPUT_PATH="$VIDEOS_DIR/${FILENAME}.mp4"

        # Remove existing file if present (simctl won't overwrite)
        rm -f "$OUTPUT_PATH"

        # Start recording in background
        xcrun simctl io booted recordVideo --codec h264 "$OUTPUT_PATH" &
        RECORD_PID=$!

        echo "$RECORD_PID" > "$PID_FILE"
        echo "$OUTPUT_PATH" > "$PATH_FILE"

        # Verify the process started
        sleep 1
        if kill -0 "$RECORD_PID" 2>/dev/null; then
            echo "Recording started (PID $RECORD_PID)"
            echo "Output: $OUTPUT_PATH"
        else
            echo "ERROR: Recording process failed to start." >&2
            rm -f "$PID_FILE" "$PATH_FILE"
            exit 1
        fi
        ;;

    stop)
        if [ ! -f "$PID_FILE" ]; then
            echo "ERROR: No active recording found." >&2
            exit 1
        fi

        RECORD_PID=$(cat "$PID_FILE")
        OUTPUT_PATH=$(cat "$PATH_FILE" 2>/dev/null || echo "unknown")

        # Send SIGINT to gracefully stop recording
        if kill -0 "$RECORD_PID" 2>/dev/null; then
            kill -INT "$RECORD_PID"
            for i in $(seq 1 10); do
                if ! kill -0 "$RECORD_PID" 2>/dev/null; then
                    break
                fi
                sleep 1
            done
        fi

        rm -f "$PID_FILE" "$PATH_FILE"

        if [ -f "$OUTPUT_PATH" ]; then
            SIZE=$(ls -lh "$OUTPUT_PATH" | awk '{print $5}')
            echo "Recording saved: $OUTPUT_PATH ($SIZE)"
        else
            echo "WARNING: Recording file not found at $OUTPUT_PATH" >&2
        fi
        ;;

    status)
        if [ -f "$PID_FILE" ]; then
            RECORD_PID=$(cat "$PID_FILE")
            if kill -0 "$RECORD_PID" 2>/dev/null; then
                echo "Recording in progress (PID $RECORD_PID)"
                echo "Output: $(cat "$PATH_FILE" 2>/dev/null)"
            else
                echo "No active recording (stale PID file, cleaning up)"
                rm -f "$PID_FILE" "$PATH_FILE"
            fi
        else
            echo "No active recording"
        fi
        ;;

    *)
        echo "Usage: record.sh {start [filename] | stop | status}" >&2
        exit 1
        ;;
esac
