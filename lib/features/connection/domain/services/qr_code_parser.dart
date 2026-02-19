/// QR Code Parser Service
///
/// Parses fspec:// connection URLs from QR codes.
/// URL format: fspec://connect?n=Name&r=RelayURL&c=ChannelID&k=APIKey
library;

/// Result of parsing a QR code
class QrCodeParseResult {
  final String? name;
  final String? relayUrl;
  final String? channelId;
  final String? apiKey;
  final String? error;
  final bool isValid;
  final bool isPartial;

  const QrCodeParseResult._({
    this.name,
    this.relayUrl,
    this.channelId,
    this.apiKey,
    this.error,
    required this.isValid,
    required this.isPartial,
  });

  /// Create a successful parse result
  factory QrCodeParseResult.success({
    required String name,
    required String relayUrl,
    required String channelId,
    String? apiKey,
  }) {
    return QrCodeParseResult._(
      name: name,
      relayUrl: relayUrl,
      channelId: channelId,
      apiKey: apiKey,
      isValid: true,
      isPartial: false,
    );
  }

  /// Create a partial parse result (some fields missing)
  factory QrCodeParseResult.partial({
    String? name,
    String? relayUrl,
    String? channelId,
    String? apiKey,
  }) {
    return QrCodeParseResult._(
      name: name,
      relayUrl: relayUrl,
      channelId: channelId,
      apiKey: apiKey,
      isValid: true,
      isPartial: true,
    );
  }

  /// Create an error parse result
  factory QrCodeParseResult.error(String message) {
    return QrCodeParseResult._(
      error: message,
      isValid: false,
      isPartial: false,
    );
  }

  /// Message to show when partial data was parsed
  String? get partialMessage =>
      isPartial ? "Some fields couldn't be read. Please complete manually." : null;
}

/// Static parser for fspec:// QR codes
class QrCodeParser {
  QrCodeParser._();

  static const String _scheme = 'fspec';
  static const String _host = 'connect';

  /// Parse a QR code string into connection data
  ///
  /// Expected format: fspec://connect?n=Name&r=RelayURL&c=ChannelID&k=APIKey
  /// - n: Connection name (required, URL encoded)
  /// - r: Relay URL (required, URL encoded)
  /// - c: Channel ID (required)
  /// - k: API key (optional)
  static QrCodeParseResult parse(String qrData) {
    // Try to parse as URI
    final Uri? uri;
    try {
      uri = Uri.parse(qrData);
    } catch (_) {
      return QrCodeParseResult.error('Not a valid fspec connection code');
    }

    // Validate scheme
    if (uri.scheme != _scheme) {
      return QrCodeParseResult.error('Not a valid fspec connection code');
    }

    // Validate host
    if (uri.host != _host) {
      return QrCodeParseResult.error('Not a valid fspec connection code');
    }

    // Extract parameters
    final params = uri.queryParameters;
    final name = params['n'];
    final relayUrl = params['r'];
    final channelId = params['c'];
    final apiKey = params['k'];

    // Check if all required fields are present
    if (name != null &&
        name.isNotEmpty &&
        relayUrl != null &&
        relayUrl.isNotEmpty &&
        channelId != null &&
        channelId.isNotEmpty) {
      return QrCodeParseResult.success(
        name: name,
        relayUrl: relayUrl,
        channelId: channelId,
        apiKey: apiKey,
      );
    }

    // Check if we have any data at all
    final hasAnyData =
        (name != null && name.isNotEmpty) ||
        (relayUrl != null && relayUrl.isNotEmpty) ||
        (channelId != null && channelId.isNotEmpty);

    if (hasAnyData) {
      return QrCodeParseResult.partial(
        name: name?.isNotEmpty == true ? name : null,
        relayUrl: relayUrl?.isNotEmpty == true ? relayUrl : null,
        channelId: channelId?.isNotEmpty == true ? channelId : null,
        apiKey: apiKey?.isNotEmpty == true ? apiKey : null,
      );
    }

    return QrCodeParseResult.error('Not a valid fspec connection code');
  }
}
