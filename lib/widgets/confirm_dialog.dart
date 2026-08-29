import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'gradient_button.dart';

/// Shows a Cancel/Delete confirmation dialog and returns true only if the
/// user confirmed. Used before any destructive delete action.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        SizedBox(
          width: 110,
          child: GradientButton(
            height: 44,
            gradient: AppColors.dangerGradient,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
