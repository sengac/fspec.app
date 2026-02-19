/// Session header widget.
///
/// Displays connection name, session ID badge, running status indicator,
/// and overflow menu with session control options.
library;

import 'package:flutter/material.dart';

import '../../data/models/stream_chunk.dart';

/// Header widget for session stream screen
class SessionHeader extends StatelessWidget implements PreferredSizeWidget {
  final String connectionName;
  final String sessionId;
  final SessionState sessionState;
  final VoidCallback? onBack;
  final VoidCallback? onClearSession;

  const SessionHeader({
    super.key,
    required this.connectionName,
    required this.sessionId,
    required this.sessionState,
    this.onBack,
    this.onClearSession,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: IconButton(
        key: const Key('back_button'),
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack ?? () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            connectionName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              sessionId,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
      actions: [
        _SessionStatusIndicator(state: sessionState),
        PopupMenuButton<String>(
          key: const Key('header_overflow_menu'),
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'clear' && onClearSession != null) {
              onClearSession!();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Clear Session',
                    style: TextStyle(color: Colors.red[400]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _SessionStatusIndicator extends StatelessWidget {
  final SessionState state;

  const _SessionStatusIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color, key) = switch (state) {
      SessionState.running => (
          'Running',
          Colors.green,
          const Key('status_indicator_running'),
        ),
      SessionState.idle => (
          'Idle',
          Colors.grey,
          const Key('status_indicator_idle'),
        ),
      SessionState.paused => (
          'Paused',
          Colors.orange,
          const Key('status_indicator_paused'),
        ),
    };

    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
