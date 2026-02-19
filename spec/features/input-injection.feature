@done
@ui-layer
@session
@MOBILE-008
Feature: Input Injection

  """
  WebSocketManager.sendInput() already exists - accepts message and optional images array
  Use image_picker package for camera/gallery access
  Create InputBarWidget at bottom of SessionStreamScreen body Column
  """

  # ========================================
  # EXAMPLE MAPPING CONTEXT
  # ========================================
  #
  # BUSINESS RULES:
  #   1. Input field appears at the bottom of the session stream view
  #   2. Text messages are sent via the 'input' message type to the relay
  #   3. Send button is enabled only when text field is not empty
  #   4. Camera icon opens platform image picker (camera or gallery)
  #   5. Images are base64-encoded with media type before sending
  #   6. Input field clears after successful send
  #   7. Keyboard adjusts layout so input field remains visible
  #
  # EXAMPLES:
  #   1. User types 'Implement the login feature' and taps send → message appears in stream and relay receives input message
  #   2. User taps camera icon → image picker appears with camera and gallery options
  #   3. User selects photo and types description → both image (base64) and text sent to relay
  #   4. User with empty text field sees disabled send button
  #   5. User opens keyboard → input field scrolls up to remain visible above keyboard
  #   6. User attaches multiple images → thumbnail preview shows all selected images
  #   7. User taps X on image thumbnail → image removed from pending attachments
  #
  # ========================================

  Background: User Story
    As a mobile user
    I want to send text messages and images to an active fspec session
    So that communicate with the AI and provide context

  # ===========================================
  # TEXT INPUT SCENARIOS
  # ===========================================

  Scenario: Send text message to session
    Given I am viewing an active session stream
    And the input field is displayed at the bottom of the screen
    When I type "Implement the login feature"
    And I tap the send button
    Then the message should appear in the stream
    And the input message should be sent to the relay

  Scenario: Send button disabled for empty input
    Given I am viewing an active session stream
    And the input field is empty
    Then the send button should be disabled

  Scenario: Input field clears after sending
    Given I am viewing an active session stream
    And I have typed a message in the input field
    When I tap the send button
    Then the input field should be cleared

  # ===========================================
  # IMAGE ATTACHMENT SCENARIOS
  # ===========================================

  Scenario: Open image picker
    Given I am viewing an active session stream
    When I tap the camera icon
    Then the image picker should appear
    And I should see options for camera and gallery

  Scenario: Attach and send image with description
    Given I am viewing an active session stream
    And I have attached an image "screenshot.png"
    When I type "Here is the error screenshot"
    And I tap the send button
    Then the input message should be sent to the relay with image data
    And the image should be base64-encoded with media type

  Scenario: Preview multiple attached images
    Given I am viewing an active session stream
    And I have attached multiple images
    Then I should see thumbnail previews of all attached images
    And each thumbnail should show the image content

  Scenario: Remove attached image before sending
    Given I am viewing an active session stream
    And I have attached an image "screenshot.png"
    When I tap the X button on the image thumbnail
    Then the image should be removed from pending attachments
    And the image preview row should no longer show that image

  # ===========================================
  # KEYBOARD BEHAVIOR
  # ===========================================

  Scenario: Keyboard adjusts layout
    Given I am viewing an active session stream
    When I tap the input field to open the keyboard
    Then the input field should remain visible above the keyboard
