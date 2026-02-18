# fspec Mobile

A Flutter-based mobile companion app that enables developers to manage multiple fspec projects on-the-go, connecting via WebSocket bridges to actively running fspec instances for real-time project visibility and lightweight task management from anywhere.

## The Problem

Developers practicing Acceptance Criteria Driven Development (ACDD) with fspec need real-time visibility into their project state, work unit status, and task progress. Currently, fspec is a CLI tool tied to development machines, requiring terminal access to check boards, manage work units, or review specifications.

When in meetings, commuting, or away from their desk, developers lose connection to their project workflow, making it difficult to:
- Plan ahead
- Update priorities
- Stay informed about multi-project status across different machines

## The Solution

fspec Mobile connects to a cloud relay server via WebSocket. Each fspec instance (running on developer workstations) also connects to the same relay server using the existing Bridge tool. The relay server routes messages between the mobile app and fspec instances, enabling bidirectional communication.

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   Mobile    │◄───────►│    Relay     │◄───────►│   fspec     │
│     App     │   WS    │    Server    │   WS    │  Instance   │
└─────────────┘         └──────────────┘         └─────────────┘
    (client)               (server)                 (client)
```

## Features

### 📱 Multi-Instance Dashboard
View and switch between multiple fspec instances on a single dashboard. Monitor the status of all your projects at a glance.

### 📊 Real-time Stream Display
Watch AI output in real-time as fspec works on your projects. See text responses, thinking processes, tool calls, and results as they happen.

### 💬 Input Injection
Send text messages and images to fspec sessions via the input channel. Provide quick clarifications or instructions while away from your desk.

### 🎮 Session Control
Send control commands including:
- **Interrupt** - Stop the current AI operation
- **Clear** - Clear the session
- Execute arbitrary fspec commands (board queries, work unit operations, feature file queries, etc.)

### 📋 Project Queries (Always Available)
Even without an active AI session, you can:
- View Kanban board state
- Check work unit details
- Review feature specifications
- Query coverage status
- Browse project foundation and architecture

## Tech Stack

| Category | Technology | Version |
|----------|------------|---------|
| **Framework** | Flutter | 3.41+ |
| **State Management** | Riverpod | 3.2+ |
| **Navigation** | GoRouter | 17.1+ |
| **Immutable State** | Freezed | 3.0+ |
| **Networking** | Dio + WebSocket | 5.8+ |
| **Local Storage** | Hive CE | 2.11+ |
| **UI** | Material 3 + Google Fonts | - |

## Project Structure

```
lib/
├── app.dart                 # Main app widget
├── main.dart                # Entry point
├── config/                  # Theme configuration
├── constants/               # API endpoints, storage keys
├── router/                  # GoRouter navigation
├── core/
│   ├── error/               # Error handling (Freezed)
│   └── websocket/           # WebSocket connection manager
└── features/
    ├── connection/          # Relay server connection
    ├── dashboard/           # Multi-instance overview
    ├── board/               # Kanban board view
    ├── stream/              # AI session streaming
    └── work_unit/           # Work unit details
```

## Getting Started

### Prerequisites

- [FVM](https://fvm.app/) (Flutter Version Manager)
- Xcode (for iOS development)
- Android Studio (for Android development)

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/fspec-mobile.git
cd fspec-mobile

# Install Flutter via FVM
fvm install

# Get dependencies
fvm flutter pub get

# Generate code (Riverpod, Freezed)
fvm flutter pub run build_runner build --delete-conflicting-outputs

# Run on iOS Simulator
fvm flutter run -d ios

# Run on Android Emulator
fvm flutter run -d android
```

### Running Tests

```bash
fvm flutter test
```

### Code Analysis

```bash
fvm flutter analyze
```

## Message Protocol

The app communicates with fspec instances through a relay server using these message types:

| Type | Direction | Purpose |
|------|-----------|---------|
| `input` | mobile → fspec | Inject AI prompt (text + optional images) |
| `session_control` | mobile → fspec | Interrupt, clear session |
| `command` | mobile → fspec | Execute fspec commands |
| `command_response` | fspec → mobile | Command execution results |
| `chunk` | fspec → mobile | StreamChunk output from AI |

## Architecture

This app follows **Clean Architecture** principles with a feature-based folder structure:

- **Data Layer** - Repositories, data sources, models
- **Domain Layer** - Entities, use cases, repository interfaces
- **Presentation Layer** - Screens, controllers, widgets

State management uses **Riverpod** with code generation for type-safe, testable providers.

## Related Projects

- [fspec](https://github.com/your-org/fspec) - The CLI tool for Acceptance Criteria Driven Development
- [fspec-relay](https://github.com/your-org/fspec-relay) - The relay server that bridges mobile apps with fspec instances

## License

MIT
