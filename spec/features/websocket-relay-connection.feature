@done
@data-layer
@websocket
@MOBILE-004
Feature: WebSocket Relay Connection

  """
  Uses WebSocketManager with Riverpod for state management. Auth protocol: mobile sends 'auth' message with channel_id + optional api_key, relay responds with 'auth_success' or 'auth_error'. Connection state persisted via ConnectionRepository (Hive). Auto-reconnect uses exponential backoff (1s initial, 30s max, 10 attempts max). Ping/pong heartbeat every 30 seconds.
  """

  # ========================================
  # EXAMPLE MAPPING CONTEXT
  # ========================================
  #
  # BUSINESS RULES:
  #   1. Connection requires relay URL, channel ID, and optional API key
  #   2. Authentication handshake must complete before any other messages can be sent
  #   3. Connection state must be reflected in the Connection model and UI
  #   4. Auto-reconnect with exponential backoff on connection loss (max 10 attempts)
  #   5. Ping/pong heartbeat every 30 seconds to keep connection alive
  #   6. Mobile sends 'auth' message with channel_id and optional api_key. Relay responds with 'auth_success' (including connected instances) or 'auth_error' with codes: INVALID_CHANNEL, INVALID_API_KEY, RATE_LIMITED
  #   7. INVALID_CHANNEL for bad channel ID, INVALID_API_KEY for bad API key - allows app to show specific error guidance
  #   8. Yes - persist last connected state and auto-connect on app launch
  #
  # EXAMPLES:
  #   1. User taps connect on a saved connection, sees 'Connecting...' indicator, then sees 'Connected' when auth succeeds
  #   2. User connects with invalid API key, sees 'Authentication failed' error and connection stays disconnected
  #   3. Network drops while connected, app shows 'Reconnecting...' and automatically retries
  #   4. User manually disconnects from an active connection, status immediately shows 'Disconnected'
  #   5. Reconnection fails after 10 attempts, app shows 'Connection failed - tap to retry' error
  #
  # QUESTIONS (ANSWERED):
  #   Q: What is the exact authentication handshake protocol with the relay? Does mobile send channelId+apiKey on connect, and relay responds with 'connected' message?
  #   A: Mobile sends 'auth' message with channel_id and optional api_key. Relay responds with 'auth_success' (including connected instances) or 'auth_error' with codes: INVALID_CHANNEL, INVALID_API_KEY, RATE_LIMITED
  #
  #   Q: What error message/code does the relay send for invalid channel ID vs invalid API key?
  #   A: INVALID_CHANNEL for bad channel ID, INVALID_API_KEY for bad API key - allows app to show specific error guidance
  #
  #   Q: Should the mobile app persist the last connected state and auto-connect on launch?
  #   A: Yes - persist last connected state and auto-connect on app launch
  #
  # ========================================

  Background: User Story
    As a mobile user
    I want to connect to my fspec relay server
    So that interact with my fspec sessions remotely

  @happy-path
  Scenario: Successful connection to relay server
    Given I have a saved connection with valid credentials
    And the relay server is available
    When I tap connect on the connection
    Then I should see "Connecting..." status indicator
    And the app should send an auth message with channel_id and api_key
    When the relay responds with auth_success
    Then I should see "Connected" status
    And the connection state should be persisted

  @error-handling
  Scenario: Connection fails with invalid API key
    Given I have a saved connection with an invalid API key
    And the relay server is available
    When I tap connect on the connection
    Then I should see "Connecting..." status indicator
    When the relay responds with auth_error code "INVALID_API_KEY"
    Then I should see "Authentication failed" error message
    And the connection status should show "Disconnected"
    And the app should not attempt to reconnect

  @error-handling
  Scenario: Connection fails with invalid channel ID
    Given I have a saved connection with an invalid channel ID
    And the relay server is available
    When I tap connect on the connection
    Then I should see "Connecting..." status indicator
    When the relay responds with auth_error code "INVALID_CHANNEL"
    Then I should see "Channel not found" error message
    And the connection status should show "Disconnected"

  @reconnection
  Scenario: Automatic reconnection on network drop
    Given I am connected to the relay server
    When the network connection drops
    Then I should see "Reconnecting..." status indicator
    And the app should attempt to reconnect with exponential backoff
    When the network becomes available
    And the reconnection succeeds
    Then I should see "Connected" status

  @reconnection
  Scenario: Reconnection exhausted after maximum attempts
    Given I am connected to the relay server
    When the network connection drops
    And the relay server remains unavailable
    Then the app should retry up to 10 times with exponential backoff
    When all 10 reconnection attempts fail
    Then I should see "Connection failed - tap to retry" error
    And the connection status should show "Error"

  @manual-control
  Scenario: Manual disconnect from active connection
    Given I am connected to the relay server
    When I tap disconnect on the connection
    Then the connection status should immediately show "Disconnected"
    And the WebSocket connection should be closed
    And the app should not attempt to reconnect

  @auto-connect
  Scenario: Auto-connect on app launch
    Given I have a saved connection that was previously connected
    When I launch the app
    Then the app should automatically attempt to connect
    And I should see "Connecting..." status indicator
