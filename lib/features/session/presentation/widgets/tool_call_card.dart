/// Tool call card widget.
///
/// Displays tool calls with name, status badge, input code block, and output.
library;

import 'package:flutter/material.dart';

import '../../data/models/stream_chunk.dart';
import '../../data/models/session_stream_state.dart';

/// Card widget for displaying tool calls
class ToolCallCard extends StatelessWidget {
  final ToolCallWithResult toolCall;

  const ToolCallCard({
    super.key,
    required this.toolCall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = toolCall.effectiveStatus;

    return Container(
      key: const Key('tool_call_block'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(theme, status),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with tool name and status
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.terminal,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'TOOL: ${toolCall.toolCall.name.toUpperCase()}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _StatusBadge(status: status),
              ],
            ),
          ),
          // Input code block
          Container(
            key: const Key('tool_input_code_block'),
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), // Dark code background
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                '\$ ${toolCall.toolCall.input}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: _getInputColor(status),
                ),
              ),
            ),
          ),
          // Progress output (if any)
          if (toolCall.progressOutput.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                toolCall.progressOutput.join('\n'),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.grey,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          // Output (if result is available)
          if (toolCall.result != null) ...[
            const SizedBox(height: 8),
            Container(
              key: toolCall.result!.isError
                  ? const Key('tool_output_error')
                  : const Key('tool_output_block'),
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: toolCall.result!.isError
                    ? Colors.red.withValues(alpha: 0.1)
                    : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: toolCall.result!.isError
                    ? Border.all(color: Colors.red.withValues(alpha: 0.3))
                    : null,
              ),
              child: Text(
                toolCall.result!.content,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: toolCall.result!.isError
                      ? Colors.red[300]
                      : Colors.grey[300],
                ),
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Color _getBorderColor(ThemeData theme, ToolCallStatus status) {
    return switch (status) {
      ToolCallStatus.running => theme.colorScheme.primary.withValues(alpha: 0.5),
      ToolCallStatus.completed => Colors.green.withValues(alpha: 0.5),
      ToolCallStatus.error => Colors.red.withValues(alpha: 0.5),
    };
  }

  Color _getInputColor(ToolCallStatus status) {
    return switch (status) {
      ToolCallStatus.error => Colors.red[300]!,
      _ => const Color(0xFF4EC9B0), // Teal for commands
    };
  }
}

class _StatusBadge extends StatelessWidget {
  final ToolCallStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, key) = switch (status) {
      ToolCallStatus.running => (
          'running',
          Colors.blue,
          const Key('tool_status_badge_running'),
        ),
      ToolCallStatus.completed => (
          'completed',
          Colors.green,
          const Key('tool_status_badge_completed'),
        ),
      ToolCallStatus.error => (
          'error',
          Colors.red,
          const Key('tool_status_badge_error'),
        ),
    };

    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
