/// Fake Relay Server for Manual Testing
///
/// A standalone WebSocket server that simulates the fspec relay protocol.
/// Supports: auth handshake, board commands, work unit details,
/// session streaming with mock AI output, input injection, and session control.
///
/// Usage:
///   dart run tools/fake_relay_server.dart [port]
///
/// Default port: 8765
/// Connect with: ws://localhost:8765

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main(List<String> args) async {
  final port = args.isNotEmpty ? int.parse(args[0]) : 8765;
  final server = await FakeRelayServer.start(port);
  
  print('🚀 Fake Relay Server running on ws://localhost:$port');
  print('');
  print('Add a connection in the app:');
  print('  Name: Local Dev Server');
  print('  Relay URL: http://localhost:$port');
  print('  Channel ID: dev-channel');
  print('  API Key: (leave empty)');
  print('');
  print('Press Ctrl+C to stop');
  
  // Keep running until interrupted
  await ProcessSignal.sigint.watch().first;
  await server.stop();
  print('\n👋 Server stopped');
}

class FakeRelayServer {
  final HttpServer _httpServer;
  final Set<WebSocket> _clients = {};
  final Map<WebSocket, String> _authenticatedChannels = {};
  final Map<String, StreamController<void>> _sessionInterrupts = {};
  
  FakeRelayServer._(this._httpServer);
  
  static Future<FakeRelayServer> start(int port) async {
    final httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
    final server = FakeRelayServer._(httpServer);
    server._listen();
    return server;
  }
  
  Future<void> stop() async {
    for (final client in _clients) {
      await client.close();
    }
    await _httpServer.close();
  }
  
