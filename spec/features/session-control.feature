@done
@mobile-core
@session
@MOBILE-009
Feature: Session Control

  """
  Uses WebSocketManager.sendSessionControl() for fire-and-forget messages. EmergencyInterruptButton widget already exists. Header overflow menu via PopupMenuButton with Clear Session option requiring confirmation dialog.
  """

  # ========================================
  # EXAMPLE MAPPING CONTEXT
  # ========================================
  #
  # BUSINESS RULES:
  #   1. Emergency interrupt button sends 'interrupt' action via session_control message type
  #   2. Clear button sends 'clear' action via session_control message type
  #   3. Session control messages are fire-and-forget (no response expected)
  #   4. Emergency interrupt button is prominently displayed in red
  #   5. Session control messages include session_id to target the correct session
  #   6. Header overflow menu (⋮) - three dots in header, contains Clear Session option
  #   7. Yes - show confirmation dialog before clearing (destructive action)
  #
  # EXAMPLES:
  #   1. User taps red EMERGENCY INTERRUPT button → sends session_control with action='interrupt'
  #   2. User taps Clear Session option → sends session_control with action='clear'
  #   3. User taps interrupt while WebSocket is disconnected → shows error/no-op
  #   4. Emergency interrupt button visible above input bar on session stream screen
  #
  # QUESTIONS (ANSWERED):
  #   Q: Where should the Clear Session option be located? Header menu? Separate button?
  #   A: Header overflow menu (⋮) - three dots in header, contains Clear Session option
  #
  #   Q: Should there be a confirmation dialog before clearing the session?
  #   A: Yes - show confirmation dialog before clearing (destructive action)
  #
  # ========================================

  Background: User Story
    As a mobile app user
    I want to control active fspec sessions with interrupt and clear commands
    So that manage AI execution and start fresh when needed

  @interrupt
  Scenario: User sends interrupt command via emergency button
    Given I am viewing an active session stream
    And the session is running
    When I tap the emergency interrupt button
    Then a session_control message with action "interrupt" should be sent
    And the message should include the current session_id

  @clear
  Scenario: User clears session via header menu
    Given I am viewing an active session stream
    When I tap the overflow menu in the header
    And I tap "Clear Session"
    Then a confirmation dialog should appear
    When I confirm the clear action
    Then a session_control message with action "clear" should be sent
    And the message should include the current session_id

  @clear
  Scenario: User cancels clear session confirmation
    Given I am viewing an active session stream
    When I tap the overflow menu in the header
    And I tap "Clear Session"
    Then a confirmation dialog should appear
    When I cancel the clear action
    Then no session_control message should be sent

  @interrupt @offline
  Scenario: User taps interrupt while disconnected
    Given I am viewing a session stream
    And the WebSocket connection is disconnected
    When I tap the emergency interrupt button
    Then the interrupt should fail gracefully
    And no crash should occur

  @ui
  Scenario: Emergency interrupt button is prominently displayed
    Given I am viewing an active session stream
    Then I should see the emergency interrupt button in red
    And the button should be positioned above the input bar
    And the button should span the full width of the screen
