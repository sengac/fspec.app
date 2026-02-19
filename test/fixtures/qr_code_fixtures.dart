/// Feature: spec/features/add-connection-screen.feature
///
/// QR code test fixtures for Add Connection Screen scenarios.
library;

/// QR code test data for scanner scenarios
class QrCodeFixtures {
  /// Valid QR code with all fields
  /// Used for: "Scanning valid QR code auto-populates all fields"
  static const String validWithAllFields =
      'fspec://connect?n=Work%20MacBook&r=https://relay.fspec.dev&c=abc-123&k=secret-key';

  /// Valid QR code without API key
  /// Used for: "Scanning QR code without API key auto-populates available fields"
  static const String validWithoutApiKey =
      'fspec://connect?n=Home%20Server&r=https://relay.home.dev&c=home-456';

  /// Invalid QR code (not fspec:// scheme)
  /// Used for: "Scanning invalid QR code shows error and stays on scanner"
  static const String invalidScheme = 'https://example.com';

  /// QR code with missing required fields
  /// Used for: "Scanning QR code with missing fields partially fills form"
  static const String partialFields =
      'fspec://connect?n=Partial&r=https://relay.dev';

  /// Expected parsed data for validWithAllFields
  static Map<String, String?> get expectedAllFields => {
        'name': 'Work MacBook',
        'relayUrl': 'https://relay.fspec.dev',
        'channelId': 'abc-123',
        'apiKey': 'secret-key',
      };

  /// Expected parsed data for validWithoutApiKey
  static Map<String, String?> get expectedWithoutApiKey => {
        'name': 'Home Server',
        'relayUrl': 'https://relay.home.dev',
        'channelId': 'home-456',
        'apiKey': null,
      };

  /// Expected parsed data for partialFields
  static Map<String, String?> get expectedPartialFields => {
        'name': 'Partial',
        'relayUrl': 'https://relay.dev',
        'channelId': null,
        'apiKey': null,
      };
}
