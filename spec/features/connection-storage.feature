@data-layer
@connection
@MOBILE-001
Feature: Connection Data Model and Local Storage
  """
  Use Freezed for immutable Connection model with JSON serialization. Use Hive with hive_ce for local storage. Create ConnectionRepository with Riverpod provider.
  """

  # ========================================
  # EXAMPLE MAPPING CONTEXT
  # ========================================
  #
  # BUSINESS RULES:
  #   1. A Connection must have a unique identifier (UUID)
  #   2. A Connection must have a non-empty display name
  #   3. A Connection must have a valid relay server URL (https scheme)
  #   4. A Connection must have a channel ID
  #   5. API key is optional (some relays may not require authentication)
  #   6. Connections are persisted locally using Hive encrypted storage
  #   7. Connection status tracks: disconnected, connecting, connected, error
  #
  # EXAMPLES:
  #   1. Creating connection with name 'Work MacBook', URL 'https://relay.fspec.dev', channel 'abc-123' succeeds
  #   2. Creating connection without API key succeeds (API key is optional)
  #   3. Creating connection with empty name fails with validation error
  #   4. Creating connection with http:// URL fails (must be https)
  #   5. Saved connections are available after app restart
  #   6. Updating a connection's name persists the change
  #   7. Deleting a connection removes it from storage permanently
  #   8. Listing connections returns all saved connections in order of creation
  #
  # ========================================
  Background: User Story
    As a mobile developer
    I want to store and retrieve fspec instance connections locally
    So that my connections persist across app restarts and I can manage multiple instances

  # ========================================
  # SCENARIOS
  # ========================================
  @happy-path
  Scenario: Creating a connection with all required fields succeeds
    Given I have no saved connections
    When I create a connection with:
      | name      | Work MacBook            |
      | relayUrl  | https://relay.fspec.dev |
      | channelId | abc-123                 |
    Then the connection should be saved successfully
    And the connection should have a unique UUID
    And the connection status should be "disconnected"

  @happy-path
  Scenario: Creating a connection without API key succeeds
    Given I have no saved connections
    When I create a connection with:
      | name      | Home Server             |
      | relayUrl  | https://relay.fspec.dev |
      | channelId | xyz-789                 |
      | apiKey    |                         |
    Then the connection should be saved successfully

  @validation
  Scenario: Creating a connection with empty name fails
    Given I have no saved connections
    When I create a connection with:
      | name      |                         |
      | relayUrl  | https://relay.fspec.dev |
      | channelId | abc-123                 |
    Then the connection should fail with validation error "Name is required"

  @validation
  Scenario: Creating a connection with http URL fails
    Given I have no saved connections
    When I create a connection with:
      | name      | Insecure Server        |
      | relayUrl  | http://relay.fspec.dev |
      | channelId | abc-123                |
    Then the connection should fail with validation error "URL must use HTTPS"

  @persistence
  Scenario: Saved connections persist after app restart
    Given I have a saved connection named "Work MacBook"
    When the app restarts
    And I list all connections
    Then I should see a connection named "Work MacBook"

  @persistence
  Scenario: Updating a connection name persists the change
    Given I have a saved connection named "Old Name"
    When I update the connection name to "New Name"
    And the app restarts
    And I list all connections
    Then I should see a connection named "New Name"
    And I should not see a connection named "Old Name"

  @persistence
  Scenario: Deleting a connection removes it permanently
    Given I have a saved connection named "To Delete"
    When I delete the connection named "To Delete"
    And the app restarts
    And I list all connections
    Then I should not see a connection named "To Delete"

  @listing
  Scenario: Listing connections returns them in creation order
    Given I have no saved connections
    When I create a connection named "First"
    And I create a connection named "Second"
    And I create a connection named "Third"
    And I list all connections
    Then the connections should be in order:
      | name   |
      | First  |
      | Second |
      | Third  |
