# Implementation Plan — AU Reader V2: Fix & Feature Completion

## Ringkasan

Perbaikan 7 item yang sudah diidentifikasi dari deep dive codebase: 4 bug nyata + 2 fitur setengah jalan + 1 fitur baru (popular authors).

---

## Scope Lengkap

### 🔴 BUG 1: Leaderboard — item tidak bisa diklik ke profil

**File:** `leaderboard_screen.dart`
**Masalah:** `_buildRankTile()` dibungkus `Container` biasa, tidak ada `onTap`.
**Fix:** Ganti `Container` luar menjadi `InkWell` dengan routing:

- Type `xp` / `supporter` → `ReaderProfileScreen(userId: uid)`
- Type `author` → `AuthorProfileScreen(authorId: uid)`

---

### 🔴 BUG 2: Top Supporters di Author Profile — tidak bisa diklik

**File:** `author_profile_screen.dart`
**Masalah:** `ListView.builder` supporter list berisi `Container` tanpa `InkWell`.
**Fix:** Wrap dengan `GestureDetector`, navigate ke `ReaderProfileScreen(userId: user['id'])`.

---

### 🔴 BUG 3: Settings & Help Center — menu kosong

**File:** `reader_profile_screen.dart` + 2 file baru
**Masalah:** `onTap: () {}` (tidak melakukan apa-apa).

**Settings Screen** (baru): Berisi:

- Toggle Dark Mode (switch langsung sambungkan ke `AuthProvider.toggleThemeMode()`)
- Notifikasi: episode baru, komentar dibalas, like pada komentar (toggle, simpan ke `notifications/preferences`)
- Clear Reading History (confirm dialog → API call)
- App Version (statis, ambil dari `package_info_plus`)

**Help Center Screen** (baru): Berisi:

- Tombol "Hubungi Kami via Instagram" → buka link eksternal Instagram (diisi hardcode URL Instagram support yang nanti bisa kamu ganti)
- FAQ statis 5-7 poin umum (cara top-up, cara unlock episode, cara daftar jadi author, dll)

---

### 🟡 BUG 4: Dark Mode — backend ada, UI tidak ada

**File:** `auth_provider.dart`, `reader_profile_screen.dart`
**Temuan:** `toggleThemeMode()` dan `isDarkMode` **sudah ada di AuthProvider**. `main.dart` sudah wire `themeMode: auth.themeMode`. Yang kurang hanya: **tidak ada tombol toggle di UI**.
**Fix:** Tambah toggle switch di Settings Screen (item 1 di atas) — tidak perlu buat provider baru.

---

### 🟡 BUG 5: Share Series — method dipanggil tapi tidak didefinisikan

**File:** `series_detail_screen.dart`
**Temuan:** `val == 'share'` memanggil `_shareSeries()` di popup menu (line 698) tapi method `_shareSeries()` **tidak ada di file** → akan crash saat ditekan.
**Fix:** Tambah method `_shareSeries()` yang memanggil `Share.shareUri()` dari `share_plus`:

```
"Baca [Judul Series] oleh [Nama Author] di AU Reader! 📚
auread://series/{id}"
```

Import `share_plus` sudah ada di pubspec.

---

### 🟢 FITUR: Popular Authors di Home Screen

**File:** `home_screen.dart`, backend Go `discover_controller.go`
**Temuan:** Tidak ada data `popular_authors` dari API dan tidak ditampilkan di UI.
**Rencana:**

- Backend Go: Tambah field `popular_authors` ke response `/reader/fyp` — query 5 author dengan followers terbanyak
- Frontend: Tambah section "Popular Authors" setelah "Trending Now", horizontal scroll, setiap kartu menampilkan avatar + pen_name + tier badge + tombol Follow, bisa diklik ke `AuthorProfileScreen`

---

## File yang Diubah / Dibuat

### Frontend

| Status | File                                              | Perubahan                                            |
| ------ | ------------------------------------------------- | ---------------------------------------------------- |
| MODIFY | `leaderboard_screen.dart`                         | Wrap tile dengan InkWell + routing                   |
| MODIFY | `author_profile_screen.dart`                      | Wrap supporter tile dengan GestureDetector + routing |
| MODIFY | `reader_profile_screen.dart`                      | Wire Settings dan Help Center ke screen baru         |
| MODIFY | `series_detail_screen.dart`                       | Tambah method `_shareSeries()`                       |
| MODIFY | `home_screen.dart`                                | Tambah section Popular Authors                       |
| NEW    | `features/shared/screens/settings_screen.dart`    | Settings screen lengkap                              |
| NEW    | `features/shared/screens/help_center_screen.dart` | Help Center + FAQ + Instagram link                   |

### Backend Go

| Status | File                                        | Perubahan                              |
| ------ | ------------------------------------------- | -------------------------------------- |
| MODIFY | `controllers/reader/discover_controller.go` | Tambah popular_authors ke FYP response |

---

## Pertanyaan Terakhir Sebelum Eksekusi

> [!IMPORTANT]
> **Instagram URL**: Untuk Help Center, link Instagram support-nya apa? Format: `https://instagram.com/[username_kamu]`
> Kalau belum ada, saya pakai placeholder yang bisa kamu ganti nanti.

> [!NOTE]
> **Popular Authors**: Apakah cukup 5 author? Dan kriteria sorting-nya: berdasarkan jumlah followers, atau bisa juga berdasarkan series yang paling banyak dibaca bulan ini?

> [!NOTE]
> **App Version**: Package `package_info_plus` sudah ada di pubspec.yaml? Kalau tidak ada saya bisa pakai versi statis ("1.0.0") saja.

