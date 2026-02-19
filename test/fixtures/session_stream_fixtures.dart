/// Fixtures for session stream tests.
///
/// Provides reusable FakeSessionStreamNotifier and test widget factory
/// for session-related tests (stream display, input injection, etc.)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fspec_mobile/features/connection/data/providers/connection_providers.dart';
import 'package:fspec_mobile/features/connection/data/services/relay_connection_service.dart';
import 'package:fspec_mobile/features/connection/domain/repositories/connection_repository_interface.dart';
import 'package:fspec_mobile/features/session/data/models/session_stream_state.dart';
import 'package:fspec_mobile/features/session/data/models/stream_chunk.dart';
import 'package:fspec_mobile/features/session/data/providers/session_stream_providers.dart';
import 'package:fspec_mobile/features/session/presentation/screens/session_stream_screen.dart';
import 'package:go_router/go_router.dart';

/// Fake notifier for testing session stream state.
///
/// Used by both session stream display tests and input injection tests.
/// Provides full control over state for widget testing.
class FakeSessionStreamNotifier extends SessionStream {
  final SessionStreamState _initialState;
  final void Function(StreamChunk)? onChunkAdded;

  FakeSessionStreamNotifier(
    this._initialState, {
    this.onChunkAdded,
  });

  @override
  SessionStreamState build(String connectionId, String sessionId) {
    return _initialState;
  }

  /// Add a chunk to the stream (for testing state changes)
  void addChunk(StreamChunk chunk) {
    onChunkAdded?.call(chunk);

    chunk.when(
      text: (content, id) {
        state = state.copyWith(
          displayItems: [
            ...state.displayItems,
            StreamDisplayItem.assistantText(
              chunk: TextChunk(content: content, id: id),
            ),
          ],
        );
      },
      thinking: (content, id) {
        final items = [...state.displayItems];
        final lastIndex = items.length - 1;

        if (lastIndex >= 0 && items[lastIndex] is ThinkingDisplayItem) {
          final existing = items[lastIndex] as ThinkingDisplayItem;
          items[lastIndex] = StreamDisplayItem.thinking(
            chunks: [
              ...existing.chunks,
              ThinkingChunk(content: content, id: id),
            ],
            isExpanded: existing.isExpanded,
          );
        } else {
          items.add(StreamDisplayItem.thinking(
            chunks: [ThinkingChunk(content: content, id: id)],
          ));
        }
        state = state.copyWith(displayItems: items);
      },
      toolCall: (toolCallId, name, input, status) {
        state = state.copyWith(
          displayItems: [
            ...state.displayItems,
            StreamDisplayItem.toolCall(
              toolCall: ToolCallWithResult(
                toolCall: ToolCallChunk(
                  toolCallId: toolCallId,
                  name: name,
                  input: input,
                  status: status,
                ),
              ),
            ),
          ],
        );
      },
      toolResult: (toolCallId, content, isError) {
        final items = state.displayItems.map((item) {
          if (item is ToolCallDisplayItem &&
              item.toolCall.toolCall.toolCallId == toolCallId) {
            return StreamDisplayItem.toolCall(
              toolCall: ToolCallWithResult(
                toolCall: item.toolCall.toolCall,
                result: ToolResultChunk(
                  toolCallId: toolCallId,
                  content: content,
                  isError: isError,
                ),
              ),
            );
          }
          return item;
        }).toList();
        state = state.copyWith(displayItems: items);
      },
      toolProgress: (content) {
        // Handle tool progress - no state change needed
      },
      sessionStateChange: (sessionState) {
        state = state.copyWith(sessionState: sessionState);
      },
      userMessage: (content, timestamp) {
        state = state.copyWith(
          displayItems: [
            ...state.displayItems,
            StreamDisplayItem.userMessage(
              chunk: UserMessageChunk(content: content, timestamp: timestamp),
            ),
          ],
        );
      },
      done: () {
        state = state.copyWith(sessionState: SessionState.idle);
      },
      error: (message) {
        state = state.copyWith(
          displayItems: [
            ...state.displayItems,
            StreamDisplayItem.error(chunk: ErrorChunk(message: message)),
          ],
        );
      },
    );
  }

  @override
  void toggleThinkingBlock(int index) {
    final items = [...state.displayItems];
    final item = items[index];

    if (item is ThinkingDisplayItem) {
      items[index] = StreamDisplayItem.thinking(
        chunks: item.chunks,
        isExpanded: !item.isExpanded,
      );
      state = state.copyWith(displayItems: items);
    }
  }

  @override
  void pauseAutoScroll() {
    state = state.copyWith(autoScrollEnabled: false);
  }

  @override
  void resumeAutoScroll() {
    state = state.copyWith(autoScrollEnabled: true);
  }
}

/// Factory for creating session stream test widgets.
///
/// Handles common setup: ProviderScope, GoRouter, provider overrides.
class SessionStreamTestFactory {
  final IConnectionRepository repository;
  final RelayConnectionService relayService;

  late FakeSessionStreamNotifier notifier;

  SessionStreamTestFactory({
    required this.repository,
    required this.relayService,
  });

  /// Create a test widget with SessionStreamScreen.
  Widget createSessionStreamWidget({
    required String connectionId,
    required String sessionId,
    SessionStreamState? initialState,
    GoRouter? router,
  }) {
    final state = initialState ??
        SessionStreamState(
          connectionName: 'MacBook Pro',
          sessionId: sessionId,
          sessionState: SessionState.running,
        );

    notifier = FakeSessionStreamNotifier(state);

    final testRouter = router ??
        GoRouter(
          initialLocation: '/session/$connectionId/$sessionId',
          routes: [
            GoRoute(
              path: '/session/:connectionId/:sessionId',
              builder: (context, routerState) => SessionStreamScreen(
                connectionId: routerState.pathParameters['connectionId']!,
                sessionId: routerState.pathParameters['sessionId']!,
              ),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        connectionRepositoryProvider.overrideWithValue(repository),
        relayConnectionServiceProvider.overrideWithValue(relayService),
        sessionStreamProvider(connectionId, sessionId)
            .overrideWith(() => notifier),
      ],
      child: MaterialApp.router(
        routerConfig: testRouter,
      ),
    );
  }
}
