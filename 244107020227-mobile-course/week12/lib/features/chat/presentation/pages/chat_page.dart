import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
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
    // Halaman ini TIDAK me-watch state chat. Tiap potongan teks streaming
    // hanya membangun ulang widget kecil di bawah yang memang memakainya
    // (lewat select), bukan Scaffold + AppBar + banner + kolom input.
    ref.listen<List<ChatMessage>>(
      chatControllerProvider.select((s) => s.messages),
      (_, _) => _scrollToEnd(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten Kampus'),
        actions: [
          IconButton(
            tooltip: 'Atur API key',
            icon: const Icon(Icons.key),
            onPressed: _openKeyDialog,
          ),
          const _ClearChatButton(),
        ],
      ),
      body: Column(
        children: [
          _NoKeyBanner(onAction: _openKeyDialog),
          Expanded(child: _MessagesView(controller: _scroll)),
          const _ErrorBanner(),
          const _QuotaText(),
          _InputArea(controller: _input, onSend: _send),
        ],
      ),
    );
  }
}

class _ClearChatButton extends ConsumerWidget {
  const _ClearChatButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEmpty = ref.watch(
      chatControllerProvider.select((s) => s.messages.isEmpty),
    );
    return IconButton(
      tooltip: 'Hapus percakapan',
      icon: const Icon(Icons.delete_outline),
      onPressed:
          isEmpty ? null : ref.read(chatControllerProvider.notifier).clear,
    );
  }
}

class _NoKeyBanner extends ConsumerWidget {
  const _NoKeyBanner({required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noKey = ref.watch(apiKeyPresentProvider).value == false;
    if (!noKey) return const SizedBox.shrink();
    return ChatBanner(
      message: 'API key belum diatur. Isi dulu untuk memakai asisten.',
      actionLabel: 'Atur',
      onAction: onAction,
    );
  }
}

class _MessagesView extends ConsumerWidget {
  const _MessagesView({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(
      chatControllerProvider.select((s) => s.messages),
    );
    return ChatMessageList(messages: messages, controller: controller);
  }
}

class _ErrorBanner extends ConsumerWidget {
  const _ErrorBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(chatControllerProvider.select((s) => s.error));
    if (error == null) return const SizedBox.shrink();
    return ChatBanner(
      isError: true,
      message: error,
      actionLabel: 'Coba lagi',
      onAction: ref.read(chatControllerProvider.notifier).retry,
    );
  }
}

class _QuotaText extends ConsumerWidget {
  const _QuotaText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(remainingQuotaProvider).value;
    if (remaining == null) return const SizedBox.shrink();
    return Text(
      'Sisa permintaan hari ini: $remaining',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _InputArea extends ConsumerWidget {
  const _InputArea({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaming = ref.watch(
      chatControllerProvider.select((s) => s.isStreaming),
    );
    return ChatInputBar(
      controller: controller,
      enabled: !streaming,
      onSend: onSend,
    );
  }
}
