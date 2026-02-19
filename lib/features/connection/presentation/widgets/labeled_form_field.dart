import 'package:flutter/material.dart';

/// Labeled Form Field Widget
///
/// A form field with a label and optional helper text.
/// Reduces boilerplate in connection forms.
class LabeledFormField extends StatelessWidget {
  final String label;
  final String? helperText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autocorrect;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? hintText;
  final Key? fieldKey;

  const LabeledFormField({
    super.key,
    required this.label,
    this.helperText,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autocorrect = true,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText,
    this.fieldKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: fieldKey,
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
          validator: validator,
          keyboardType: keyboardType,
          autocorrect: autocorrect,
          textInputAction: textInputAction,
          obscureText: obscureText,
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
