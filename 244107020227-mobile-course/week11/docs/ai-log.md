# AI Log: Jobsheet 10 (Integrasi Fitur AI)

Fitur: **chatbot asisten kampus** pada Campus Notify. Pengguna bertanya soal pengumuman, jawaban datang bertahap (streaming) dari model Llama 3.3 70B lewat Groq, dengan konteks dari data pengumuman.

## 1. Prompt pengembangan (formula 5 slot)

```
Peran: senior Flutter dev
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
  Riverpod (flutter_riverpod ^2.6.1), GoRouter, Dio. Dependency rule: domain
  tidak boleh mengimpor Flutter/Dio/Riverpod. Kontrak yang ditempel:
  Announcement, AnnouncementRepository, announcements_providers.dart,
  home_page.dart, app_router.dart, routes.dart, failures.dart, pubspec.yaml.
Tugas: tambah chatbot asisten kampus dengan konteks pengumuman, streaming
  response (SSE), API key di secure storage, fallback saat AI error, dan
  pembatas permintaan harian. Provider: Groq (gratis, model open-weight).
Batas: jangan ubah fitur announcements/auth/notifications. Aturan
  (validasi, kuota, penyusunan prompt) harus di use case domain yang murni.
  Dio untuk AI harus terpisah dari dioProvider (jangan kirim JWT ke pihak
  ketiga). Tiap fungsi maks 40 baris.
Output: kode + test (unit test aturan, parser SSE, 1 widget test) +
  cara uji manual.
```

**Catatan privasi:** tidak ada token FCM, JWT, API key, maupun `google-services.json` yang ditempel ke AI. Data pengumuman di project ini adalah data dummy.

## 2. Konteks yang ditempel

| File | Alasan ditempel |
|---|---|
| `pubspec.yaml` | versi package (Riverpod 2.x, Dio 5, secure storage sudah ada) |
| `announcement.dart` | bentuk entity (`id`, `title`, `body`) |
| `announcement_repository.dart` | kontrak data |
| `announcements_providers.dart` | sumber data konteks (`announcementsProvider`) |
| `failures.dart` | hierarki `Failure` (sealed, jadi tidak ditambah subclass baru) |
| `app_router.dart`, `routes.dart` | tempat menambah rute `/chat` |
| `home_page.dart` | tempat tombol masuk ke chat |

Yang sengaja **tidak** ditempel: `token_store.dart`, `api_client.dart`, `google-services.json`, token FCM, API key Groq.