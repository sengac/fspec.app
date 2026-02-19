@done
@MOBILE-005
Feature: Kanban Board View

  """
  Use PageView widget for horizontal column swiping with PageController
  Create BoardNotifier extending AsyncNotifier to manage board state and relay communication
  Work unit card is tappable to navigate to detail view (MOBILE-006)
  """

  # ========================================
  # EXAMPLE MAPPING CONTEXT
  # ========================================
  #
  # BUSINESS RULES:
  #   1. Board displays 7 columns: Backlog, Specifying, Testing, Implementing, Validating, Done, Blocked
  #   2. Each column shows a count of work units it contains
  #   3. Work unit cards display: ID, title, story points (if estimated), and type indicator
  #   4. Type indicators: blue dot for story, orange dot for bug, green dot for task
  #   5. Horizontal swipe navigates between columns with page indicators
  #   6. Board data is fetched by sending 'board' command via WebSocket relay
  #   7. Columns are vertically scrollable when content exceeds screen height
  #   8. Yes, show a centered loading spinner while waiting for board data
  #   9. Yes, pull-to-refresh reloads board data - standard mobile pattern
  #   10. Show connection lost banner with retry option, keep displaying cached data
  #
  # EXAMPLES:
  #   1. User opens board and sees Backlog column with 12 work units, swipes left to see Specifying column
  #   2. Work unit card shows 'AUTH-001' ID, 'Implement OAuth2 login flow' title, folder icon with '5 pts', and blue dot indicating story type
  #   3. Bug work unit 'UI-103' displays with bug icon, '3 pts', and orange dot indicator
  #   4. Task work unit 'API-204' displays with checkbox icon, '2 pts', and green dot indicator
  #   5. Column with 15 work units is vertically scrollable; user scrolls down to see remaining cards
  #   6. Board sends 'board' command via relay on load and receives JSON with column data
  #   7. Work unit without estimate shows only ID, title, and type indicator (no points)
  #
  # QUESTIONS (ANSWERED):
  #   Q: Should we show a loading indicator while fetching board data?
  #   A: Yes, show a centered loading spinner while waiting for board data
  #
  #   Q: Should we support pull-to-refresh to reload the board?
  #   A: Yes, pull-to-refresh reloads board data - standard mobile pattern
  #
  #   Q: What happens if the WebSocket connection is lost while viewing the board?
  #   A: Show connection lost banner with retry option, keep displaying cached data
  #
  # ========================================

  Background: User Story
    As a mobile user
    I want to view my project's Kanban board
    So that see work unit status across all workflow columns

  # ========================================
  # SCENARIOS
  # ========================================

  @happy-path
  Scenario: View and navigate between board columns
    Given I am connected to an fspec instance
    And the board has work units in multiple columns
    When I open the Kanban board
    Then I see the Backlog column with a work unit count
    And I see page indicators showing 7 columns
    When I swipe left
    Then I see the Specifying column
    And the page indicator updates to show current position

  @happy-path
  Scenario: Display story work unit card
    Given I am viewing the Kanban board
    And the board contains a story "AUTH-001" titled "Implement OAuth2 login flow" with 5 points
    When I view the work unit card
    Then I see the ID "AUTH-001"
    And I see the title "Implement OAuth2 login flow"
    And I see a folder icon with "5 pts"
    And I see a blue dot indicator for story type

  @happy-path
  Scenario: Display bug work unit card
    Given I am viewing the Kanban board
    And the board contains a bug "UI-103" titled "Fix dark mode contrast issues" with 3 points
    When I view the work unit card
    Then I see the ID "UI-103"
    And I see a bug icon with "3 pts"
    And I see an orange dot indicator for bug type

  @happy-path
  Scenario: Display task work unit card
    Given I am viewing the Kanban board
    And the board contains a task "API-204" titled "Update user profile endpoint" with 2 points
    When I view the work unit card
    Then I see the ID "API-204"
    And I see a checkbox icon with "2 pts"
    And I see a green dot indicator for task type

  @happy-path
  Scenario: Work unit without estimate shows no points
    Given I am viewing the Kanban board
    And the board contains a story "SETUP-001" titled "Initial setup" without an estimate
    When I view the work unit card
    Then I see the ID "SETUP-001"
    And I see the title "Initial setup"
    And I see a blue dot indicator for story type
    But I do not see any points displayed

  @happy-path
  Scenario: Scroll vertically in column with many work units
    Given I am viewing the Kanban board
    And the current column contains 15 work units
    When I scroll down in the column
    Then I see additional work unit cards
    And I can scroll back up to see earlier cards

  @loading
  Scenario: Show loading indicator while fetching board data
    Given I am connected to an fspec instance
    When I navigate to the Kanban board
    Then I see a centered loading spinner
    When the board data loads successfully
    Then the loading spinner disappears
    And I see the board columns with work units

  @refresh
  Scenario: Pull to refresh reloads board data
    Given I am viewing the Kanban board
    When I pull down to refresh
    Then I see a refresh indicator
    And a "board" command is sent via WebSocket relay
    When fresh board data is received
    Then the board updates with the new data
    And the refresh indicator disappears

  @error-handling
  Scenario: Handle connection loss while viewing board
    Given I am viewing the Kanban board with work units displayed
    When the WebSocket connection is lost
    Then I see a connection lost banner
    And the banner shows a retry option
    And I can still see the previously loaded board data
    When I tap the retry button
    Then the app attempts to reconnect

  @data-loading
  Scenario: Fetch board data via relay on load
    Given I am connected to an fspec instance
    When I open the Kanban board
    Then a "board" command is sent via WebSocket relay
    And I receive JSON data containing columns and work units
    And the board displays work units in their respective columns
