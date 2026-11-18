# Minggu 12 — Pengujian dan Jaminan Kualitas

Project **Campus Notify** hasil Minggu 11 disalin ke folder `week12`, lalu
dilengkapi pengujian unit, widget, dan integrasi sesuai jobsheet Minggu 12.

Nama package di `pubspec.yaml` masih `week10` (warisan dari Minggu 10/11);
seluruh `import 'package:week10/...'` mengikuti nama itu.

## 1. Skenario yang diuji

Perilaku utama yang dipilih: **login → daftar pengumuman → pencarian → detail**,
ditambah **chat AI** karena ia punya jalur gagal (jaringan, API key, kuota).

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

## 2. Perubahan kode aplikasi

Hanya penambahan `Key` agar widget test tidak bergantung pada teks/urutan:

| Berkas | Perubahan |
|---|---|
| `lib/features/auth/presentation/pages/login_page.dart` | `login-email-field`, `login-password-field`, `login-submit-button` |
| `lib/features/announcements/presentation/widgets/announcement_search_field.dart` | `announcement-search-field` |
| `pubspec.yaml` | `dev_dependencies: integration_test` |

Logika aplikasi tidak diubah.

## 3. Berkas uji

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

Baris yang belum tercakup: `di.dart`, `routes.dart` (konstanta),
`announcement_remote_data_source.dart` + `auth_remote_data_source.dart`
(API palsu dengan `Future.delayed` sengaja diuji lewat fake),
`hive_announcement_cache.dart` (butuh inisialisasi Hive di disk),
`secure_ai_settings_repository.dart` (pembungkus tipis secure storage).

## 5. Kendala

- Pengujian integrasi **tidak dijalankan di perangkat/emulator** sesuai arahan.
  Dijalankan headless dengan `-d flutter-tester` (host test runner), yang
  menjalankan `IntegrationTestWidgetsFlutterBinding` tanpa layar. Perintah
  untuk perangkat: `flutter test integration_test/app_test.dart -d <device_id>`.
- `flutter test integration_test/app_test.dart` tanpa `-d` gagal dengan
  "More than one device connected" pada mesin ini (Windows, Chrome, Edge
  terdeteksi) — perintah jobsheet memang mensyaratkan `-d`.
- `main()` asli tidak dipakai di tes integrasi karena memanggil
  `Firebase.initializeApp()`; `MyApp` dijalankan dengan `ProviderScope` berisi
  fake auth, fake pengumuman, dan fake push.

## 6. Temuan yang belum terselesaikan

1. `HiveAnnouncementCache` belum punya tes: `Hive.initFlutter()` menulis ke
   direktori aplikasi, sehingga tes akan mengotori disk host. Belum diputuskan
   apakah cache perlu diuji dengan direktori sementara.
2. `ApiKeyDialog` tidak memberi umpan balik bila "Simpan" ditekan dengan kolom
   kosong — dialog hanya diam. Perilaku ini belum diuji karena belum jelas
   apakah seharusnya menampilkan validasi.
3. Cakupan `auth_providers.dart` 70%: jalur `logout()` dari `HomePage` belum
   diuji pada level widget.
4. `announcementsProvider` tetap memakai `FakeAnnouncementApi` dengan latensi
   600 ms; tes integrasi menggantinya dengan fake sehingga latensi asli tidak
   ikut terukur.

## 7. Refleksi

- **Bug yang paling mungkin terlewat tanpa tes:** pemetaan error HTTP. Tanpa
  `failure_mapper_test` dan `api_client_test`, 401 saat refresh token bisa
  berubah menjadi error tak dikenal atau token lama tetap dipakai tanpa
  terlihat.
- **Bagian yang perlu fake:** repository pengumuman, auth, chat, kuota, dan
  push. Dengan fake, hasil sukses dan gagal bisa dipaksa deterministik tanpa
  jaringan, Firebase, atau secure storage perangkat.
- **Nilai widget vs integrasi:** widget test cepat menemukan regresi tampilan
  (empty state, banner, tombol nonaktif) dan bisa dijalankan tiap commit;
  tes integrasi membuktikan router + provider + halaman benar-benar menyambung
  (login mengarahkan ke beranda, pencarian menyaring, detail terbuka) — hal
  yang tidak terlihat dari tes per widget.

## 8. Menjalankan

```bash
flutter pub get
flutter test
flutter analyze
flutter test --coverage            # laporan di coverage/lcov.info
flutter test integration_test/app_test.dart -d <device_id>
```
