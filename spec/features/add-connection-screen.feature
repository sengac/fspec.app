@data-layer
@connection
@MOBILE-002
Feature: Add Connection Screen
  """
  Uses mobile_scanner package for QR code scanning. Form built with Flutter's Form widget and TextFormField validators. Saves via ConnectionRepository from MOBILE-001. Navigation uses go_router.
  """

  # ========================================
  # EXAMPLE MAPPING CONTEXT
  # ========================================
  #
  # BUSINESS RULES:
  #   1. Connection Name is required and cannot be empty
  #   2. Relay Server URL must use https:// scheme
  #   3. Channel ID is required
  #   4. API Key is optional
  #   5. QR code scanner can auto-populate all form fields from desktop
  #   6. API Key field has a visibility toggle (show/hide password)
  #   7. Cancel button returns to previous screen without saving
  #   8. Save button validates form and persists connection if valid
  #   9. URL scheme format: fspec://connect?n=Name&r=RelayURL&c=ChannelID&k=APIKey (k is optional)
  #   10. Invalid QR shows toast and stays on scanner. Missing fields partially fill form with toast to complete manually. Camera denied shows Settings button. Manual entry is always the fallback.
  #
  # EXAMPLES:
  #   1. User enters 'Work MacBook', 'https://relay.fspec.dev', channel 'abc-123' and taps Save - connection is created and user returns to connections list
  #   2. User scans QR code from desktop CLI - all fields auto-populate with connection details
  #   3. User leaves Connection Name empty and taps Save - sees validation error 'Connection name is required'
  #   4. User enters 'http://relay.example.com' as URL and taps Save - sees validation error 'URL must use https'
  #   5. User leaves Channel ID empty and taps Save - sees validation error 'Channel ID is required'
  #   6. User fills form without API key and saves - connection is created successfully (API key optional)
  #   7. User taps Cancel button - returns to previous screen without creating connection
  #   8. User taps eye icon on API Key field - toggles between hidden (dots) and visible text
  #
  # QUESTIONS (ANSWERED):
  #   Q: What format is the QR code data? JSON with fields, or a URL scheme?
  #   A: URL scheme format: fspec://connect?n=Name&r=RelayURL&c=ChannelID&k=APIKey (k is optional)
  #
  #   Q: Should there be a 'Test Connection' button to verify connectivity before saving?
  #   A: No - just Cancel and Save buttons. Connection testing happens elsewhere.
  #
  #   Q: What happens if QR code scan fails or contains invalid data?
  #   A: Invalid QR shows toast and stays on scanner. Missing fields partially fill form with toast to complete manually. Camera denied shows Settings button. Manual entry is always the fallback.
  #
  # ========================================
  Background: User Story
    Given I am on the Add Connection screen

  # Happy Path - Manual Entry
  @happy-path
  Scenario: Creating connection with all required fields succeeds
    When I enter "Work MacBook" in the Connection Name field
    And I enter "https://relay.fspec.dev" in the Relay Server URL field
    And I enter "abc-123" in the Channel ID field
    And I tap the Save button
    Then the connection should be saved
    And I should be returned to the connections list

  @happy-path
  Scenario: Creating connection without API key succeeds
    When I enter "Personal Laptop" in the Connection Name field
    And I enter "https://relay.example.com" in the Relay Server URL field
    And I enter "xyz-789" in the Channel ID field
    And I tap the Save button
    Then the connection should be saved
    And I should be returned to the connections list

  # QR Code Scanner
  @qr-scanner
  Scenario: Scanning valid QR code auto-populates all fields
    When I tap the Scan QR Code button
    And I scan a QR code containing "fspec://connect?n=Work%20MacBook&r=https://relay.fspec.dev&c=abc-123&k=secret-key"
    Then the Connection Name field should contain "Work MacBook"
    And the Relay Server URL field should contain "https://relay.fspec.dev"
    And the Channel ID field should contain "abc-123"
    And the API Key field should contain "secret-key"

  @qr-scanner
  Scenario: Scanning QR code without API key auto-populates available fields
    When I tap the Scan QR Code button
    And I scan a QR code containing "fspec://connect?n=Home%20Server&r=https://relay.home.dev&c=home-456"
    Then the Connection Name field should contain "Home Server"
    And the Relay Server URL field should contain "https://relay.home.dev"
    And the Channel ID field should contain "home-456"
    And the API Key field should be empty

  @qr-scanner
  @error-handling
  Scenario: Scanning invalid QR code shows error and stays on scanner
    When I tap the Scan QR Code button
    And I scan a QR code containing "https://example.com"
    Then I should see a toast message "Not a valid fspec connection code"
    And I should remain on the QR scanner

  @qr-scanner
  @error-handling
  Scenario: Scanning QR code with missing fields partially fills form
    When I tap the Scan QR Code button
    And I scan a QR code containing "fspec://connect?n=Partial&r=https://relay.dev"
    Then the Connection Name field should contain "Partial"
    And the Relay Server URL field should contain "https://relay.dev"
    And the Channel ID field should be empty
    And I should see a toast message "Some fields couldn't be read. Please complete manually."

  @qr-scanner
  @permissions
  Scenario: Camera permission denied shows settings option
    Given camera permission is denied
    When I tap the Scan QR Code button
    Then I should see a camera permission explanation
    And I should see an "Open Settings" button

  # Validation Errors
  @validation
  Scenario: Empty connection name shows validation error
    When I leave the Connection Name field empty
    And I enter "https://relay.fspec.dev" in the Relay Server URL field
    And I enter "abc-123" in the Channel ID field
    And I tap the Save button
    Then I should see a validation error "Connection name is required"
    And the connection should not be saved

  @validation
  Scenario: HTTP URL shows validation error
    When I enter "Work MacBook" in the Connection Name field
    And I enter "http://relay.example.com" in the Relay Server URL field
    And I enter "abc-123" in the Channel ID field
    And I tap the Save button
    Then I should see a validation error "URL must use https"
    And the connection should not be saved

  @validation
  Scenario: Empty channel ID shows validation error
    When I enter "Work MacBook" in the Connection Name field
    And I enter "https://relay.fspec.dev" in the Relay Server URL field
    And I leave the Channel ID field empty
    And I tap the Save button
    Then I should see a validation error "Channel ID is required"
    And the connection should not be saved

  # Cancel Action
  @navigation
  Scenario: Cancel button returns to previous screen without saving
    When I enter "Work MacBook" in the Connection Name field
    And I tap the Cancel button
    Then I should be returned to the previous screen
    And no connection should be saved

  # API Key Visibility Toggle
  @ui
  Scenario: API key visibility can be toggled
    When I enter "my-secret-key" in the API Key field
    Then the API Key field should be obscured
    When I tap the visibility toggle on the API Key field
    Then the API Key field should show "my-secret-key"
    When I tap the visibility toggle on the API Key field
    Then the API Key field should be obscured
