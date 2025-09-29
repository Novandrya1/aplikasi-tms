import 'package:flutter/material.dart';
import '../utils/input_sanitizer.dart';

class EnhancedFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool sanitize;
  final TextInputType? keyboardType;
  final IconData? icon;

  const EnhancedFormField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.sanitize = true,
    this.keyboardType,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (sanitize && value != null) {
          final sanitized = InputSanitizer.sanitize(value);
          if (sanitized != value) {
            return 'Input mengandung karakter tidak valid';
          }
        }
        return validator?.call(value);
      },
      onChanged: sanitize ? (value) {
        final sanitized = InputSanitizer.sanitize(value);
        if (sanitized != value) {
          controller.text = sanitized;
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: sanitized.length),
          );
        }
      } : null,
    );
  }
}