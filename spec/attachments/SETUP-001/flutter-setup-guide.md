# Flutter App Setup Guide - fspec Mobile

## Overview

This guide covers setting up a production-ready Flutter application for the fspec Mobile companion app.

## 1. System Prerequisites

### macOS Development Tools

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Xcode from App Store, then:
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# Accept Xcode license
sudo xcodebuild -license accept

# Install CocoaPods
sudo gem install cocoapods
```

### Android Studio

1. Download from https://developer.android.com/studio
2. Install Android SDK (API 34+)
3. Configure Android emulator (Pixel 6 recommended)
4. Accept licenses: `flutter doctor --android-licenses`

## 2. Flutter Version Manager (FVM)

FVM allows managing multiple Flutter SDK versions per project.

```bash
# Install FVM via Homebrew
brew tap leoafarias/fvm
brew install fvm

# Configure shell (add to ~/.zshrc)
export PATH="$PATH:$HOME/fvm/default/bin"

# Install latest stable Flutter
fvm install stable

# Set as default
fvm global stable

# Verify installation
fvm flutter --version
```

### Project-specific Flutter Version

```bash
cd fspec-mobile
fvm use 3.32.0  # Or latest stable
fvm flutter pub get
```

## 3. Google Cloud SDK & Stitch MCP

### Install Google Cloud CLI

```bash
brew install --cask google-cloud-sdk

# Initialize and login
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud auth application-default set-quota-project YOUR_PROJECT_ID
```

### Enable Stitch API

```bash
# Enable the Stitch MCP API
gcloud beta services mcp enable stitch.googleapis.com

# Get application default credentials
gcloud auth application-default login
```

### Configure stitch-mcp for Claude

Add to `~/.config/claude/claude_desktop_config.json` (or Claude Code's MCP config):

```json
{
  "mcpServers": {
    "stitch": {
      "command": "npx",
      "args": ["-y", "stitch-mcp"],
      "env": {
        "GOOGLE_CLOUD_PROJECT": "YOUR_PROJECT_ID"
      }
    }
  }
}
```

### Available Stitch MCP Tools

| Tool | Description |
|------|-------------|
| `extract_design_context` | Scans a screen to extract "Design DNA" (Fonts, Colors, Layouts) |
| `fetch_screen_code` | Downloads raw HTML/Frontend code of a screen |
| `fetch_screen_image` | Downloads high-res screenshot of a screen |
| `generate_screen_from_text` | Generates NEW screen based on prompt |
| `create_project` | Creates new workspace/project folder |
| `list_projects` | Lists all available Stitch projects |
| `list_screens` | Lists all screens within a project |
| `get_project` | Retrieves details of a specific project |
| `get_screen` | Gets metadata for a specific screen |

### Designer Flow Workflow

1. **Extract**: Get design context from existing screen
2. **Generate**: Use that context to generate new screens with consistent design

## 4. Flutter Project Creation

### Using Template (Recommended)

```bash
# Clone the Riverpod Quickstart Template
git clone https://github.com/Erengun/Flutter-Riverpod-Quickstart-Template.git fspec_mobile
cd fspec_mobile

# Or create fresh with organization
flutter create --org com.fspec fspec_mobile
cd fspec_mobile
```

### Core Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  
  # Immutable State
  freezed_annotation: ^3.0.6
  
  # Navigation
  go_router: ^14.8.0
  
  # Networking
  dio: ^5.8.0
  web_socket_channel: ^3.0.0
  
  # Local Storage
  hive_ce: ^2.11.1
  
  # UI
  google_fonts: ^6.2.1
  
  # Utilities
  fpdart: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.0
  riverpod_generator: ^2.6.5
  freezed: ^3.0.6
  
  # Linting
  flutter_lints: ^5.0.0
```

### Project Structure

```
lib/
├── common/              # Shared widgets and components
├── config/              # App configuration (theme etc.)
├── constants/           # App-wide constants (endpoints, assets)
├── core/                # Core functionality, network layer
│   └── websocket/       # WebSocket connection management
├── features/            # Feature modules
│   ├── connection/      # Relay connection management
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── dashboard/       # Multi-instance dashboard
│   ├── board/           # Kanban board view
│   ├── work_unit/       # Work unit details
│   └── stream/          # Session stream view
├── router/              # Navigation & routing
├── utils/               # Utility functions
├── main.dart            # App entry point
└── app.dart             # App configuration
```

## 5. Verify Installation

```bash
# Run Flutter doctor
flutter doctor -v

# Expected output (all green):
# [✓] Flutter (Channel stable, 3.32.x)
# [✓] Android toolchain - develop for Android devices
# [✓] Xcode - develop for iOS and macOS
# [✓] Chrome - develop for the web
# [✓] Android Studio
# [✓] VS Code
# [✓] Connected device
# [✓] Network resources
```

## 6. Running the App

```bash
# Generate code (Riverpod, Freezed)
dart run build_runner build --delete-conflicting-outputs

# Run on iOS Simulator
flutter run -d ios

# Run on Android Emulator
flutter run -d android

# Run with specific flavor
flutter run --flavor dev -t lib/main_dev.dart
```

## 7. IDE Setup

### VS Code Extensions

- Dart
- Flutter
- Riverpod Snippets
- Error Lens
- GitLens

### Android Studio Plugins

- Flutter
- Dart
- Flutter Riverpod Snippets

## 8. Key Architecture Decisions for fspec Mobile

Based on the foundation architecture notes:

1. **WebSocket Client**: Mobile app connects TO relay server (not hosting a server)
2. **Connection Management**: Maintain connections to multiple relay channels
3. **Message Types**:
   - `input` - Send prompts to fspec sessions
   - `session_control` - Interrupt/clear commands
   - `command` - fspec commands (board, work units, etc.)
   - `chunk` - Receive StreamChunk output from AI
4. **Offline Support**: Cache last known project state for offline viewing
5. **State Management**: Riverpod for reactive state, Freezed for immutable models

## References

- Flutter Riverpod Template: https://github.com/Erengun/Flutter-Riverpod-Quickstart-Template
- Stitch MCP: https://github.com/Kargatharaakash/stitch-mcp
- Google Stitch: https://stitch.withgoogle.com
- FVM Documentation: https://fvm.app
- Flutter Clean Architecture: https://ssoad.github.io/flutter_riverpod_clean_architecture/