---

## Urutan Eksekusi

1. Fix \_shareSeries() (paling critical — crash)
2. Fix leaderboard click
3. Fix supporter click
4. Settings Screen (dark mode toggle + notif prefs)
5. Help Center Screen
6. Wire Settings & Help Center ke profile
7. Popular Authors (backend + frontend)

Searched for "Share\."
Viewed reader_profile_screen.dart:430-520
Searched for "Dark Mode\|dark_mode\|brightness\|Brightness"
Searched for "InkWell\|onTap.*uid\|onTap.*userId"
Viewed reader_profile_screen.dart:650-750
Viewed author_profile_screen.dart:780-810

Sudah cukup data. Sekarang saya sudah punya gambaran lengkap dari seluruh codebase. Mari kita **brainstorming**.

---

## 🔍 Hasil Deep Dive — Temuan Faktual dari Kode

Sebelum brainstorming, inilah yang saya temukan langsung dari kodenya:

### ✅ Yang Sudah Jalan Dengan Baik

- **Avatar di comment drawer** → sudah bisa diklik, langsung ke profil (author atau reader). ✔️
- **Avatar di series detail (author row)** → sudah bisa diklik ke AuthorProfile. ✔️
- **Avatar di search hasil user** → sudah bisa diklik ke profil yang sesuai. ✔️
- **Source URL / Wattpad link di Series Detail** → sudah ada UI-nya dan bisa diklik ke eksternal. ✔️
- **Wattpad di Author Profile** → sudah ada (bisa diisi di edit profil author). ✔️

### ❌ Yang Mockup-nya Ada Tapi Tidak Berfungsi / Kosong

1. **Leaderboard — avatar & nama TIDAK bisa diklik** → `_buildRankTile()` dibungkus `Container` biasa, tidak ada `onTap`. Orang di leaderboard tidak bisa diklik ke profilnya, padahal di sosmed manapun ini selalu bisa.

2. **Top Supporters di Author Profile — TIDAK bisa diklik** → `ListView.builder` berisi `Container` biasa tanpa `InkWell`/`GestureDetector`. Kamu bisa lihat nama supporter tapi tidak bisa tap ke profil mereka.

3. **Settings di Reader Profile — KOSONG** → `onTap: () {}` (tidak ada navigasi). Menu "Settings" ada di UI tapi tidak ke mana-mana.

4. **Help Center di Reader Profile — KOSONG** → sama, `onTap: () {}`.

5. **Dark Mode** → **TIDAK ADA implementasinya sama sekali** di codebase. Doc bilang ada, guide bilang ada, tapi ThemeMode/brightness toggle tidak ditemukan di satu pun file dart. Hanya `isDark` untuk membaca state tema saat ini, tidak ada toggle.

6. **Share series** → `share_plus` diimport di `series_detail_screen.dart` tapi tidak ada `Share.shareUri()` atau sejenisnya yang terpanggil. Tombol share kemungkinan ada di UI tapi tidak terhubung.

7. **Popular Authors di Home Screen** → bagian ini **tidak ada** di home screen sama sekali. Dokumen guide menyebutkannya, tapi `_data['popular_authors']` tidak dipanggil di `home_screen.dart`.

---

## 💬 Brainstorming — Mari Diskusi

Dari temuan di atas, ada **prioritas yang berbeda-beda**. Saya bagi jadi 3 kelompok supaya kita bisa diskusi mana yang mau digarap duluan:

### 🔴 Kelompok 1 — Harus Diperbaiki Segera (Bug Nyata)

Ini bukan fitur baru, tapi **yang ada sudah setengah jalan**:

**A. Leaderboard items tidak bisa diklik ke profil**
Kamu klik nama orang di ranking #1, tidak ada yang terjadi. Ini terasa broken.

**B. Top Supporters di halaman Author juga tidak bisa diklik**
Kamu lihat nama supporter, tapi tidak bisa ke profil mereka.

**C. Settings & Help Center kosong**
Ada di menu tapi tidak ke mana-mana. Bikin pengguna bertanya-tanya apakah app-nya crash.

---

### 🟡 Kelompok 2 — Fitur yang Sudah Direncanakan Tapi Belum Ada

**D. Dark Mode** — tidak ada sama sekali di kode, padahal user sudah bisa pilih tema warna. Ini pasangannya.

**E. Share series** — import sudah ada, tinggal disambungkan ke UI.

**F. Popular Authors di Home** — ada di panduan, ada di API (kemungkinan), tapi tidak ditampilkan.

---

### 🟢 Kelompok 3 — Hal yang Perlu Kita Diskusikan Desainnya

**G. Wattpad link di Series Detail**
Ini sudah jalan secara teknis. Tapi pertanyaannya: apakah author juga bisa mengisi link ini **per-series** (bukan hanya di profil author)? Saat ini link source URL diisi di form "Create Series" — apakah juga bisa diedit di halaman "Edit Series"?

**H. Home screen — Author name/avatar di series card tidak bisa diklik**
Di kartu series di Home, ada nama author tapi tidak bisa diklik ke profil author-nya. Konsisten dengan sosmed lain seharusnya bisa.

---

**Pertanyaan untuk brainstorming:**

1. Dari kelompok 1, mana yang paling mengganggu kamu secara pribadi saat pakai app ini?
2. Dark mode — apakah ini prioritas tinggi, atau masih bisa ditunda?
3. Untuk leaderboard dan top supporters yang bisa diklik — ketika diklik, mana yang lebih logis: langsung ke halaman profil penuh, atau muncul mini card/popup dulu?
