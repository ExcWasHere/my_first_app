import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes.dart';

class ChatEntryButton extends StatelessWidget {
  const ChatEntryButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Asisten AI',
      icon: const Icon(Icons.smart_toy_outlined),
      onPressed: () => context.push(AppRoutes.chat),
    );
  }
}
