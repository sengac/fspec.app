/// Session stream screen.
///
/// Main screen for displaying real-time AI session output.
/// Shows StreamChunks with auto-scroll and session controls.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/session_stream_state.dart';
import '../../data/providers/session_stream_providers.dart';
import '../widgets/assistant_message_bubble.dart';
import '../widgets/emergency_interrupt_button.dart';
import '../widgets/input_bar.dart';
import '../widgets/session_header.dart';
import '../widgets/thinking_block.dart';
import '../widgets/tool_call_card.dart';
import '../widgets/user_message_bubble.dart';
import '../../../../core/websocket/websocket_manager.dart';
import '../../../connection/data/services/relay_connection_service.dart';
import '../../../connection/data/providers/connection_providers.dart';

/// Session stream screen displaying real-time AI output
class SessionStreamScreen extends ConsumerStatefulWidget {
  final String connectionId;
  final String sessionId;

  const SessionStreamScreen({
    super.key,
    required this.connectionId,
    required this.sessionId,
  });

  @override
  ConsumerState<SessionStreamScreen> createState() =>
      _SessionStreamScreenState();
}

class _SessionStreamScreenState extends ConsumerState<SessionStreamScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isAtBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;

    if (isAtBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = isAtBottom;
      });

      final notifier = ref.read(
        sessionStreamProvider(widget.connectionId, widget.sessionId).notifier,
      );

      if (isAtBottom) {
        notifier.resumeAutoScroll();
      } else {
        notifier.pauseAutoScroll();
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleInterrupt() {
    final service = ref.read(relayConnectionServiceProvider);
    final manager = service.getManager(widget.connectionId);
    manager?.sendSessionControl(
      sessionId: widget.sessionId,
      action: 'interrupt',
    );
  }

  void _handleClearSession() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('clear_session_dialog'),
        title: const Text('Clear Session?'),
        content: const Text(
          'This will clear the current session. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            key: const Key('cancel_clear_button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm_clear_button'),
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        final service = ref.read(relayConnectionServiceProvider);
        final manager = service.getManager(widget.connectionId);
        manager?.sendSessionControl(
          sessionId: widget.sessionId,
          action: 'clear',
        );
      }
    });
  }

  void _handleSend(String message, List<AttachedImage>? images) {
    final service = ref.read(relayConnectionServiceProvider);
    final manager = service.getManager(widget.connectionId);
    
    final List<Map<String, dynamic>>? imageData = images?.map((img) => img.toJson()).toList();
    
    manager?.sendInput(
      sessionId: widget.sessionId,
      message: message,
      images: imageData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      sessionStreamProvider(widget.connectionId, widget.sessionId),
    );

    // Auto-scroll when new items arrive and auto-scroll is enabled
    ref.listen(
      sessionStreamProvider(widget.connectionId, widget.sessionId),
      (previous, next) {
        if (next.autoScrollEnabled &&
            next.displayItems.length > (previous?.displayItems.length ?? 0)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      },
    );

    return Scaffold(
      key: const Key('session_stream_screen'),
      appBar: SessionHeader(
        connectionName: state.connectionName,
        sessionId: state.sessionId,
        sessionState: state.sessionState,
        onBack: () => context.pop(),
        onClearSession: _handleClearSession,
      ),
      body: Column(
        children: [
          // Auto-scroll indicator
          if (!state.autoScrollEnabled)
            Container(
              key: const Key('auto_scroll_paused'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Center(
                child: Text(
                  'Auto-scroll paused • Scroll to bottom to resume',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          else if (state.displayItems.isNotEmpty)
            Container(
              key: const Key('auto_scroll_active'),
              width: 0,
              height: 0,
            ),

          // Stream list
          Expanded(
            child: ListView.builder(
              key: const Key('stream_list'),
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: state.displayItems.length,
              itemBuilder: (context, index) {
                final item = state.displayItems[index];
                return _buildDisplayItem(context, item, index);
              },
            ),
          ),

          // Emergency interrupt button
          EmergencyInterruptButton(
            onPressed: _handleInterrupt,
          ),

          // Input bar
          InputBar(
            onSend: _handleSend,
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayItem(
    BuildContext context,
    StreamDisplayItem item,
    int index,
  ) {
    return switch (item) {
      UserMessageDisplayItem(:final chunk) => UserMessageBubble(chunk: chunk),
      AssistantTextDisplayItem(:final chunk) =>
        AssistantMessageBubble(chunk: chunk),
      ThinkingDisplayItem(:final chunks, :final isExpanded) => ThinkingBlock(
          chunks: chunks,
          isExpanded: isExpanded,
          onToggle: () => ref
              .read(sessionStreamProvider(widget.connectionId, widget.sessionId)
                  .notifier)
              .toggleThinkingBlock(index),
        ),
      ToolCallDisplayItem(:final toolCall) => ToolCallCard(toolCall: toolCall),
      ErrorDisplayItem(:final chunk) => _ErrorMessage(message: chunk.message),
    };
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red[300],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
