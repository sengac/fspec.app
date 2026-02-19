@ui-layer
@dashboard
@MOBILE-003
Feature: Instance Dashboard
  """
  Uses Connection model with added fields: lastKnownProjectName, lastActivityType, lastActivityContent, lastActivityAt. Dashboard screen uses Riverpod to watch connection list and auto-refresh status.
  """

  # ========================================
  # EXAMPLE MAPPING CONTEXT
  # ========================================
  #
  # BUSINESS RULES:
  #   1. Each instance card shows: instance name, connection status (online/offline/syncing), time since last activity, and project name
  #   2. Each instance card shows an activity preview with the most recent AI output, error, or status message
  #   3. Connection status is indicated with colored dots: green for ONLINE, red for OFFLINE, and a distinct indicator for SYNCING
  #   4. Instance list auto-refreshes to show real-time status updates
  #   5. Tapping an instance card navigates to the instance detail view
  #   6. Each card has a context-sensitive action button based on instance state (View Details, Retry, Open Staging, etc.)
  #   7. connected→ONLINE, disconnected→OFFLINE, connecting→SYNCING, error→OFFLINE (with error indicator)
  #   8. Project name received from fspec instance via WebSocket when connected. Store as lastKnownProjectName on Connection model to display when offline.
  #   9. Activity preview from WebSocket session stream. Cache on Connection: lastActivityType (aiOutput/error/status), lastActivityContent (truncated preview), lastActivityAt (timestamp for relative display).
  #   10. Dashboard displays summary stat showing active instances count
  #
  # EXAMPLES:
  #   1. User opens dashboard with 3 connections: MacBook Pro (online, fspec-core), Ubuntu Server (offline, api-gateway), Development VM (online, mobile-ui) - sees all cards with correct status colors
  #   2. MacBook Pro card shows AI OUTPUT SNIPPET: 'Optimized 3 functions in core module. Reduced latency by 12%...' with 'View Details' button
  #   3. Ubuntu Server card shows CRITICAL FAILURE in red: 'Build failed at step 4: dependency conflict...' with 'Retry Deployment' button
  #   4. User opens dashboard with no connections configured - sees empty state with prompt to add first connection
  #   5. User taps on MacBook Pro card - navigates to instance detail view for that connection
  #   6. User sees summary stat showing '3' active instances at top of screen
  #
  # QUESTIONS (ANSWERED):
  #   Q: The Connection model has status enum (disconnected/connecting/connected/error) but design shows ONLINE/OFFLINE/SYNCING. How should these map?
  #   A: connected→ONLINE, disconnected→OFFLINE, connecting→SYNCING, error→OFFLINE (with error indicator)
  #
  #   Q: Connection model has no projectName field - where does the project name displayed on cards come from?
  #   A: Project name received from fspec instance via WebSocket when connected. Store as lastKnownProjectName on Connection model to display when offline.
  #
  #   Q: Activity preview data (AI output snippets, errors, status messages) - where does this come from? Need a separate activity/message model?
  #   A: Activity preview from WebSocket session stream. Cache on Connection: lastActivityType (aiOutput/error/status), lastActivityContent (truncated preview), lastActivityAt (timestamp for relative display).
  #
  #   Q: What defines 'failed jobs' for the summary stat? Is this related to CRITICAL FAILURE messages?
  #   A: Deferred - failed jobs stat not needed for initial implementation. Can add later if required.
  #
  # ========================================
  Background: User Story
    As a mobile app user
    I want to view a dashboard of all my fspec instance connections
    So that quickly see status and activity across all my projects

  Scenario: Dashboard displays multiple connections with status indicators
    Given I have the following connections configured:
      | name           | status       | projectName |
      | MacBook Pro    | connected    | fspec-core  |
      | Ubuntu Server  | disconnected | api-gateway |
      | Development VM | connected    | mobile-ui   |
    When I open the dashboard
    Then I should see 3 instance cards
    And "MacBook Pro" should show "ONLINE" status with a green indicator
    And "Ubuntu Server" should show "OFFLINE" status with a red indicator
    And "Development VM" should show "ONLINE" status with a green indicator

  Scenario: Instance card shows AI output activity preview
    Given I have a connection "MacBook Pro" with status "connected"
    And the connection has activity type "aiOutput"
    And the activity content is "Optimized 3 functions in core module. Reduced latency by 12%..."
    When I open the dashboard
    Then the "MacBook Pro" card should show "AI OUTPUT SNIPPET" label
    And the card should display the activity preview text
    And the card should have a "View Details" action button

  Scenario: Instance card shows error activity preview
    Given I have a connection "Ubuntu Server" with status "error"
    And the connection has activity type "error"
    And the activity content is "Build failed at step 4: dependency conflict..."
    When I open the dashboard
    Then the "Ubuntu Server" card should show "CRITICAL FAILURE" label in red
    And the card should display the error preview text
    And the card should have a "Retry Deployment" action button

  Scenario: Empty state when no connections configured
    Given I have no connections configured
    When I open the dashboard
    Then I should see an empty state message
    And I should see a prompt to add my first connection

  Scenario: Navigate to instance detail on card tap
    Given I have a connection "MacBook Pro" with status "connected"
    When I open the dashboard
    And I tap on the "MacBook Pro" card
    Then I should navigate to the instance detail view for "MacBook Pro"

  Scenario: Dashboard shows active instances summary stat
    Given I have the following connections configured:
      | name           | status       |
      | MacBook Pro    | connected    |
      | Ubuntu Server  | disconnected |
      | Development VM | connected    |
    When I open the dashboard
    Then I should see "2" as the active instances count

  Scenario: Instance card shows SYNCING status for connecting connection
    Given I have a connection "Staging Server" with status "connecting"
    When I open the dashboard
    Then "Staging Server" should show "SYNCING" status with an orange indicator

  Scenario: Instance card displays project name
    Given I have a connection "MacBook Pro" with project name "fspec-core"
    When I open the dashboard
    Then the "MacBook Pro" card should display "fspec-core" as the project name
