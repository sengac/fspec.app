# fspec Mobile Architecture Notes - Part 2: Relay Server Rationale

## Why a Relay Server?

### Mobile Device Limitations

Mobile devices cannot easily run WebSocket servers with stable addresses because:
1. NAT traversal issues - no public IP
2. Dynamic IP addresses on cellular networks
3. App backgrounding kills server sockets
4. Battery optimization restricts persistent connections

### Telegram Bridge Pattern vs Mobile App

**Telegram Bridge:**
```
fspec ----[connects to]----> Telegram Endpoint ----[Telegram API]----> Phone
            (client)            (server)
```
Telegram handles delivery persistence. The endpoint just translates.

**Mobile App (naive approach - won't work):**
```
fspec ----[connects to]----> Mobile App running server???
            (client)            (can't host stable server)
```

### Solution: Cloud Relay

```
Mobile App <----[connects to]----> Relay Server <----[connects to]---- fspec
  (client)                           (server)                          (client)
```

Both fspec and mobile app are clients connecting to a stable relay server.

## Relay Server Responsibilities

### 1. Bidirectional Buffering

**Buffer fspec→mobile when mobile disconnects:**
- Phone goes to sleep
- App backgrounded
- Network switch (WiFi ↔ cellular)
- Temporary connectivity loss

**Buffer mobile→fspec when fspec disconnects:**
- Laptop closed
- Network issue on workstation
- fspec process restarted

### 2. Authentication

- User accounts (which users own which fspec instances)
- Token-based auth for both mobile app and fspec connections
- Prevent unauthorized access to other users' streams/commands

### 3. Connection State Tracking

- Know which fspec instances are online
- Know which mobile clients are connected
- Route messages only to live connections
- Buffer for disconnected recipients

### 4. Reconnection Handling

- Replay buffered messages on reconnect
- Size limits (like fspec's 1GB limit)
- TTL on buffered messages to avoid stale data

## Instance-Level vs Session-Level Connection

**Decision: Connect at the INSTANCE level, not session level.**

Reasoning (Single Responsibility):
1. **Project state** (board, work units, features) exists whether AI is running or not
2. **AI session interaction** (streaming, input, interrupt) only meaningful when session active

The fspec CLI reflects this - you can run `fspec board` without any AI session.

### Connection Model

```
Mobile App connects to Relay
           ↓
    authenticates as User
           ↓
    subscribes to Instance (by instance ID)
           ↓
    Instance channel provides:
       - Project queries (always available)
       - Session subscriptions (zero or more, dynamic)
```

Sessions come and go; the instance connection remains stable.
