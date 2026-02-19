/// Input bar widget for session stream.
///
/// Provides text input, send button, and camera button for attaching images.
/// Used at the bottom of the SessionStreamScreen.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Attached image model for pending attachments
class AttachedImage {
  final String name;
  final String mimeType;
  final Uint8List bytes;

  AttachedImage({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  String get base64Data => base64Encode(bytes);

  Map<String, dynamic> toJson() => {
        'media_type': mimeType,
        'data': base64Data,
      };
}

/// Input bar for sending messages and images to a session.
class InputBar extends StatefulWidget {
  final void Function(String message, List<AttachedImage>? images) onSend;

  const InputBar({
    super.key,
    required this.onSend,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<AttachedImage> _attachedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isComposing = _controller.text.isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
    }
  }

  Future<void> _showImagePickerDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('image_picker_dialog'),
        title: const Text('Add Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImages();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final mimeType = _getMimeType(pickedFile.path);
        setState(() {
          _attachedImages.add(AttachedImage(
            name: pickedFile.name,
            mimeType: mimeType,
            bytes: bytes,
          ));
        });
      }
    } catch (e) {
      // Handle error - in a real app would show snackbar
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage();
      for (final file in pickedFiles) {
        final bytes = await file.readAsBytes();
        final mimeType = _getMimeType(file.path);
        setState(() {
          _attachedImages.add(AttachedImage(
            name: file.name,
            mimeType: mimeType,
            bytes: bytes,
          ));
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'svg' => 'image/svg+xml',
      _ => 'image/png',
    };
  }

  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachedImages.isEmpty) return;

    widget.onSend(
      text,
      _attachedImages.isNotEmpty ? List.from(_attachedImages) : null,
    );

    setState(() {
      _controller.clear();
      _attachedImages.clear();
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSend = _isComposing || _attachedImages.isNotEmpty;

    return Container(
      key: const Key('input_bar'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview row
            if (_attachedImages.isNotEmpty)
              Container(
                key: const Key('image_preview_row'),
                height: 80,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachedImages.length,
                  itemBuilder: (context, index) {
                    return _ImageThumbnail(
                      key: Key('image_thumbnail_$index'),
                      image: _attachedImages[index],
                      onRemove: () => _removeImage(index),
                      removeButtonKey: Key('remove_image_$index'),
                    );
                  },
                ),
              ),

            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Camera button
                IconButton(
                  key: const Key('camera_button'),
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _showImagePickerDialog,
                  tooltip: 'Add image',
                ),

                // Text input
                Expanded(
                  child: TextField(
                    key: const Key('message_input_field'),
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                IconButton(
                  key: const Key('send_button'),
                  icon: Icon(
                    Icons.send,
                    color: canSend
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  onPressed: canSend ? _handleSend : null,
                  tooltip: 'Send message',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Thumbnail widget for attached images
class _ImageThumbnail extends StatelessWidget {
  final AttachedImage image;
  final VoidCallback onRemove;
  final Key? removeButtonKey;

  const _ImageThumbnail({
    super.key,
    required this.image,
    required this.onRemove,
    this.removeButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Stack(
        children: [
          // Image thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              image.bytes,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 70,
                  height: 70,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.image, size: 30),
                );
              },
            ),
          ),

          // Remove button
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              key: removeButtonKey,
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
