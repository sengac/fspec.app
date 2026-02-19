/// Emergency interrupt button widget.
///
/// Prominent red button for sending interrupt command to the AI session.
library;

import 'package:flutter/material.dart';

/// Red emergency interrupt button
class EmergencyInterruptButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const EmergencyInterruptButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        key: const Key('emergency_interrupt_button'),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(Icons.pan_tool, size: 20),
        label: const Text(
          'EMERGENCY INTERRUPT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
