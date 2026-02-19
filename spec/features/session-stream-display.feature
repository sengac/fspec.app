@MOBILE-007
Feature: Session Stream Display

  """
  Subscribes to WebSocketManager.messageStream filtering for chunk messages. Uses Riverpod StreamProvider for reactive UI updates. Chunk types: text, thinking, toolCall, toolResult, toolProgress, sessionStateChange, done, error. UI widgets: UserMessageBubble, ThinkingBlock (ExpansionTile), ToolCallCard, AssistantMessageBubble. Auto-scroll via ScrollController with smart pause on manual scroll.
  """

  # ========================================
  # EXAMPLE MAPPING CONTEXT
  # ========================================
  #
  # BUSINESS RULES:
  #   1. Session header displays connection name, session ID, and running status indicator
  #   2. User messages display in purple bubbles with timestamps
  #   3. AI text responses display in labeled message bubbles
  #   4. Thinking blocks are collapsible and show step-by-step reasoning with progress indicators
  #   5. Tool calls display with tool name, status badge, input code block, and output
  #   6. Stream chunks arrive as WebSocket messages with type 'chunk' and must be parsed into typed models
  #   7. Session state changes (Running/Idle/Paused) update the header status indicator
  #   8. Emergency Interrupt button is always visible at the bottom of the screen
  #
  # EXAMPLES:
  #   1. User sends 'Refactor the login logic' and sees it appear in a purple bubble with timestamp
  #   2. AI starts thinking and user sees collapsible 'Thinking Process' block with live progress steps
  #   3. AI runs grep command and user sees TOOL: BASH block with command input and file path output
  #   4. Tool completes and status badge changes from 'running' to 'completed'
  #   5. AI responds with text and user sees labeled 'DevBot' response bubble
  #   6. Session changes from Running to Idle when AI completes response
  #   7. User taps collapsed thinking block and it expands to show all thinking steps
  #   8. New chunks stream in and auto-scroll keeps the latest content visible
  #
  # ========================================

  Background: User Story
    As a developer
    I want to view real-time AI session output on my mobile device
    So that monitor what Claude is doing and follow along with the conversation

  # -------------------------------------------
  # Session Header Display
  # -------------------------------------------

  @smoke
  Scenario: Session header shows connection info and status
    Given I am connected to a relay channel
    And I open a session stream view
    Then I should see the connection name in the header
    And I should see the session ID badge
    And I should see a status indicator showing "Running"

  # -------------------------------------------
  # User Message Display
  # -------------------------------------------

  @smoke
  Scenario: User message appears in purple bubble with timestamp
    Given I am viewing a session stream
    When a user message chunk arrives with text "Refactor the login logic"
    Then I should see the message in a purple bubble
    And I should see a timestamp on the message

  # -------------------------------------------
  # AI Thinking Display
  # -------------------------------------------

  Scenario: Thinking block displays with collapsible steps
    Given I am viewing a session stream
    When a thinking chunk arrives with content "Analyzing request scope"
    Then I should see a "Thinking Process" block
    And the block should show a gear icon
    And I should see the thinking step with a progress indicator

  Scenario: User can expand and collapse thinking block
    Given I am viewing a session stream with a collapsed thinking block
    When I tap on the thinking block header
    Then the block should expand to show all thinking steps
    When I tap on the thinking block header again
    Then the block should collapse

  # -------------------------------------------
  # Tool Call Display
  # -------------------------------------------

  @smoke
  Scenario: Tool call displays with name and input
    Given I am viewing a session stream
    When a tool call chunk arrives for tool "Bash" with input "grep -r \"def login\" ."
    Then I should see a "TOOL: BASH" block
    And I should see the command in a code block
    And I should see a "running" status badge

  Scenario: Tool result updates the tool call display
    Given I am viewing a session stream with a running tool call
    When a tool result chunk arrives with output containing file paths
    Then I should see the output displayed below the input
    And the status badge should change to "completed"

  Scenario: Tool error displays with error styling
    Given I am viewing a session stream with a running tool call
    When a tool result chunk arrives with an error flag
    Then the status badge should show "error"
    And the output should be styled as an error

  # -------------------------------------------
  # AI Response Display
  # -------------------------------------------

  @smoke
  Scenario: AI text response appears in labeled bubble
    Given I am viewing a session stream
    When a text chunk arrives with assistant response "I found the login definition"
    Then I should see the text in a message bubble
    And the bubble should have a label identifying the assistant

  # -------------------------------------------
  # Session State Changes
  # -------------------------------------------

  Scenario: Status indicator updates when session state changes
    Given I am viewing a session stream showing "Running" status
    When a session state change chunk arrives with state "Idle"
    Then the status indicator should change to "Idle"

  Scenario: Status shows Paused when session is paused
    Given I am viewing a session stream showing "Running" status
    When a session state change chunk arrives with state "Paused"
    Then the status indicator should change to "Paused"

  # -------------------------------------------
  # Auto-scroll Behavior
  # -------------------------------------------

  Scenario: New chunks auto-scroll to keep latest visible
    Given I am viewing a session stream at the bottom
    When multiple text chunks arrive in sequence
    Then the view should auto-scroll to show the latest content

  Scenario: Manual scroll up pauses auto-scroll
    Given I am viewing a session stream with auto-scroll active
    When I manually scroll up to view earlier content
    Then auto-scroll should pause
    And I should be able to review earlier messages

  # -------------------------------------------
  # Emergency Interrupt
  # -------------------------------------------

  @smoke
  Scenario: Emergency interrupt button is always visible
    Given I am viewing a session stream
    Then I should see an "Emergency Interrupt" button at the bottom
    And the button should be styled prominently in red
