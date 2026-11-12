## 1. Ringkasan fitur

Optimasi performa pada **Campus Notify** (Minggu 11). Repository pengumuman
sekarang mengambil data dari API palsu (200 item, latensi 600 ms) dan menyimpannya
di cache lokal Hive. Halaman chat dan beranda dibangun ulang secara lebih
terarah, dan daftar pengumuman dibangun malas.

Cara melihat hasilnya: jalankan `flutter run --profile`, buka beranda (daftar
pengumuman), lalu ikon robot (chat) dan bandingkan di DevTools.

## 2. Arsitektur

```
presentation  HomePage, AnnouncementsSection (ListView.builder),
              ChatPage (widget kecil + select), providers
      |
      v
domain        GetAnnouncements, SearchAnnouncements
              AnnouncementRepository (interface, tidak berubah)
      ^
      |
data          AnnouncementRepositoryImpl (Cache-First TTL)
              AnnouncementRemoteDataSource -> FakeAnnouncementApi
              AnnouncementCache -> HiveAnnouncementCache
```

| Lapisan | File utama | Tanggung jawab |
|---|---|---|
| data | `announcement_repository_impl.dart` | strategi cache: segar -> cache, kedaluwarsa -> API, gagal -> cache lama |
| data | `announcement_remote_data_source.dart` | API palsu 200 item + delay |
| data | `announcement_cache.dart`, `hive_announcement_cache.dart` | kontrak cache dan implementasi Hive (JSON string, init malas) |
| presentation | `announcements_section.dart` | daftar lazy `ListView.builder`, navigasi `context.push` |
| presentation | `home_page.dart` | tanpa `ref.watch` di Scaffold; `_FcmTokenTile` terpisah |
| presentation | `chat_page.dart`, `chat_message_list.dart` | `select` per field, `RepaintBoundary` per bubble |

Perubahan pada fitur lain: tidak ada. Interface `AnnouncementRepository`,
use case, auth, notifications, dan logika chat tidak diubah.

## 3. Konfigurasi

| Item | Nilai |
|---|---|
| Jumlah data API palsu | 200 (`FakeAnnouncementApi.totalCount`) |
| Latensi API palsu | 600 ms |
| Cache | Hive box `announcement_cache`, satu key `list` (JSON) |
| TTL cache | 5 menit (`ttl` di `AnnouncementRepositoryImpl`) |
| Dependency baru | `hive_ce`, `hive_ce_flutter` |

## 4. Cara menjalankan

1. `flutter pub get`
2. `flutter run --profile` di perangkat fisik.
3. Buka DevTools dari link di terminal, tab Performance dan Memory.
4. Ulangi skenario: daftar + scroll + search, detail bolak-balik 5x, chat streaming.

## 5. Tabel risiko dan mitigasi

| Risiko | Dampak | Mitigasi di aplikasi | Sisa risiko |
|---|---|---|---|
| Data cache basi | pengumuman terbaru terlambat tampil | TTL 5 menit, cache diganti tiap ambil dari API | belum ada pull-to-refresh |
| Hive gagal dibuka / rusak | cache tidak berfungsi | semua baca/tulis cache dibungkus try/catch, app jatuh ke API | tanpa cache, tiap buka app menunggu API |
| Cache menyimpan data lama saat API mati | pengguna melihat info usang tanpa penanda | fallback hanya bila tidak ada data segar | tidak ada indikator "data offline" di UI |
| Pencarian hanya di judul pada data yang dimuat | hasil terbatas | semua 200 item dimuat; pencarian lokal | data jauh lebih besar membutuhkan pagination + pencarian server |
| Optimasi tanpa bukti ukur | klaim peningkatan tidak terbukti | temuan diberi status bukti; angka after dikosongkan sampai diukur | perlu rekaman before/after |