  void _listen() {
    _httpServer.listen((request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _handleClient(socket);
      } else {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.text
          ..write('Fake Relay Server - Use WebSocket connection')
          ..close();
      }
    });
  }
  
  void _handleClient(WebSocket socket) {
    _clients.add(socket);
    print('📱 Client connected (${_clients.length} total)');
    
    socket.listen(
      (data) => _handleMessage(socket, data as String),
      onDone: () {
        _clients.remove(socket);
        _authenticatedChannels.remove(socket);
        print('📱 Client disconnected (${_clients.length} remaining)');
      },
      onError: (error) {
        print('❌ WebSocket error: $error');
        _clients.remove(socket);
        _authenticatedChannels.remove(socket);
      },
    );
  }
  
  void _handleMessage(WebSocket socket, String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final type = json['type'] as String;
      
      print('📨 Received: $type');
      
      switch (type) {
        case 'auth':
          _handleAuth(socket, json);
        case 'command':
          _handleCommand(socket, json);
        case 'input':
          _handleInput(socket, json);
        case 'sessionControl':
          _handleSessionControl(socket, json);
        case 'ping':
          _handlePing(socket, json);
        default:
          print('   Unknown message type: $type');
      }
    } catch (e) {
      print('❌ Error parsing message: $e');
    }
  }
  
  void _handleAuth(WebSocket socket, Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final channelId = data['channel_id'] as String;
    
    print('   Channel: $channelId');
    
    // Always succeed auth for fake server
    _authenticatedChannels[socket] = channelId;
    
    socket.add(jsonEncode({
      'type': 'authSuccess',
      'data': {
        'instances': [
          {
            'instance_id': 'fake-instance-1',
            'project_name': 'fspec-mobile',
            'online': true,
          },
          {
            'instance_id': 'fake-instance-2', 
            'project_name': 'my-other-project',
            'online': true,
          },
        ],
      },
    }));
    
    print('   ✅ Auth success sent');
  }
  
  void _handleCommand(WebSocket socket, Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final command = data['command'] as String;
    final requestId = json['request_id'] as String?;
    final instanceId = json['instance_id'] as String?;
    
    print('   Command: $command (request: $requestId)');
    
    final result = switch (command) {
      'board' => _getBoardResponse(),
      'show-work-unit' => _getWorkUnitDetailResponse(data['args'] as Map<String, dynamic>?),
      _ => {'success': false, 'error': 'Unknown command: $command'},
    };
    
    socket.add(jsonEncode({
      'type': 'commandResponse',
      'request_id': requestId,
      'instance_id': instanceId,
      'data': {
        'command': command,
        'result': result,
      },
    }));
    
    print('   ✅ Response sent');
  }
  
  Map<String, dynamic> _getBoardResponse() {
    return {
      'success': true,
      'columns': {
        'backlog': [
          {'id': 'AUTH-001', 'title': 'Implement OAuth2 login flow', 'type': 'story', 'estimate': 5},
          {'id': 'UI-002', 'title': 'Fix dark mode contrast', 'type': 'bug', 'estimate': 3},
          {'id': 'API-003', 'title': 'Update API schema', 'type': 'task', 'estimate': 2},
        ],
        'specifying': [
          {'id': 'SPEC-001', 'title': 'Design biometric login', 'type': 'story', 'estimate': 5},
        ],
        'testing': [
          {'id': 'TEST-001', 'title': 'Write integration tests', 'type': 'task', 'estimate': 3},
        ],
        'implementing': [
          {'id': 'IMPL-001', 'title': 'Build dashboard widget', 'type': 'story', 'estimate': 8},
        ],
        'validating': [],
        'done': [
          {'id': 'DONE-001', 'title': 'Setup project structure', 'type': 'task', 'estimate': 1},
          {'id': 'DONE-002', 'title': 'Configure CI/CD', 'type': 'task', 'estimate': 2},
        ],
        'blocked': [
          {'id': 'BLOCK-001', 'title': 'Waiting for API docs', 'type': 'story', 'estimate': 8},
        ],
      },
      'summary': '16 points in progress, 3 points completed',
    };
  }
  
  Map<String, dynamic> _getWorkUnitDetailResponse(Map<String, dynamic>? args) {
    final workUnitId = args?['_']?.first as String? ?? 'AUTH-001';
    
    return {
      'success': true,
      'id': workUnitId,
      'title': 'Implement Biometric Login',
      'type': 'story',
      'status': 'specifying',
      'estimate': 5,
      'userStory': {
        'role': 'mobile user',
        'action': 'log in using FaceID',
        'benefit': 'I can access my account quickly without typing a password',
      },
      'rules': [
        {'index': 0, 'text': 'Must fallback to PIN or Password if FaceID biometrics fail.', 'deleted': false},
        {'index': 1, 'text': 'Biometrics only enabled after initial successful password login.', 'deleted': false},
      ],
      'examples': [
        {'index': 0, 'text': 'User enables FaceID in settings, next app launch prompts for FaceID.', 'type': 'HAPPY PATH', 'deleted': false},
        {'index': 1, 'text': 'User changes system face data -> App forces password login once.', 'type': 'EDGE CASE', 'deleted': false},
      ],
      'questions': [
        {'index': 0, 'text': 'What is the max retry count before we force PIN entry? @security-team', 'answer': null, 'deleted': false},
      ],
      'architectureNotes': [
        'Uses LocalAuthentication framework for biometric APIs',
        'Stores biometric enrollment state in secure enclave',
      ],
    };
  }
  
  void _handleInput(WebSocket socket, Map<String, dynamic> json) {
    final sessionId = json['session_id'] as String?;
    final data = json['data'] as Map<String, dynamic>;
    final message = data['message'] as String;
    final images = data['images'] as List<dynamic>?;
    
    print('   Session: $sessionId');
    print('   Message: $message');
    if (images != null && images.isNotEmpty) {
      print('   Images: ${images.length} attached');
    }
    
    // Stream a fake AI response
    _streamFakeResponse(socket, sessionId ?? 'unknown', message);
  }
  
  Future<void> _streamFakeResponse(WebSocket socket, String sessionId, String userMessage) async {
    // Create interrupt controller for this session
    final interruptController = StreamController<void>.broadcast();
    _sessionInterrupts[sessionId] = interruptController;
    
    bool interrupted = false;
    interruptController.stream.listen((_) {
      interrupted = true;
      print('   🛑 Session $sessionId interrupted');
    });
    
    try {
      // Send session state: Running
      _sendChunk(socket, sessionId, {'chunkType': 'sessionStateChange', 'state': 'Running'});
      
      // Echo user message
      _sendChunk(socket, sessionId, {
        'chunkType': 'userMessage',
        'content': userMessage,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      if (interrupted) return;
      
      // Send thinking
      final thinkingPhrases = [
        'Analyzing the request...',
        'Looking at the codebase structure...',
        'Considering the best approach...',
      ];
      
      for (final phrase in thinkingPhrases) {
        if (interrupted) return;
        _sendChunk(socket, sessionId, {'chunkType': 'thinking', 'content': phrase});
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      if (interrupted) return;
      
      // Simulate a tool call
      _sendChunk(socket, sessionId, {
        'chunkType': 'toolCall',
        'id': 'tool-${Random().nextInt(10000)}',
        'name': 'Bash',
        'input': 'find . -name "*.dart" | head -5',
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (interrupted) return;
      
      // Tool progress
      _sendChunk(socket, sessionId, {'chunkType': 'toolProgress', 'content': 'Searching files...'});
      
      await Future.delayed(const Duration(milliseconds: 300));
      if (interrupted) return;
      
      // Tool result
      _sendChunk(socket, sessionId, {
        'chunkType': 'toolResult',
        'toolCallId': 'tool-${Random().nextInt(10000)}',
        'content': '''./lib/main.dart
./lib/app.dart
./lib/core/websocket/websocket_manager.dart
./lib/features/session/presentation/screens/session_stream_screen.dart
./lib/features/board/presentation/screens/board_screen.dart''',
        'isError': false,
      });
      
      await Future.delayed(const Duration(milliseconds: 400));
      if (interrupted) return;
      
      // Send text response in chunks
      final response = _generateResponse(userMessage);
      final words = response.split(' ');
      
      for (var i = 0; i < words.length; i += 3) {
        if (interrupted) return;
        final chunk = words.skip(i).take(3).join(' ') + ' ';
        _sendChunk(socket, sessionId, {'chunkType': 'text', 'content': chunk});
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Send done
      _sendChunk(socket, sessionId, {'chunkType': 'done'});
      
      // Send session state: Idle
      _sendChunk(socket, sessionId, {'chunkType': 'sessionStateChange', 'state': 'Idle'});
      
      print('   ✅ Response stream complete');
    } finally {
      _sessionInterrupts.remove(sessionId);
      await interruptController.close();
    }
  }
  
  String _generateResponse(String userMessage) {
    final responses = [
      "I've analyzed your request and found several relevant files in the codebase. The main entry point is in lib/main.dart, which sets up the Flutter application. Let me know if you'd like me to make any changes.",
      "Based on my analysis, I can see the project structure follows a clean architecture pattern with features organized into data, domain, and presentation layers. The WebSocket connection is handled in the core module.",
      "I found what you're looking for! The implementation uses Riverpod for state management and GoRouter for navigation. Would you like me to explain any specific part in more detail?",
      "Great question! The session streaming feature is implemented using StreamControllers and processes chunks from the WebSocket connection. Each chunk type (text, thinking, toolCall, etc.) is handled separately.",
    ];
    
    return responses[Random().nextInt(responses.length)];
  }
  
  void _sendChunk(WebSocket socket, String sessionId, Map<String, dynamic> chunkData) {
    socket.add(jsonEncode({
      'type': 'chunk',
      'session_id': sessionId,
      'data': chunkData,
    }));
  }
  
  void _handleSessionControl(WebSocket socket, Map<String, dynamic> json) {
    final sessionId = json['session_id'] as String?;
    final data = json['data'] as Map<String, dynamic>;
    final action = data['action'] as String;
    
    print('   Session: $sessionId');
    print('   Action: $action');
    
    switch (action) {
      case 'interrupt':
        // Trigger interrupt for this session
        _sessionInterrupts[sessionId]?.add(null);
        print('   🛑 Interrupt signal sent');
      case 'clear':
        print('   🗑️ Clear session (no-op for fake server)');
      default:
        print('   Unknown action: $action');
    }
    
    // Session control is fire-and-forget, no response needed
  }
  
  void _handlePing(WebSocket socket, Map<String, dynamic> json) {
    socket.add(jsonEncode({
      'type': 'pong',
      'data': {'timestamp': DateTime.now().millisecondsSinceEpoch},
    }));
  }
}
