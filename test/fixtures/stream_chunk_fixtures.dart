/// Fixtures for session stream display tests.
///
/// Provides sample stream chunk data for testing the session stream screen.
/// NOTE: For connected Connection instances, use ConnectionFixtures.connectedInstance()
library;

/// Fixtures for stream chunk WebSocket message data
class StreamChunkFixtures {
  /// User message chunk
  static Map<String, dynamic> userMessageChunk({
    String? content,
    String? sessionId,
  }) {
    return {
      'type': 'chunk',
      'session_id': sessionId ?? 'AUTH-001',
      'data': {
        'chunkType': 'userMessage',
        'content': content ?? 'Refactor the login logic',
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Text response chunk from AI
  static Map<String, dynamic> textChunk({
    String? content,
    String? sessionId,
  }) {
    return {
      'type': 'chunk',
      'session_id': sessionId ?? 'AUTH-001',
      'data': {
        'chunkType': 'text',
        'content': content ?? 'I found the login definition',
      },
    };
  }

  /// Thinking chunk
  static Map<String, dynamic> thinkingChunk({
    String? content,
    String? sessionId,
  }) {
    return {
      'type': 'chunk',
      'session_id': sessionId ?? 'AUTH-001',
      'data': {
        'chunkType': 'thinking',
        'content': content ?? 'Analyzing request scope',
      },
    };
  }

  /// Tool call chunk
  static Map<String, dynamic> toolCallChunk({
    String? id,
    String? name,
    String? input,
    String? sessionId,
  }) {
    return {
      'type': 'chunk',
      'session_id': sessionId ?? 'AUTH-001',
      'data': {
        'chunkType': 'toolCall',
        'id': id ?? 'tool-call-1',
        'name': name ?? 'Bash',
        'input': input ?? 'grep -r "def login" .',
      },
    };
  }

  /// Tool result chunk
  static Map<String, dynamic> toolResultChunk({
    String? toolCallId,
    String? content,
    bool isError = false,
    String? sessionId,
  }) {
    return {
      'type': 'chunk',
      'session_id': sessionId ?? 'AUTH-001',
      'data': {
        'chunkType': 'toolResult',
        'toolCallId': toolCallId ?? 'tool-call-1',
        'content': content ?? './app/controllers/auth_controller.rb:45: def login',
        'isError': isError,
      },
    };
  }

  /// Tool progress chunk (streaming bash output)
  static Map<String, dynamic> toolProgressChunk({
    String? content,
    String? sessionId,
  }) {
    return {
      'type': 'chunk',
      'session_id': sessionId ?? 'AUTH-001',
      'data': {
        'chunkType': 'toolProgress',
        'content': content ?? 'Searching files...',
      },
    };
  }

  /// Session state change chunk
  static Map<String, dynamic> sessionStateChangeChunk({
    String? state,
    String? sessionId,
  }) {
    return {
      'type': 'chunk',
      'session_id': sessionId ?? 'AUTH-001',
      'data': {
        'chunkType': 'sessionStateChange',
        'state': state ?? 'Running',
      },
    };
  }

  /// Done chunk (stream completed)
  static Map<String, dynamic> doneChunk({String? sessionId}) {
    return {
      'type': 'chunk',
      'session_id': sessionId ?? 'AUTH-001',
      'data': {
        'chunkType': 'done',
      },
    };
  }

  /// Error chunk
  static Map<String, dynamic> errorChunk({
    String? message,
    String? sessionId,
  }) {
    return {
      'type': 'chunk',
      'session_id': sessionId ?? 'AUTH-001',
      'data': {
        'chunkType': 'error',
        'message': message ?? 'An error occurred',
      },
    };
  }

  /// Sequence of chunks simulating a typical conversation
  static List<Map<String, dynamic>> typicalConversationSequence() {
    return [
      sessionStateChangeChunk(state: 'Running'),
      userMessageChunk(content: 'Refactor the login logic'),
      thinkingChunk(content: 'Analyzing request scope for login logic refactor'),
      thinkingChunk(content: 'Locating auth_controller.rb'),
      toolCallChunk(
        name: 'Bash',
        input: 'grep -r "def login" .',
      ),
      toolProgressChunk(content: 'Searching...'),
      toolResultChunk(
        content: './app/controllers/auth_controller.rb:45: def login\n'
            './spec/controllers/auth_controller_spec.rb: def login_helper',
      ),
      textChunk(
        content: 'I found the login definition in auth_controller.rb. '
            'I will now extract the validation logic into a private method',
      ),
      sessionStateChangeChunk(state: 'Idle'),
    ];
  }
}
