#!/bin/bash
# Pre-flight check for iOS development environment.
# Checks: Xcode, simctl, sips, Java, Maestro, simulators, project files.
# Auto-installs Maestro if missing.
# Exit codes: 0 = ready, 1 = critical failure.

ERRORS=0
WARNINGS=0

# Resolve project root: walk up from script location until we find .claude/ at the expected level
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# scripts/ is inside the skill folder, which is inside skills/, which is inside .claude/
# So project root is 4 directories up from scripts/
PROJECT_ROOT="$SCRIPT_DIR"
while [ "$PROJECT_ROOT" != "/" ]; do
    if [ -d "$PROJECT_ROOT/.claude" ] && [ "$PROJECT_ROOT/.claude" != "$SCRIPT_DIR" ] && [[ ! "$SCRIPT_DIR" == "$PROJECT_ROOT/.claude"* ]] ; then
        break
    fi
    # Check if parent has .claude that is an ancestor of our script
    PARENT="$(dirname "$PROJECT_ROOT")"
    if [ -d "$PARENT/.claude" ] && [[ "$SCRIPT_DIR" == "$PARENT/.claude"* ]]; then
        PROJECT_ROOT="$PARENT"
        break
    fi
    PROJECT_ROOT="$PARENT"
done

# Fallback: if we couldn't find it, use pwd
if [ "$PROJECT_ROOT" = "/" ]; then
    PROJECT_ROOT="$(pwd)"
fi

echo "=== iOS Dev Pre-flight Check ==="
echo "Project root: $PROJECT_ROOT"
echo ""

# 1. Xcode and xcodebuild
if ! command -v xcodebuild &>/dev/null; then
    echo "FAIL: xcodebuild not found. Install Xcode from the App Store."
    ERRORS=$((ERRORS + 1))
else
    XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -1)
    echo "OK: $XCODE_VERSION"
fi

# 2. Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
    echo "FAIL: Xcode Command Line Tools not installed."
    echo "  Fix: xcode-select --install"
    ERRORS=$((ERRORS + 1))
else
    echo "OK: Xcode CLT at $(xcode-select -p)"
fi

# 3. simctl
if ! xcrun simctl help &>/dev/null; then
    echo "FAIL: xcrun simctl not available."
    ERRORS=$((ERRORS + 1))
else
    echo "OK: xcrun simctl available"
fi

# 4. sips (should always be on macOS)
if ! command -v sips &>/dev/null; then
    echo "FAIL: sips not found (should be built into macOS)."
    ERRORS=$((ERRORS + 1))
else
    echo "OK: sips available"
fi

# 5. Available simulators
BOOTED=$(xcrun simctl list devices booted 2>/dev/null | grep -c "Booted" || true)
AVAILABLE=$(xcrun simctl list devices available 2>/dev/null | grep -c "iPhone" || true)
echo "OK: $AVAILABLE iPhone simulators available, $BOOTED currently booted"

# 6. Java (required for Maestro)
if ! command -v java &>/dev/null; then
    echo "WARN: Java not found. Required for Maestro."
    echo "  Fix: brew install openjdk@17"
    WARNINGS=$((WARNINGS + 1))
else
    JAVA_VERSION=$(java -version 2>&1 | head -1)
    echo "OK: Java $JAVA_VERSION"
fi

# 7. Maestro (auto-install if missing)
export PATH="$HOME/.maestro/bin:$PATH"
if ! command -v maestro &>/dev/null; then
    echo "INFO: Maestro not found. Attempting auto-install..."
    if curl -Ls "https://get.maestro.mobile.dev" | bash 2>&1; then
        export PATH="$HOME/.maestro/bin:$PATH"
        if command -v maestro &>/dev/null; then
            MAESTRO_VER=$(MAESTRO_CLI_NO_ANALYTICS=1 maestro --version 2>/dev/null | tail -1)
            echo "OK: Maestro installed successfully ($MAESTRO_VER)"
        else
            echo "WARN: Maestro installed but not in PATH. Add ~/.maestro/bin to PATH."
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo "WARN: Maestro auto-install failed. Install manually:"
        echo "  curl -Ls 'https://get.maestro.mobile.dev' | bash"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    MAESTRO_VER=$(MAESTRO_CLI_NO_ANALYTICS=1 maestro --version 2>/dev/null | tail -1)
    echo "OK: Maestro $MAESTRO_VER"
fi

# 8. Project detection
XCWORKSPACE=$(find "$PROJECT_ROOT" -maxdepth 3 -name "*.xcworkspace" -not -path "*/DerivedData/*" -not -path "*/.build/*" -not -path "*/Pods/*" 2>/dev/null | head -1)
XCODEPROJ=$(find "$PROJECT_ROOT" -maxdepth 3 -name "*.xcodeproj" -not -path "*/DerivedData/*" -not -path "*/Pods/*" 2>/dev/null | head -1)

if [ -n "$XCWORKSPACE" ]; then
    echo "OK: Found workspace: $XCWORKSPACE"
elif [ -n "$XCODEPROJ" ]; then
    echo "OK: Found project: $XCODEPROJ"
else
    echo "INFO: No .xcodeproj or .xcworkspace found. Will need to create one."
fi

# 9. Artifacts directory
mkdir -p "$PROJECT_ROOT/.claude-ios/screenshots" "$PROJECT_ROOT/.claude-ios/videos"
echo "OK: Artifacts directory ready at $PROJECT_ROOT/.claude-ios/"

# Summary
echo ""
echo "=== Summary ==="
echo "Errors: $ERRORS | Warnings: $WARNINGS"
if [ $ERRORS -gt 0 ]; then
    echo "RESULT: BLOCKED - Fix errors above before proceeding."
    exit 1
else
    echo "RESULT: READY"
    exit 0
fi
