import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/sync.dart';
import '../note_tile.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          IconButton(
            tooltip: 'Posts (cache-first)',
            icon: const Icon(Icons.article_outlined),
            onPressed: () => context.push('/posts-cache'),
          ),
          IconButton(
            tooltip: 'Posts Paged (Minggu 4)',
            icon: const Icon(Icons.dynamic_feed_outlined),
            onPressed: () => context.push('/posts'),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          const _StatusCard(),
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Gagal memuat catatan: $error'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => ref.invalidate(notesProvider),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
              data: (notes) {
                if (notes.isEmpty) {
                  return const Center(
                    child: Text('Belum ada catatan. Tekan + untuk menambah.'),
                  );
                }
                return ListView.separated(
                  itemCount: notes.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final id = note.id;
                    return NoteTile(
                      note: note,
                      onTap: id == null
                          ? null
                          : () => context.push('/note/$id'),
                      onDelete: id == null
                          ? null
                          : () =>
                              ref.read(notesProvider.notifier).deleteNote(id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Catatan'),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String title, String body})>(
      context: context,
      builder: (_) => const _AddNoteDialog(),
    );
    if (result == null) return;
    await ref
        .read(notesProvider.notifier)
        .addNote(title: result.title, body: result.body);
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(forceOfflineProvider);
    final dirtyCount = ref.watch(dirtyCountProvider);
    final syncing = ref.watch(syncingProvider);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Simulasi offline'),
              subtitle: Text(
                offline ? 'Jaringan diputus (simulasi)' : 'Online',
              ),
              value: offline,
              onChanged: (value) =>
                  ref.read(forceOfflineProvider.notifier).state = value,
            ),
            Row(
              children: [
                Icon(
                  dirtyCount > 0
                      ? Icons.sync_problem
                      : Icons.cloud_done_outlined,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dirtyCount > 0
                        ? '$dirtyCount catatan belum tersinkron'
                        : 'Semua catatan tersinkron',
                  ),
                ),
                FilledButton.icon(
                  onPressed: (syncing || dirtyCount == 0)
                      ? null
                      : () => _sync(context, ref),
                  icon: syncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(syncing ? 'Menyinkronkan...' : 'Sinkronkan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final synced = await ref.read(notesProvider.notifier).sync();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            synced == 0
                ? 'Tidak ada catatan yang perlu disinkronkan'
                : '$synced catatan berhasil disinkronkan',
          ),
        ),
      );
    } on OfflineException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Sinkronisasi gagal: $e')));
    }
  }
}

class _AddNoteDialog extends StatefulWidget {
  const _AddNoteDialog();

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _titleError;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Judul wajib diisi');
      return;
    }
    Navigator.of(context).pop((
      title: title,
      body: _bodyController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Catatan baru'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Judul',
              errorText: _titleError,
            ),
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Isi (opsional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}