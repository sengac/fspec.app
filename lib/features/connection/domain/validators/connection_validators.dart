/// Connection Form Validators
///
/// Extracted validators for Add Connection form fields.
/// Provides consistent validation across the app.
library;

/// Validates connection name field
///
/// Returns null if valid, or error message if invalid.
/// Rule: Connection Name is required and cannot be empty
String? validateConnectionName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Connection name is required';
  }
  return null;
}

/// Validates relay server URL field
///
/// Returns null if valid, or error message if invalid.
/// Rules:
/// - Relay Server URL is required
/// - URL must use https:// scheme
String? validateRelayUrl(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Relay URL is required';
  }
  if (!value.toLowerCase().startsWith('https://')) {
    return 'URL must use https';
  }
  return null;
}

/// Validates channel ID field
///
/// Returns null if valid, or error message if invalid.
/// Rule: Channel ID is required
String? validateChannelId(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Channel ID is required';
  }
  return null;
}
