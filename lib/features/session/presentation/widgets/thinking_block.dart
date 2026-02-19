/// Thinking block widget.
///
/// Collapsible block showing AI reasoning with step-by-step progress.
library;

import 'package:flutter/material.dart';

import '../../data/models/stream_chunk.dart';

/// Collapsible thinking block widget
class ThinkingBlock extends StatelessWidget {
  final List<ThinkingChunk> chunks;
  final bool isExpanded;
  final VoidCallback onToggle;

  const ThinkingBlock({
    super.key,
    required this.chunks,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const Key('thinking_block'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (always visible)
          InkWell(
            key: const Key('thinking_block_header'),
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.settings,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thinking Process',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (isExpanded) ...[
            Container(
              key: const Key('thinking_steps_expanded'),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...chunks.map((chunk) => _ThinkingStep(chunk: chunk)),
                ],
              ),
            ),
          ] else if (chunks.isNotEmpty) ...[
            // Show first step preview when collapsed
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  _StepIndicator(isComplete: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chunks.first.content,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (chunks.length > 1)
                    Text(
                      '+${chunks.length - 1} more',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThinkingStep extends StatelessWidget {
  final ThinkingChunk chunk;

  const _ThinkingStep({required this.chunk});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(
            key: const Key('thinking_step_indicator'),
            isComplete: true,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              chunk.content,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final bool isComplete;

  const _StepIndicator({
    super.key,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isComplete
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        border: isComplete
            ? null
            : Border.all(color: theme.colorScheme.outline),
      ),
      child: isComplete
          ? const Icon(
              Icons.check,
              size: 12,
              color: Colors.white,
            )
          : null,
    );
  }
}
