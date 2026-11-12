import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_controller.dart';
import '../providers/chat_providers.dart';
import '../widgets/api_key_dialog.dart';
import '../widgets/chat_banner.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_list.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    ref.read(chatControllerProvider.notifier).send(text);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _openKeyDialog() {
    showDialog<void>(context: context, builder: (_) => const ApiKeyDialog());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChatState>(chatControllerProvider, (_, _) => _scrollToEnd());
    final chat = ref.watch(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);
    final noKey = ref.watch(apiKeyPresentProvider).value == false;
    final remaining = ref.watch(remainingQuotaProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten Kampus'),
        actions: [
          IconButton(
            tooltip: 'Atur API key',
            icon: const Icon(Icons.key),
            onPressed: _openKeyDialog,
          ),
          IconButton(
            tooltip: 'Hapus percakapan',
            icon: const Icon(Icons.delete_outline),
            onPressed: chat.messages.isEmpty ? null : controller.clear,
          ),
        ],
      ),
      body: Column(
        children: [
          if (noKey)
            ChatBanner(
              message: 'API key belum diatur. Isi dulu untuk memakai asisten.',
              actionLabel: 'Atur',
              onAction: _openKeyDialog,
            ),
          Expanded(
            child: ChatMessageList(messages: chat.messages, controller: _scroll),
          ),
          if (chat.error != null)
            ChatBanner(
              isError: true,
              message: chat.error!,
              actionLabel: 'Coba lagi',
              onAction: controller.retry,
            ),
          if (remaining != null)
            Text(
              'Sisa permintaan hari ini: $remaining',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ChatInputBar(
            controller: _input,
            enabled: !chat.isStreaming,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}
