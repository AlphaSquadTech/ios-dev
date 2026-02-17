# iOS Development Troubleshooting

## Build Errors

### "No profiles found" / Code Signing Issues
For simulator builds, code signing is not required. Add to your xcodebuild command:
```
CODE_SIGNING_ALLOWED=NO
```
Or: `CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO`

### "No scheme found"
Discover available schemes:
```bash
xcodebuild -list -project MyApp.xcodeproj
xcodebuild -list -workspace MyApp.xcworkspace
```

### "Module not found" / Missing Dependencies
```bash
# CocoaPods
pod install
# Then build with -workspace, not -project

# Swift Package Manager
xcodebuild -resolvePackageDependencies
```

### Build Succeeds But No .app Found
Check the build products directory:
```bash
xcodebuild -showBuildSettings | grep BUILT_PRODUCTS_DIR
# Or search DerivedData:
find ~/Library/Developer/Xcode/DerivedData -name "*.app" -path "*Debug-iphonesimulator*" | head -5
```

### Clean Build
```bash
xcodebuild clean -scheme MyScheme -project MyApp.xcodeproj
# Nuclear option — delete all derived data:
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## Simulator Errors

### "Unable to boot device" / "Operation timed out"
```bash
# Shutdown all simulators first
xcrun simctl shutdown all
# Wait a moment, then boot
sleep 2
xcrun simctl boot <UDID>
```

### "No simulator is currently booted"
```bash
# List available devices
xcrun simctl list devices available | grep iPhone
# Boot one
xcrun simctl boot <UDID>
# Open Simulator app
open -a Simulator
```

### Wrong Simulator Architecture
Ensure you build for the simulator SDK:
```bash
xcodebuild -sdk iphonesimulator -destination 'platform=iOS Simulator,id=<UDID>'
```

### "Failed to install app"
- Check the build was for iphonesimulator (not iphoneos)
- Verify the simulator is fully booted (wait a few seconds after boot)
- Try uninstalling first: `xcrun simctl uninstall booted <bundle_id>`

## Maestro Errors

### "Element not found" / Assertion Failures
1. Take a screenshot to see the actual UI state
2. Check for exact text match (Maestro is case-sensitive)
3. Add `waitForAnimationToEnd` before assertions after screen transitions
4. Use accessibility identifiers instead of text for reliability

### Maestro Not Found After Install
```bash
# Add to PATH
export PATH="$HOME/.maestro/bin:$PATH"
# Verify
maestro --version
```

### Java Not Found (Required by Maestro)
```bash
brew install openjdk@17
# Or if brew is not available:
# Download from https://adoptium.net/
```

### Maestro Timeout on Actions
Increase timeout in the flow:
```yaml
- extendedWaitUntil:
    visible: "Expected Text"
    timeout: 30000
```

## Screenshot Errors

### "Multiply coordinates by X.XX" Warning
The screenshot was not resized before viewing. Always use the screenshot script:
```bash
bash .claude/skills/ios-dev/scripts/screenshot.sh my_screenshot
```
Or manually resize:
```bash
sips --resampleHeightWidthMax 1568 screenshot.png
```

### Screenshot Shows Wrong Screen
- The app may not have finished loading. Add `sleep 2` before taking the screenshot.
- Another app may be in the foreground. Relaunch your app:
  ```bash
  xcrun simctl launch booted <bundle_id>
  ```

## App Runtime Errors

### App Crashes on Launch
Check crash logs:
```bash
xcrun simctl spawn booted log show --last 2m --predicate 'process == "MyApp"' --style compact
```

### Debug Console Output
Stream logs in real-time:
```bash
xcrun simctl spawn booted log stream --predicate 'process == "MyApp"' --level debug
```
