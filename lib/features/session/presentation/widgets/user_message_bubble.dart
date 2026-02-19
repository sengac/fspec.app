/// User message bubble widget.
///
/// Displays user messages in a purple bubble with timestamp.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/stream_chunk.dart';

/// Purple bubble widget for displaying user messages
class UserMessageBubble extends StatelessWidget {
  final UserMessageChunk chunk;

  const UserMessageBubble({
    super.key,
    required this.chunk,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a');

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        key: const Key('user_message_bubble'),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF9C27B0), // Purple
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              chunk.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              key: const Key('message_timestamp'),
              timeFormat.format(chunk.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
