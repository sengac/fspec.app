import 'package:flutter/material.dart';

/// QR Scanner Card Widget
///
/// Displays a card with QR scanner icon and prompt.
/// Tapping opens the QR scanner for quick setup.
class QrScannerCard extends StatelessWidget {
  final VoidCallback onTap;

  const QrScannerCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        key: const Key('scan_qr_button'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Scan QR Code',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Quick setup from desktop',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Camera Permission Denied Card Widget
///
/// Displays when camera permission is denied.
/// Shows explanation and Open Settings button.
class CameraPermissionDeniedCard extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const CameraPermissionDeniedCard({
    super.key,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            const Text('Camera access required'),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('open_settings_button'),
              onPressed: onOpenSettings,
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
