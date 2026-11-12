# Temuan Performa - Campus Notify (Minggu 11)

Perangkat uji: Android arm64 (GPU Mali), mode `flutter run --profile`, Impeller.
Beban uji: API palsu 200 pengumuman, latensi 600 ms (`FakeAnnouncementApi`).

**Status bukti** dibedakan agar jujur: *Terukur* = ada angka/screenshot dari
DevTools di `screenshots/`; *Analisis kode* = disimpulkan dari membaca kode,
belum diukur sendiri di DevTools (hipotesis yang masih perlu diverifikasi).

| # | Masalah | Lokasi | Status bukti |
|---|---------|--------|--------------|
| 1 | Chat: tiap potongan teks streaming membangun ulang seluruh halaman | `chat_page.dart` (`ref.watch(chatControllerProvider)` penuh) + `chat_controller.dart` (`_onChunk` membuat `ChatState` baru tiap chunk) | Analisis kode |
| 2 | Daftar pengumuman tidak lazy: semua tile dibangun sekaligus | `home_page.dart` (`ListView(children: [...])`) + `announcements_section.dart` (`Column` dengan spread tile) | Terukur sebagian: 201 instance `Announcement` di heap (`before-memory.png`); jank pada frame awal saat daftar 200 item pertama dimuat (`before-profile.png`). Sisanya analisis kode |
| 3 | Beranda membangun ulang seluruh Scaffold saat token FCM berubah | `home_page.dart` (`ref.watch(pushControllerProvider)` di level Scaffold) | Analisis kode |
| 4 | Beranda dibuat ulang tiap kembali dari detail, sehingga `PushController.start()` jalan lagi (potensi `POST /devices` berulang) dan posisi scroll hilang | `announcements_section.dart` memakai `context.go` ke rute top-level, `AnnouncementPage` kembali dengan `context.go(home)` | Analisis kode. Log baseline hanya memuat satu `PUSH token diterima` karena skenario bolak-balik detail belum dijalankan |
| 5 | Tidak ada cache: daftar diambil ulang tiap app dibuka, detail diambil ulang walau datanya sudah ada di daftar; provider detail tidak `autoDispose` sehingga state per-id menumpuk | `announcement_repository_impl.dart`, `announcements_providers.dart` | Analisis kode (delay 600 ms per request karena API palsu) |

## Catatan pengukuran baseline (yang benar-benar ada)

- `before-profile.png`: tab Performance setelah app dibuka. Frame jank (merah/
  salmon) menumpuk di frame 3-10 (fase startup + memuat 200 item), lalu
  frame menjadi ringan. Rata-rata 56 FPS pada sesi itu. **Ini rekaman startup,
  bukan skenario scroll/search/chat**, jadi tidak dipakai sebagai bukti masalah 1,
  3, atau 4.
- `before-memory.png`: Dart heap 18,4 MB; 201 instance `Announcement`
  (200 daftar + 1 detail); 17 `ProviderElement`.
