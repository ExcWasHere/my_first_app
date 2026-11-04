# Campus Notify: Week 9, AI-Assisted Development / Vibe Coding

Project Minggu 7 (Campus Notify, feature-first Clean Architecture) ditambah satu fitur kecil yang dibuat dengan bantuan AI: **pencarian judul pengumuman dengan empty state**. Seluruh proses (prompt, konteks, output awal AI, verifikasi, keputusan terima/tolak) ada di [`docs/ai-log.md`](docs/ai-log.md).

## Fitur

- Kolom "Cari judul pengumuman" di `HomePage`, menyaring daftar saat mengetik.
- Pencarian mengabaikan huruf besar/kecil dan spasi di tepi; query kosong menampilkan semua pengumuman.
- Empty state: *Tidak ada pengumuman untuk "…"* bila tidak ada yang cocok, dan *Belum ada pengumuman* bila daftar memang kosong.
- Tombol hapus (ikon X) untuk mengosongkan pencarian.

## File baru / diubah

| File | Status |
|---|---|
| `lib/features/announcements/domain/usecases/search_announcements.dart` | baru |
| `lib/features/announcements/presentation/providers/announcements_providers.dart` | diubah |
| `lib/features/announcements/presentation/widgets/announcement_search_field.dart` | baru |
| `lib/features/announcements/presentation/widgets/announcement_empty_state.dart` | baru |
| `lib/features/announcements/presentation/widgets/announcements_section.dart` | baru |
| `lib/features/home/presentation/pages/home_page.dart` | diubah |
| `test/search_filter_test.dart` | baru (5 unit test) |
| `test/announcement_search_widget_test.dart` | baru (4 widget test) |
| `docs/ai-log.md`, `README.md`, `screenshots/` | baru |

## Prompt (ringkas)

Formula 5 slot: **Peran** senior Flutter dev; **Konteks** feature-first + Riverpod + kontrak repository/use case yang ada + versi package; **Tugas** search judul + empty state; **Batas** jangan ubah repository/router/auth/push, filter harus di use case murni, fungsi maks 40 baris; **Output** kode + test + cara uji. Versi lengkap ada di `docs/ai-log.md`.

## Stack

Flutter (Dart SDK `^3.11.5`), `flutter_riverpod ^2.6.1`, `go_router ^17.5.0`, `dio ^5.11.1`, `flutter_secure_storage ^11.2.0`, `firebase_core ^4.15.0`, `firebase_messaging ^16.7.0`, `flutter_local_notifications ^22.3.1`.