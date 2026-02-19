@done
@ui-layer
@board
@MOBILE-006
Feature: Work Unit Detail View

  """
  Fetch work unit details via WebSocket relay using existing connection infrastructure from MOBILE-004
  Reuse color theming from Kanban board for type/status badges
  Navigate to detail view by sending show-work-unit command via WebSocket relay
  """

  # ========================================
  # EXAMPLE MAPPING CONTEXT
  # ========================================
  #
  # BUSINESS RULES:
  #   1. Header displays work unit ID, back navigation, and overflow menu
  #   2. Status row shows type badge (Story/Bug/Task), status badge with icon, and story points
  #   3. User story displays role, action, and benefit with keyword highlighting
  #   4. Rules are displayed as blue-themed cards with count badge in section header
  #   5. Examples are displayed as green-themed cards with type labels (HAPPY PATH, EDGE CASE) and count badge
  #   6. Questions are displayed as red/pink-themed cards with @mention highlighting and count badge
  #   7. Architecture notes section displays technical context for the work unit
  #   8. v1 is view-only - no editing or adding capabilities
  #
  # EXAMPLES:
  #   1. User taps work unit AUTH-001 from Kanban board → Detail view shows full Example Mapping with 2 rules, 2 examples, 1 question
  #   2. Work unit has no user story set → User story section shows empty state or is hidden
  #   3. Work unit has zero rules → Rules section header shows (0) badge, section is collapsed or shows empty state
  #   4. Question contains @security-team mention → Mention text is highlighted in distinct color
  #   5. Work unit is type Bug → Purple badge shows 'Bug' instead of 'Story'
  #   6. Work unit has no estimate → Story points badge is hidden or shows dash
  #   7. User presses back arrow → Returns to Kanban board view
  #
  # ========================================

  Background: User Story
    As a mobile user
    I want to view full work unit details including Example Mapping data
    So that understand the complete context of a story before working on it

  # ========================================
  # SCENARIOS
  # ========================================

  @happy-path
  Scenario: View work unit with full Example Mapping data
    Given I am connected to a relay instance
    And the instance has a work unit "AUTH-001" with:
      | field       | value                       |
      | title       | Implement Biometric Login   |
      | type        | story                       |
      | status      | specifying                  |
      | estimate    | 5                           |
      | rules       | 2                           |
      | examples    | 2                           |
      | questions   | 1                           |
    When I tap on work unit "AUTH-001" from the Kanban board
    Then I should see the work unit detail view
    And I should see the header with "AUTH-001" and back navigation
    And I should see the title "Implement Biometric Login"
    And I should see a "Story" type badge
    And I should see a "Specifying" status badge
    And I should see "5 pts" story points
    And I should see the user story section with highlighted keywords
    And I should see the rules section with count badge showing "2"
    And I should see 2 blue-themed rule cards
    And I should see the examples section with count badge showing "2"
    And I should see 2 green-themed example cards with type labels
    And I should see the questions section with count badge showing "1"
    And I should see 1 red-themed question card

  @edge-case
  Scenario: View work unit without user story
    Given I am connected to a relay instance
    And the instance has a work unit "TASK-001" without a user story
    When I navigate to the work unit detail view for "TASK-001"
    Then I should see the work unit detail view
    And I should not see the user story section

  @edge-case
  Scenario: View work unit with zero rules
    Given I am connected to a relay instance
    And the instance has a work unit "NEW-001" with zero rules
    When I navigate to the work unit detail view for "NEW-001"
    Then I should see the rules section with count badge showing "0"
    And I should see an empty state for the rules section

  @edge-case
  Scenario: Question displays @mention highlighting
    Given I am connected to a relay instance
    And the instance has a work unit "AUTH-001" with a question containing "@security-team"
    When I navigate to the work unit detail view for "AUTH-001"
    Then I should see the question text with "@security-team" highlighted in a distinct color

  @edge-case
  Scenario: View bug work unit type
    Given I am connected to a relay instance
    And the instance has a work unit "BUG-001" of type "bug"
    When I navigate to the work unit detail view for "BUG-001"
    Then I should see a "Bug" type badge with appropriate styling

  @edge-case
  Scenario: View work unit without estimate
    Given I am connected to a relay instance
    And the instance has a work unit "DRAFT-001" without an estimate
    When I navigate to the work unit detail view for "DRAFT-001"
    Then I should not see the story points badge

  @navigation
  Scenario: Navigate back to Kanban board
    Given I am viewing the work unit detail for "AUTH-001"
    When I press the back arrow
    Then I should return to the Kanban board view
