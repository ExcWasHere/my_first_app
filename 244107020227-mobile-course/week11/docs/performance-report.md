# Laporan Optimasi Performa - Campus Notify (Minggu 11)

## 1. Ruang lingkup dan cara kerja

Optimasi dilakukan pada project Minggu 10 (disalin menjadi `week11`). Karena
data pengumuman sebelumnya hanya 3 item hardcode, repository diganti menjadi
**API palsu** (200 item + latensi 600 ms) agar ada beban yang bisa dioptimasi.
Semua analisis kode dibantu AI; keputusan dan alasannya dirangkum di bawah.
**Verifikasi after belum dijalankan** (lihat bagian 5): angka after sengaja
dikosongkan, bukan diperkirakan.

## 2. Baseline

| Metrik | Nilai | Sumber |
|---|---|---|
| Rata-rata FPS (sesi startup) | 56 FPS | `before-profile.png` |
| Frame jank | Menumpuk di frame 3-10 (startup + memuat 200 item) | `before-profile.png` |
| Dart heap | 18,4 MB | `before-memory.png` |
| Instance `Announcement` | 201 | `before-memory.png` |
| `PUSH token diterima` setelah bolak-balik detail 5x | belum diukur | - |
| Jank saat scroll / search / chat streaming | belum diukur | - |

## 3. Temuan

Lihat `docs/performance-findings.md` (5 temuan, dengan status bukti masing-masing).

## 4. Optimasi yang diterapkan

| # | Teknik (jobsheet) | Perubahan | Alasan pemilihan | Trade-off |
|---|---|---|---|---|
| 1 | Riverpod `select` + ekstrak widget (D, B) | `ChatPage` tidak lagi `ref.watch` state penuh; dipecah jadi `_MessagesView`, `_InputArea`, `_ErrorBanner`, `_ClearChatButton`, `_QuotaText`, `_NoKeyBanner` yang masing-masing `select` field-nya saja | Streaming mengubah state puluhan kali per jawaban; tanpa `select`, AppBar, banner, dan input ikut rebuild tiap chunk | Lebih banyak class kecil di satu file |
| 2 | `RepaintBoundary` (C) | Tiap `ChatBubble` dibungkus `RepaintBoundary` + `ValueKey` | Hanya bubble yang sedang streaming yang berubah; bubble lama tidak perlu digambar ulang | Layer tambahan memakai sedikit memori; manfaat kecil untuk percakapan pendek |
| 3 | `ListView.builder` / lazy (5) + ekstrak widget | Beranda: `Column[FcmTile, Expanded(AnnouncementsSection)]`; daftar jadi `ListView.builder` dengan `_AnnouncementTile`; token FCM dipindah ke `_FcmTokenTile` (Consumer) | Sebelumnya 200 tile dibangun dan di-layout sekaligus; sekarang hanya yang terlihat. Perubahan token FCM tidak lagi membangun ulang Scaffold | Tile FCM debug tidak ikut ter-scroll; `AnnouncementsSection` butuh parent dengan tinggi terbatas |
| 4 | Repository cache (8) | `AnnouncementRepositoryImpl` memakai `AnnouncementRemoteDataSource` + `AnnouncementCache` (Hive). Strategi **Cache-First (TTL 5 menit) + fallback stale saat API gagal** | Daftar jarang berubah; menghindari request 600 ms berulang dan membuat app tetap berguna saat offline | Data bisa tertinggal sampai 5 menit; belum ada pull-to-refresh. Jobsheet memberi contoh stale-while-revalidate, tetapi interface repository berupa `Future` tunggal sehingga tidak bisa meng-emit dua kali tanpa mengubah semua use case dan test; Cache-First + TTL dipilih sebagai strategi yang setara dengan risiko perubahan lebih kecil |
| 5 | Kurangi request & memori (analisis kode) | Navigasi ke detail memakai `context.push` (beranda tetap hidup); `announcementProvider` jadi `autoDispose`; detail diambil dari cache bila ada | Mencegah `HomePage.initState` (dan `PushController.start()`) berjalan lagi tiap kembali dari detail, mempertahankan posisi scroll, dan mencegah state per-id menumpuk | `AnnouncementPage` harus menangani dua kasus back (ada/tidak ada halaman di bawahnya) |

Test: `announcement_repository_cache_test.dart` (7 kasus strategi cache) dan
tambahan satu test widget yang memastikan daftar 500 item dibangun malas.

## 5. Hasil verifikasi (after)

Belum diukur. Untuk melengkapi, ulangi skenario yang sama dengan baseline
(daftar + scroll + search, detail bolak-balik 5x, chat streaming), lalu isi:

| Metrik | Before | After |
|---|---|---|
| Frame jank saat scroll + search | belum diukur | ... |
| Rata-rata frame time | belum diukur | ... |
| Dart heap setelah bolak-balik detail 5x | 18,4 MB (snapshot awal) | ... |
| `PUSH token diterima` setelah 5x bolak-balik | belum diukur | ... |
| Waktu daftar tampil pada pembukaan kedua (cache) | sekitar 600 ms (latensi API palsu) | ... |

Simpan screenshot sebagai `screenshots/after-profile.png`.

## 6. Refleksi

- **Dampak terbesar (dugaan, belum terukur):** pemecahan `ChatPage` dengan
  `select`, karena streaming adalah satu-satunya alur yang memicu perubahan
  state berulang dalam waktu singkat. Cache punya dampak terbesar pada waktu
  muat yang dirasakan pengguna, bukan pada frame time.
- **Cara memastikan bukan placebo:** bandingkan skenario identik di mode
  `--profile` pada perangkat yang sama (jumlah frame jank, frame time, jumlah
  rebuild di *Rebuild Stats*, heap). Tanpa langkah ini, klaim di atas
  hanyalah hipotesis.
- **Trade-off:** kode lebih terpecah (banyak widget kecil), data bisa basi
  sampai 5 menit, dan ada dependency baru (`hive_ce`).
- **Hindari optimasi prematur:** saat data hanya 3 item tidak ada masalah
  yang bisa diukur; optimasi baru bermakna setelah ada beban (200 item) dan
  bukti dari profiling.
