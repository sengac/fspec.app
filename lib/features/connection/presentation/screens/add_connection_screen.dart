import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/connection_providers.dart';
import '../../domain/models/connection.dart';
import '../../domain/services/qr_code_parser.dart';
import '../../domain/validators/connection_validators.dart';
import '../../../dashboard/data/providers/dashboard_providers.dart';
import '../widgets/labeled_form_field.dart';
import '../widgets/qr_scanner_cards.dart';

/// Add Connection Screen
///
/// Allows users to add a new fspec instance connection by:
/// - Manually entering connection details (name, relay URL, channel ID, API key)
/// - Scanning a QR code containing fspec:// URL
class AddConnectionScreen extends ConsumerStatefulWidget {
  const AddConnectionScreen({super.key});

  @override
  ConsumerState<AddConnectionScreen> createState() => _AddConnectionScreenState();
}

class _AddConnectionScreenState extends ConsumerState<AddConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relayUrlController = TextEditingController();
  final _channelIdController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _isApiKeyVisible = false;
  bool _isSaving = false;
  bool _showCameraPermissionDenied = false;

  @override
  void dispose() {
    _nameController.dispose();
    _relayUrlController.dispose();
    _channelIdController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(connectionRepositoryProvider);
      final connection = Connection.create(
        name: _nameController.text.trim(),
        relayUrl: _relayUrlController.text.trim(),
        channelId: _channelIdController.text.trim(),
        apiKey: _apiKeyController.text.trim().isEmpty
            ? null
            : _apiKeyController.text.trim(),
      );

      final result = await repository.save(connection);

      result.fold(
        (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save: ${error.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (_) {
          if (mounted) {
            // Invalidate the connections provider so dashboard refreshes
            ref.invalidate(connectionsProvider);
            Navigator.of(context).maybePop();
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _handleCancel() {
    Navigator.of(context).maybePop();
  }

  // ignore: unused_element - Will be used when mobile_scanner is integrated
  void _handleQrCodeScanned(String qrData) {
    final result = QrCodeParser.parse(qrData);

    if (!result.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Invalid QR code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Fill in the form fields with parsed data
    if (result.name != null) {
      _nameController.text = result.name!;
    }
    if (result.relayUrl != null) {
      _relayUrlController.text = result.relayUrl!;
    }
    if (result.channelId != null) {
      _channelIdController.text = result.channelId!;
    }
    if (result.apiKey != null) {
      _apiKeyController.text = result.apiKey!;
    }

    // Show partial message if applicable
    if (result.isPartial && result.partialMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.partialMessage!),
          backgroundColor: Colors.orange,
        ),
      );
    }

    // Close scanner and return to form
    Navigator.of(context).pop();
  }

  void _openQrScanner() {
    // For now, show camera permission denied state
    // In a real implementation, this would check permissions and open the scanner
    setState(() => _showCameraPermissionDenied = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleCancel,
        ),
        title: const Text('Add Connection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // QR Scanner Card or Camera Permission Denied Card
              if (!_showCameraPermissionDenied)
                QrScannerCard(onTap: _openQrScanner)
              else
                CameraPermissionDeniedCard(onOpenSettings: () {}),

              const SizedBox(height: 24),

              // Connection Name Field
              LabeledFormField(
                fieldKey: const Key('connection_name_field'),
                label: 'Connection Name',
                helperText: 'A friendly name for this instance.',
                controller: _nameController,
                validator: validateConnectionName,
                hintText: 'Work MacBook',
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 24),

              // Relay Server URL Field
              LabeledFormField(
                fieldKey: const Key('relay_url_field'),
                label: 'Relay Server URL',
                helperText: 'The address of your fspec relay server.',
                controller: _relayUrlController,
                validator: validateRelayUrl,
                hintText: 'https://',
                prefixIcon: Icon(
                  Icons.dns_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 24),

              // Channel ID Field
              LabeledFormField(
                fieldKey: const Key('channel_id_field'),
                label: 'Channel ID',
                helperText: 'Unique identifier for the tunnel (UUID).',
                controller: _channelIdController,
                validator: validateChannelId,
                hintText: 'e.g. 123e4567-e89b...',
                prefixIcon: Icon(
                  Icons.tag,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 24),

              // API Key Field
              _buildApiKeyField(theme),

              const SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeyField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'API Key (Optional)',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('api_key_field'),
          controller: _apiKeyController,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.key_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            suffixIcon: IconButton(
              key: const Key('api_key_visibility_toggle'),
              icon: Icon(
                _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _isApiKeyVisible = !_isApiKeyVisible);
              },
            ),
          ),
          obscureText: !_isApiKeyVisible,
          autocorrect: false,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 4),
        Text(
          'Required only if authentication is enabled.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const Key('cancel_button'),
            onPressed: _isSaving ? null : _handleCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton(
            key: const Key('save_button'),
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ),
      ],
    );
  }
}
