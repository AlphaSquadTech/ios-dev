# ios-dev

An Agent Skill that gives AI coding agents full autonomous control over iOS app development -- build, run, navigate, screenshot, record, and debug iOS apps on the Simulator without any manual intervention.

## What it does

When this skill is active, your AI agent can autonomously:

- **Build** iOS apps with `xcodebuild` (auto-detects projects/workspaces/schemes)
- **Boot & manage** iOS Simulators (selects the best available device)
- **Install & launch** apps on the Simulator
- **Take screenshots** and view them (auto-resized to fit API limits)
- **Navigate the app** using [Maestro](https://maestro.mobile.dev) UI automation (tap, type, swipe, assert)
- **Record videos** of app interactions
- **Read debug logs** from the Simulator
- **Fix issues and iterate** in a fully autonomous build-run-verify loop

## Install

```bash
npx skills add alphasquadtech/ios-dev
```

Or manually copy the skill into your project:

```bash
# Clone into your project's .claude/skills/ directory
mkdir -p .claude/skills
git clone https://github.com/alphasquadtech/ios-dev.git .claude/skills/ios-dev
```

## Requirements

- **macOS** (required for Xcode and iOS Simulator)
- **Xcode** with Command Line Tools installed
- **Java 17+** (for Maestro): `brew install openjdk@17`
- **Maestro** (auto-installed by the skill if missing)

## Usage

Once installed, use the `/ios-dev` slash command in Claude Code:

```
/ios-dev build     # Build and run the app
/ios-dev test      # Build, run, and navigate through the app
/ios-dev debug     # Check logs and diagnose issues
/ios-dev screenshot # Take a screenshot of the current simulator state
```

Or just describe what you want and the skill activates automatically when iOS development is detected.

## What's included

```
ios-dev/
├── SKILL.md                    # Main skill instructions
├── scripts/
│   ├── preflight.sh            # Dependency checker + Maestro auto-installer
│   ├── screenshot.sh           # Capture + resize to 1568px (API limit)
│   └── record.sh              # Start/stop video recording
└── references/
    ├── maestro-guide.md        # Maestro command reference
    └── troubleshooting.md      # Common iOS dev errors and fixes
```

## How it works

The skill follows an autonomous **Build-Run-Verify** loop:

1. Run pre-flight checks (Xcode, Simulator, Maestro)
2. Auto-detect `.xcodeproj` / `.xcworkspace` and schemes
3. Build for the iOS Simulator with `xcodebuild`
4. Boot a simulator and install the app
5. Take a screenshot and visually analyze it
6. Navigate using Maestro (tap buttons, fill forms, swipe)
7. Screenshot after each action to verify correctness
8. If something is wrong: read logs, fix code, rebuild, re-verify
9. Repeat until the app works correctly

Screenshots are automatically resized to max 1568px (longest side) to comply with Claude's image API constraints.

## Artifacts

All runtime artifacts are stored in `.claude-ios/` in your project root:

```
.claude-ios/
├── build/          # xcodebuild derived data
├── screenshots/    # Captured & resized screenshots
└── videos/         # Recorded simulator videos
```

Add to `.gitignore`:
```
.claude-ios/
```

## License

MIT
