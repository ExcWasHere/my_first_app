import 'package:flutter/material.dart';

class ChatBanner extends StatelessWidget {
  const ChatBanner({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.isError = false,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isError ? scheme.errorContainer : scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(message)),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
