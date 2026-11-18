# Minggu 12 — Pengujian dan Jaminan Kualitas

## 1. Skenario yang diuji

Perilaku utama yang dipilih: **login → daftar pengumuman → pencarian → detail**,
ditambah **chat AI**.

| # | Skenario | Jenis | Berkas uji |
|---|---|---|---|
| 1 | Judul pengumuman tersaring tanpa peduli huruf besar/kecil, spasi tepi diabaikan, pencarian hanya di judul | unit | `search_filter_test.dart` |
| 2 | **Kasus tepi:** query kosong / hanya spasi mengembalikan semua; kata sandi tepat 6 karakter diterima; kuota direset pada hari berikutnya; hitungan kuota rusak dianggap 0 | unit | `search_filter_test.dart`, `login_test.dart`, `usage_quota_test.dart` |
| 3 | **Kasus gagal:** repository mengembalikan `NetworkFailure` (tidak dilempar diam-diam), cache kedaluwarsa lalu API gagal → pakai cache lama, API key kosong / kuota habis / pertanyaan > 500 karakter tidak memanggil AI | unit | `get_announcements_test.dart`, `announcement_repository_cache_test.dart`, `send_chat_message_test.dart` |
| 4 | **Fake repository:** daftar sukses dan daftar error dipakai untuk memisahkan dependensi dari API sungguhan | unit | `get_announcements_test.dart`, `announcement_repository_cache_test.dart`, `support/chat_fakes.dart` |
| 5 | Halaman login: input tidak valid menampilkan pesan tanpa memanggil repository; error jaringan dari repository tampil | widget | `login_page_test.dart` |
| 6 | Daftar pengumuman: tampilan awal, pencarian, empty state, tombol hapus, daftar 500 item dibangun malas, dan repository gagal menampilkan pesan error | widget | `announcement_search_widget_test.dart` |
| 7 | Chat: jawaban streaming, banner error + jawaban cadangan lokal, banner API key, tombol coba lagi, hapus percakapan, simpan/hapus API key lewat dialog | widget | `chat_page_test.dart` |
| 8 | Pemetaan error Dio (timeout, 401/403, 5xx, 4xx lain, cancel, non-Dio) dan alur refresh token pada `api_client` (401 → refresh → ulang; refresh gagal → token dibersihkan) | unit | `failure_mapper_test.dart`, `api_client_test.dart` |
| 9 | Repositori Groq: potongan SSE dialirkan berurutan, API key kosong gagal sebelum jaringan, 401/429/500 dipetakan ke pesan yang tepat | unit | `groq_chat_repository_test.dart` |
| 10 | **Alur utama:** login → beranda → cari "beasiswa" → buka detail pengumuman | integrasi | `integration_test/app_test.dart` |

## 2. Hasil testing

Baru: 31 pengujian unit/widget di `test/` — `login_page_test.dart` (3),
`failure_mapper_test.dart` (7), `api_client_test.dart` (3),
`groq_chat_repository_test.dart` (4), `auth_repository_impl_test.dart` (3),
`usage_quota_test.dart` (4), plus tambahan di `login_test.dart` (2),
`announcement_search_widget_test.dart` (1), `chat_page_test.dart` (4) — dan
1 pengujian integrasi di `integration_test/app_test.dart`.

Total suite `flutter test`: **82 pengujian** (51 dari Minggu 11 + 31 baru),
ditambah 1 tes integrasi yang dijalankan terpisah.

Fake yang dipakai: `_FakeAuthRepository`, `_FakeAnnouncementRepository`,
`_FakePushRepository` (integrasi), `FakeChat`/`FakeSettings`/`FakeQuota`
(chat), `_MemoryCache` + `_Remote` (cache), `_SseAdapter`/`_FakeAdapter`
(HTTP palsu lewat `HttpClientAdapter`).

## 4. Hasil pemeriksaan

| Perintah | Hasil |
|---|---|
| `flutter test` | 82 tes lulus, 0 gagal |
| `flutter analyze` | `No issues found!` |
| `flutter test --coverage` | 519/609 baris = **85,2%** |
| `flutter test integration_test/app_test.dart -d flutter-tester` | 1 tes lulus |
| `flutter test integration_test/app_test.dart -d <device_id>` | belum dijalankan (lihat kendala) |