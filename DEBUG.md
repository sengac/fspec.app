# Debugging fspec-mobile

## Fake Relay Server

### IMPORTANT: Always Use GNU Screen

The relay server MUST be run in a GNU screen session to prevent it from dying when tests run or terminals close.

```bash
# One-time setup: compile the server
cd /Users/rquast/projects/fspec-mobile
/Users/rquast/fvm/versions/stable/bin/dart compile exe tools/fake_relay_server.dart -o /tmp/fake_relay_server

# Start relay in a detached screen session
screen -dmS relay /tmp/fake_relay_server

# Verify it's running
screen -ls                      # Should show "relay" session
lsof -i :8765 -P | grep LISTEN  # Should show fake_relay_server

# View live output (attach to screen)
screen -r relay
# To detach without killing: Ctrl+A, then D

# Check if relay crashed and restart
screen -ls | grep relay || screen -dmS relay /tmp/fake_relay_server

# Kill and restart
screen -X -S relay quit
screen -dmS relay /tmp/fake_relay_server
```

### Quick Health Check

```bash
# Is relay running?
screen -ls | grep relay && lsof -i :8765 -P | grep LISTEN

# Test HTTP endpoint
curl -s http://127.0.0.1:8765
# Should return: "Fake Relay Server - Use WebSocket connection"
```

### Connection Details for App

```
Name: Local Dev Server
Relay URL: http://localhost:8765
Channel ID: dev-channel
API Key: (leave empty)
```

### Known Issue: URL Path Appending

The app appends `/v1/ws` to the relay URL automatically:
- Input: `http://localhost:8765`
- Actual WebSocket URL: `ws://localhost:8765/v1/ws`

The fake server handles any path, so this should work.

---

## Maestro UI Testing

### Installation

```bash
# Install Maestro CLI (requires Java 17+)
brew install openjdk@17
curl -Ls "https://get.maestro.mobile.dev" | bash

# Set environment variables
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH:$HOME/.maestro/bin"
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export MAESTRO_CLI_NO_ANALYTICS=1
export MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED=true
```

### Running Maestro Tests

```bash
cd /Users/rquast/projects/fspec-mobile

# Run a single flow
maestro test tools/maestro/add_and_save_connection.yaml

# Run with output directory for screenshots
maestro test tools/maestro/flow.yaml --output /tmp/maestro_output
```

### Maestro Flow Files Location

All Maestro flows are in `tools/maestro/`:
- `add_and_save_connection.yaml` - Full flow to add a connection
- `connect_to_relay.yaml` - Connect to a relay server
- Other utility flows for testing specific features

### Maestro Flow Syntax Tips

```yaml
# App ID (find in ios/Runner.xcodeproj/project.pbxproj)
appId: com.fspec.fspecMobile

---
# Take screenshots
- takeScreenshot: screenshot_name

# Tap on text
- tapOn: "Button Text"

# Tap on point (percentage)
- tapOn:
    point: "50%,50%"

# Input text (tap field first!)
- tapOn: "placeholder text"
- inputText: "my input"

# Dismiss keyboard
- pressKey: Enter

# Swipe/scroll
- swipe:
    start: "50%,70%"
    end: "50%,30%"

# Wait for animations
- waitForAnimationToEnd

# Assert visibility
- assertVisible: "Some Text"

# Optional assertion (won't fail test)
- assertVisible:
    text: "Some Text"
    optional: true

# Press back button
- back
```

---

## Fake Relay Server

### Building and Running (Recommended: GNU Screen)

```bash
cd /Users/rquast/projects/fspec-mobile

# Compile the server (one time)
/Users/rquast/fvm/versions/stable/bin/dart compile exe tools/fake_relay_server.dart -o /tmp/fake_relay_server

# Create a wrapper script for logging
cat > /tmp/run_relay.sh << 'EOF'
#!/bin/bash
exec /tmp/fake_relay_server 2>&1 | tee /tmp/fake_relay.log
EOF
chmod +x /tmp/run_relay.sh

# Start in detached screen session
screen -dmS relay /tmp/run_relay.sh

# Verify it's running
screen -ls                    # Should show "relay" session
lsof -i :8765 -P | grep LISTEN  # Should show fake_relay_server

# View live logs
tail -f /tmp/fake_relay.log

# Attach to screen session (to see full output)
screen -r relay
# Detach: Ctrl+A, D

# Kill the server
screen -X -S relay quit
```

### Quick Commands

