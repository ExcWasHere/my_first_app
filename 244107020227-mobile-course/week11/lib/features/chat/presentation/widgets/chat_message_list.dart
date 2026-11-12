import 'package:flutter/material.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_bubble.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    super.key,
    required this.messages,
    required this.controller,
  });

  final List<ChatMessage> messages;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Tanyakan sesuatu soal pengumuman kampus.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(12),
      itemCount: messages.length,
      // RepaintBoundary: gelembung yang sedang streaming di-repaint sendiri,
      // gelembung lama tidak ikut digambar ulang tiap potongan teks tiba.
      itemBuilder: (_, i) => RepaintBoundary(
        child: ChatBubble(key: ValueKey(i), message: messages[i]),
      ),
    );
  }
}
