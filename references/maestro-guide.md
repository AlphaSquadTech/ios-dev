# Maestro Command Reference

## Flow File Format

Every Maestro flow file is YAML with an optional app header:

```yaml
appId: com.example.MyApp
---
- launchApp
- assertVisible: "Welcome"
- tapOn: "Login"
```

## Core Commands

### Launching & Stopping

```yaml
- launchApp                              # Launch the app specified in appId
- launchApp:
    appId: "com.other.App"               # Launch a different app
    clearState: true                     # Clear app data before launch
- stopApp                                # Stop the current app
- clearState                             # Clear app data without stopping
```

### Tapping

```yaml
- tapOn: "Button Text"                   # Tap element with this text
- tapOn:
    id: "myAccessibilityId"              # Tap by accessibility identifier
- tapOn:
    text: "Submit"
    index: 0                             # Tap first match if multiple
- doubleTapOn: "Element"                 # Double tap
- longPressOn: "Element"                 # Long press
- tapOn:
    point: "50%,50%"                     # Tap at screen coordinates
```

### Text Input

```yaml
- tapOn: "Search field"                  # First tap to focus the field
- inputText: "Hello World"              # Type text into focused field
- eraseText: 5                          # Erase 5 characters
- inputText: "New text"                 # Type replacement
- hideKeyboard                          # Dismiss the keyboard
```

### Assertions

```yaml
- assertVisible: "Welcome"              # Assert text is visible
- assertVisible:
    id: "loginButton"                   # Assert element by ID is visible
- assertNotVisible: "Error"             # Assert text is NOT visible
- assertVisible:
    text: "Count: .*"
    enabled: true                       # Assert element is enabled
```

### Navigation

```yaml
- scroll                                # Scroll down
- scroll:
    direction: UP                       # Scroll up
- scrollUntilVisible:
    element: "Footer Text"
    direction: DOWN
    timeout: 10000                      # Scroll until visible (ms timeout)
- swipe:
    direction: LEFT
    duration: 500                       # Swipe duration in ms
- back                                  # Navigate back (Android back / iOS swipe)
- pressKey: Home                        # Press hardware button
```

### Waiting

```yaml
- waitForAnimationToEnd                 # Wait for animations to settle
- extendedWaitUntil:
    visible: "Dashboard"
    timeout: 15000                      # Wait up to 15s for element
```

### Screenshots

```yaml
- takeScreenshot: path/to/file          # Save screenshot (Maestro appends .png)
```

### Conditional Logic

```yaml
- runFlow:
    when:
      visible: "Cookie Banner"
    file: dismiss_cookies.yaml          # Run sub-flow conditionally
- assertTrue:
    condition: "${output.text == 'Success'}"
```

### Repeat & Loops

```yaml
- repeat:
    times: 3
    commands:
      - tapOn: "Next"
      - assertVisible: "Page.*"
```

## Selector Priority

When finding elements, Maestro checks in this order:
1. **Accessibility ID** (`id:`) — most reliable, use when available
2. **Text content** (`text:` or plain string) — matches visible text
3. **Point** (`point:`) — screen coordinates as last resort

## Tips for iOS

- SwiftUI: Add `.accessibilityIdentifier("myId")` to views for reliable selection
- UIKit: Set `accessibilityIdentifier` property
- Use `waitForAnimationToEnd` after navigation transitions
- Maestro auto-waits up to 5 seconds for elements to appear
- Use `index: N` when multiple elements match the same text