```bash
# Check if relay is running
lsof -i :8765 -P | grep LISTEN

# Test HTTP endpoint
curl -s http://127.0.0.1:8765

# View recent logs
tail -20 /tmp/fake_relay.log

# Restart relay server
screen -X -S relay quit 2>/dev/null; screen -dmS relay /tmp/run_relay.sh
```

### Connection Details for App

```
Name: Local Dev Server
Relay URL: http://localhost:8765
Channel ID: dev-channel
API Key: (leave empty)
```

### Known Issue: URL Path Appending

The app appends `/v1/ws` to the relay URL automatically:
- Input: `http://localhost:8765`
- Actual WebSocket URL: `ws://localhost:8765/v1/ws`

The fake server handles any path, so this should work.

### Checking Server Logs

```bash
cat /tmp/fake_relay.log
```

---

## iOS Simulator Networking

### Localhost Access

The iOS Simulator **should** be able to access `localhost` on the host machine directly. Unlike Android emulator, you don't need special IP addresses like `10.0.2.2`.

However, if having issues:
1. Try using `127.0.0.1` instead of `localhost`
2. Try your machine's actual IP: `ifconfig en0 | grep "inet "`
3. Ensure no firewall blocking

### Debugging Connection Issues

```bash
# Check app logs for WebSocket errors
xcrun simctl spawn booted log show --predicate 'processImagePath contains "Runner"' --last 1m 2>&1 | grep -i "websocket\|connect\|error"
```

---

## Flutter App

### Running the App

```bash
cd /Users/rquast/projects/fspec-mobile

# Run on iOS Simulator
fvm flutter run -d "iPhone 16 Pro"

# Hot reload: press 'r' in terminal
# Hot restart: press 'R' in terminal
```

### Checking Available Simulators

```bash
xcrun simctl list devices available | grep -E "(iPhone|iPad)"
```

### Boot Simulator

```bash
xcrun simctl boot "iPhone 16 Pro"
open -a Simulator
```

### Take Screenshots

```bash
xcrun simctl io booted screenshot /tmp/screenshot.png
```

---

## Common Issues

### 1. Connection Refused on Port 8765

**Symptom:** App logs show `Connection refused, errno = 61`

**Solutions:**
- Ensure fake relay server is actually running: `lsof -i :8765 -P`
- Compile and run the binary version instead of `dart run`
- Check if process died: `ps aux | grep fake_relay`

### 2. Maestro Can't Find Elements

**Symptom:** `Element not found: Text matching regex: XYZ`

**Solutions:**
- Take a screenshot first to see actual screen state
- Element might be off-screen - add swipe/scroll
- Keyboard might be covering element - dismiss with `pressKey: Enter`
- Check for exact text match (case-sensitive)

### 3. Dashboard Shows Empty After Save

**Symptom:** Connection saved but doesn't appear on dashboard

**Solution:** The `connectionsProvider` needs to be invalidated after saving. This was fixed by adding:
```dart
ref.invalidate(connectionsProvider);
```
in `add_connection_screen.dart` after successful save.

### 4. Validation Fails for localhost URL

**Symptom:** Can't save connection with `http://localhost:8765`

**Solution:** The Connection model's `validate()` method was updated to allow `http://localhost` and `http://127.0.0.1` for development.

### 5. Connection Status Not Updating in UI

**Symptom:** Connection shows "SYNCING" even after auth succeeds; Active Instances counter stays at 0

**Root Cause:** The `RelayConnectionService` was updating connection status in the repository, but the dashboard's `connectionsProvider` wasn't being notified to refresh.

**Solution:** Added `_onConnectionChanged` callback to `RelayConnectionService` that invalidates `connectionsProvider` when status changes (see `relay_connection_service.dart`).

---

## Quick Start Checklist

1. **Start fake relay server:**
   ```bash
   /tmp/fake_relay_server > /tmp/fake_relay.log 2>&1 &
   ```

2. **Verify server is running:**
   ```bash
   curl -s http://127.0.0.1:8765
   ```

3. **Start Flutter app:**
   ```bash
   cd /Users/rquast/projects/fspec-mobile
   fvm flutter run -d "iPhone 16 Pro"
   ```

4. **Run Maestro test:**
   ```bash
   export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH:$HOME/.maestro/bin"
   export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
   maestro test tools/maestro/add_and_save_connection.yaml
   ```

5. **Check logs if issues:**
   ```bash
   # Server logs
   cat /tmp/fake_relay.log
   
   # App logs
   xcrun simctl spawn booted log show --predicate 'processImagePath contains "Runner"' --last 1m 2>&1 | grep -i "websocket\|error"
   ```
