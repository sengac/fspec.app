import 'package:flutter/material.dart';

import '../../../connection/domain/models/connection.dart';

/// Widget displaying a single instance connection card on the dashboard
///
/// Shows connection status, project name, activity preview,
/// and context-sensitive action button.
/// 
/// UX states:
/// - CONNECTED: Primary action is "Open" to view the board. Disconnect in menu.
/// - CONNECTING: Shows spinner, disabled state
/// - DISCONNECTED/ERROR: Primary action is "Connect" / "Retry"
class InstanceCard extends StatelessWidget {
  const InstanceCard({
    super.key,
    required this.connection,
    required this.onTap,
    this.onConnect,
    this.onDisconnect,
    this.onMoreOptions,
  });

  final Connection connection;
  final VoidCallback onTap;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;
  final VoidCallback? onMoreOptions;

  /// Get display label for connection status
  String get _statusLabel {
    switch (connection.status) {
      case ConnectionStatus.connected:
        return 'ONLINE';
      case ConnectionStatus.connecting:
        return 'CONNECTING';
      case ConnectionStatus.disconnected:
      case ConnectionStatus.error:
        return 'OFFLINE';
    }
  }

  /// Get status indicator color
  Color _statusColor(BuildContext context) {
    switch (connection.status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.disconnected:
      case ConnectionStatus.error:
        return Colors.red;
    }
  }

  /// Get activity type label
  String? get _activityLabel {
    switch (connection.lastActivityType) {
      case ActivityType.aiOutput:
        return 'AI OUTPUT SNIPPET';
      case ActivityType.error:
        return 'CRITICAL FAILURE';
      case ActivityType.status:
        return 'STATUS MESSAGE';
      case null:
        return null;
    }
  }

  /// Get activity label color
  Color _activityLabelColor(BuildContext context) {
    switch (connection.lastActivityType) {
      case ActivityType.error:
        return Colors.red;
      case ActivityType.aiOutput:
      case ActivityType.status:
      case null:
        return Theme.of(context).colorScheme.primary;
    }
  }

  /// Format relative time for last activity
  String? get _relativeTime {
    final activityAt = connection.lastActivityAt;
    if (activityAt == null) return null;
    
    final now = DateTime.now();
    final difference = now.difference(activityAt);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  bool get _isConnected => connection.status == ConnectionStatus.connected;
  bool get _isConnecting => connection.status == ConnectionStatus.connecting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      key: const Key('instance_card'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: _isConnected ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: name, status, time
              Row(
                children: [
                  Expanded(
                    child: Text(
                      connection.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(context).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isConnecting)
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _statusColor(context),
                            ),
                          )
                        else
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _statusColor(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _statusColor(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_relativeTime != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      _relativeTime!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),

              // Project name
              if (connection.lastKnownProjectName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      connection.lastKnownProjectName!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],

              // Activity preview
              if (connection.lastActivityContent != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_activityLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            _activityLabel!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _activityLabelColor(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        connection.lastActivityContent!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],

              // Action button row
              const SizedBox(height: 12),
              _buildActionRow(context, theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    if (_isConnected) {
      // Connected: "Open" button + overflow menu with disconnect
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showConnectedMenu(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      );
    } else if (_isConnecting) {
      // Connecting: Disabled button with spinner
      return Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: null,
              icon: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              label: const Text('Connecting...'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onMoreOptions,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      );
    } else {
      // Disconnected/Error: "Connect" button
      final isError = connection.status == ConnectionStatus.error;
      return Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: onConnect,
              icon: Icon(isError ? Icons.refresh : Icons.link),
              label: Text(isError ? 'Retry Connection' : 'Connect'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onMoreOptions,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      );
    }
  }

  void _showConnectedMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('View Board'),
              onTap: () {
                Navigator.pop(context);
                onTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('Disconnect'),
              onTap: () {
                Navigator.pop(context);
                onDisconnect?.call();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Connection'),
              onTap: () {
                Navigator.pop(context);
                onMoreOptions?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
