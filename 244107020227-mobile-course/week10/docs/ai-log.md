# AI Log: Jobsheet 9 (AI-Assisted Development / Vibe Coding)

Fitur: **pencarian judul pengumuman + empty state** pada project Campus Notify (hasil refactor Clean Architecture Minggu 7).

---

## 1. Prompt (formula 5 slot)

```
Peran: senior Flutter dev
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
  Riverpod (flutter_riverpod ^2.6.1), GoRouter, Dio. Dependency rule: domain
  tidak boleh mengimpor Flutter/Dio/Riverpod. Kontrak yang ditempel:
  Announcement (entity), AnnouncementRepository (interface), GetAnnouncements
  (use case), announcements_providers.dart, home_page.dart, pubspec.yaml.
Tugas: tambah pencarian judul pengumuman di HomePage + empty state
  ("Tidak ada pengumuman untuk ...").
Batas: jangan ubah AnnouncementRepository, AnnouncementRepositoryImpl, router,
  auth, maupun push notification. Aturan filter harus di use case domain yang
  murni. Widget tidak boleh berisi logika filter. Tiap fungsi maks 40 baris.
Output: kode + test (unit test filter sukses dan gagal, 1 widget test empty
  state) + cara uji manual.
```

**Catatan privasi:** tidak ada token FCM, JWT, API key, atau `google-services.json` yang ditempel ke AI. Data pengumuman di project ini juga hanya data dummy.


## 2. Konteks yang ditempel

| File | Alasan ditempel |
|---|---|
| `announcement.dart` | bentuk entity (`id`, `title`, `body`) |
| `announcement_repository.dart` | kontrak data, agar tidak diubah |
| `get_announcements.dart` | gaya use case yang sudah ada |
| `announcements_providers.dart` | titik sambung Riverpod |
| `home_page.dart` | tempat daftar pengumuman ditampilkan |
| `pubspec.yaml` | versi package (Riverpod 2.x, GoRouter 17.x) |
| `get_announcements_test.dart` | gaya test dan pola fake repository |

Yang sengaja **tidak** ditempel: `token_store.dart`, `api_client.dart`, `google-services.json`, token FCM.

## 3. Output awal AI (ringkasan)

AI mengusulkan 7 file (5 baru, 2 diubah) dan 2 file test:

| File | Status | Isi singkat |
|---|---|---|
| `domain/usecases/search_announcements.dart` | baru | filter judul, abaikan huruf besar/kecil, trim, query kosong = semua |
| `presentation/providers/announcements_providers.dart` | diubah | tambah `searchAnnouncementsProvider`, `AnnouncementSearchQuery` (Notifier), `filteredAnnouncementsProvider` |
| `presentation/widgets/announcement_search_field.dart` | baru | TextField + tombol hapus |
| `presentation/widgets/announcement_empty_state.dart` | baru | tampilan kosong |
| `presentation/widgets/announcements_section.dart` | baru | menggabungkan field + daftar + empty state |
| `home/presentation/pages/home_page.dart` | diubah | blok `announcements.when` diganti `AnnouncementsSection` |
| `test/search_filter_test.dart` | baru | 5 unit test use case |
| `test/announcement_search_widget_test.dart` | baru | 4 widget test |

## 4. Verifikasi 6 langkah

### Perintah bukti

```bash
# Langkah 2: domain tidak boleh impor Flutter/Dio/Riverpod (harus tanpa hasil)
grep -rnE "package:(flutter|flutter_riverpod|dio|go_router)" \
  lib/features/announcements/domain/

# Langkah 3: API yang dipakai kode AI benar-benar ada di versi yang terpasang
grep -n "flutter_riverpod\|^  riverpod:" pubspec.lock
grep -rn "whenData" ~/.pub-cache/hosted/pub.dev/riverpod-2.*/lib | head -3
grep -rn "class Notifier<" ~/.pub-cache/hosted/pub.dev/riverpod-2.*/lib | head -3
grep -rn "overrideWithValue" ~/.pub-cache/hosted/pub.dev/riverpod-2.*/lib | head -3
```

(Path `~/.pub-cache` di Windows: `%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\`.)

## 5. Bukti bug / halusinasi (wajib)

Jobsheet meminta minimal satu bug/halusinasi **yang kamu temukan sendiri** beserta cara membuktikannya. Jangan menyalin dari file ini kalau kamu belum benar-benar mengalaminya. Dua cara mendapatkan bukti yang nyata:

**A. Mutation check (test merah buatan).** Buktikan test benar-benar menangkap bug:

1. Di `search_announcements.dart`, hapus `.toLowerCase()` pada sisi judul (`a.title.toLowerCase()` menjadi `a.title`).
2. Jalankan `flutter test test/search_filter_test.dart`.
3. Test "filter abaikan huruf besar/kecil" harus **merah**. Tempel outputnya di bawah, lalu kembalikan kodenya.

**B. Temuan dari AI lain / review sendiri.** Kalau saat membaca kode atau menjalankan `flutter analyze` kamu menemukan method fiktif, API yang tidak cocok dengan versi paket, atau logika yang salah, catat di sini.

## 6. AI Prompt Challenge: review kode search

Prompt review (tempel kode `search_announcements.dart`, `announcements_providers.dart`, dan `announcements_section.dart`):

```
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data), Riverpod, Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

## 7. Tabel usulan AI vs keputusan

Draf keputusan di bawah adalah usulan awal. Ubah kalau kamu tidak setuju, dan pastikan kamu bisa menjelaskan tiap baris tanpa membuka AI.

| File | Usulan AI | Keputusan (draf) | Alasan |
|---|---|---|---|
| `search_announcements.dart` | use case murni, filter judul | Terima | tanpa dependensi Flutter, mudah diuji, di bawah 40 baris |
| `announcements_providers.dart` | Notifier untuk query + provider turunan | Terima | state di presentation, aturan di domain |
| `announcement_search_field.dart` | field punya controller sendiri | Terima + dicek | controller diisi dari query tersimpan agar tidak beda dengan provider |
| `announcement_empty_state.dart` | widget terpisah | Terima | UI saja |
| `announcements_section.dart` | gabungan field + daftar | Terima | memecah `HomePage` supaya tetap kecil |
| `home_page.dart` | ganti blok `when` dengan section | Terima | `HomePage` tidak lagi mengimpor GoRouter/routes |
| Test | 5 unit + 4 widget | Terima | mencakup sukses, gagal, dan empty state |

## 8. Refactoring Challenge

- [x] Aturan filter ada di use case domain yang murni, bukan di widget.
- [x] Tidak ada import lintas layer (lihat perintah grep langkah 2).
- [x] Tiap fungsi di bawah 40 baris; hasil AI dipecah menjadi 1 use case + 3 widget kecil.