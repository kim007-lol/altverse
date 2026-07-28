# Brainstorming & Arsitektur Web Admin (AU Reader V2)

Berdasarkan kebutuhan aplikasi *comic/novel reading* seperti AU Reader V2, sebuah Web Admin tidak hanya berfungsi untuk melihat data, tetapi harus bisa menjaga ekosistem aplikasi (moderasi konten, mencegah penipuan finansial, dan menjaga komunitas). 

Berikut adalah hasil *deep reasoning* dan rencana arsitektur untuk membangun Web Admin menggunakan Next.js dan merapikan backend Golang.

---

## 1. Kebutuhan Fitur Admin (Deep Reasoning)
Sebagai admin aplikasi platform kreator (seperti Webtoon/Wattpad), ini adalah fitur-fitur yang **wajib** ada untuk mengelola platform dengan baik:

### A. Dashboard Overview (Pusat Kendali)
Admin butuh melihat "kesehatan" aplikasi dalam satu pandangan.
- **Metrik Utama:** Total User Aktif, Total Author, Pendapatan Platform (Top-Up), dan Uang Keluar (Withdrawal).
- **Alerts:** Jumlah laporan (report) yang belum ditangani, jumlah permintaan penarikan dana (withdrawal) yang menunggu persetujuan.

### B. User Management (Pembaca & Author)
- **Tabel User:** Melihat daftar seluruh user, role mereka, dan jumlah saldo koin/uang mereka.
- **Moderasi User:** Fitur untuk **Suspend / Banned** user yang melanggar aturan.
- **Author Verification:** Jika kedepannya author butuh verifikasi KTP/Identitas sebelum bisa menarik dana.

### C. Content Moderation (Moderasi Karya)
Karya yang melanggar pedoman komunitas (misal: NSFW ekstrem, plagiarisme) harus bisa ditindak.
- **Tabel Series & Episode:** Melihat semua karya yang di-publish.
- **Takedown:** Admin bisa menyembunyikan (take down) atau menghapus series/episode yang dilaporkan.

### D. Finance & Transactions (Urat Nadi Platform)
- **Top-Up History:** Memantau aliran uang masuk dari pembaca.
- **Withdrawal Management:** (Sangat Krusial). Author yang meminta pencairan dana harus disetujui secara manual/otomatis oleh admin. Admin mengunggah bukti transfer, lalu mengubah status menjadi `Success` (Sebagian API-nya sudah ada di Golang, tinggal kita lengkapi).

### E. Report Management (Laporan Komunitas)
- Menangani laporan dari user (misal: "Komentar ini spam", "Series ini plagiat").
- Admin bisa mereview laporan, mengambil tindakan (hapus komentar, tegur author), dan menutup status laporan menjadi `Resolved`.

---

## 2. Arsitektur Golang Backend (Clean & Maintainable)
Saat ini semua route ditumpuk di dalam `api.go`. Agar mudah di-*maintain* dan di-*tracking*, kita akan melakukan *refactoring* khusus untuk admin.

**Rencana Struktur Folder Backend:**
```text
backend_golang/
├── controllers/
│   └── admin/
│       ├── dashboard_controller.go   # Handle statistik
│       ├── user_controller.go        # Handle list user & suspend
│       ├── content_controller.go     # Handle moderasi series/episode
│       ├── finance_controller.go     # Handle top-up history & withdrawal
│       └── report_controller.go      # Handle report resolving
├── routes/
│   ├── api.go          # Entry point routing
│   ├── admin_routes.go # KHUSUS menampung semua route /api/v1/admin/*
│   └── public_routes.go# (Opsional) untuk memisahkan route auth/reader
```

**Konsep Routing Bersih (Clean Routing):**
Nantinya di `api.go` kita cukup memanggil:
```go
adminGroup := v1.Group("/admin", middleware.Auth(), middleware.AdminOnly())
routes.RegisterAdminRoutes(adminGroup, ctrl) // Semua route admin didefinisikan di file terpisah
```
Ini membuat `api.go` tidak bengkak hingga ratusan baris.

---

## 3. Arsitektur Next.js (web_admin)
Kita akan membuat directory baru `d:\AU_Reader_V2\web_admin`.

**Tech Stack Pilihan:**
1. **Framework:** Next.js 14 (App Router) dengan TypeScript.
2. **Styling & UI:** Tailwind CSS + **Shadcn UI**. Shadcn UI sangat sempurna untuk dashboard admin karena komponennya (Data Tables, Dialogs, Cards, Forms) terlihat sangat modern, bersih, dan profesional ala Vercel/Stripe.
3. **Data Fetching:** React Query (TanStack Query) dipadukan dengan Axios. Ini membuat tabel admin terasa cepat, punya fitur *caching*, dan mudah di-*refresh* setelah admin melakukan aksi (misal: setelah klik "Approve Withdrawal", tabel otomatis update tanpa reload page).
4. **State Management:** Zustand (untuk menyimpan state login admin).

**Struktur Direktori `web_admin`:**
```text
web_admin/
├── src/
│   ├── app/
│   │   ├── (auth)/login/page.tsx       # Halaman Login Admin
│   │   ├── (dashboard)/
│   │   │   ├── page.tsx                # Overview Dashboard
│   │   │   ├── users/page.tsx          # Manajemen User
│   │   │   ├── content/page.tsx        # Moderasi Konten
│   │   │   ├── finance/page.tsx        # Keuangan & Withdrawal
│   │   │   └── reports/page.tsx        # Laporan
│   │   ├── layout.tsx                  # Sidebar & Navbar Admin
│   ├── components/
│   │   ├── ui/                         # Komponen Shadcn UI
│   │   ├── shared/                     # Custom components (Tabel, Cards)
│   ├── lib/
│   │   ├── api.ts                      # Konfigurasi Axios & interceptors
│   │   └── utils.ts
│   └── hooks/                          # Custom hooks untuk React Query
```

---

## 💡 Tahapan Eksekusi (Langkah Selanjutnya)
Jika kamu setuju dengan arsitektur dan *brainstorming* di atas, saya sarankan kita mengeksekusinya dengan urutan ini:

1. **Fase 1: Setup Next.js & UI Foundation**
   - Inisialisasi Next.js di folder `web_admin`.
   - Setup Tailwind, Shadcn UI, dan membuat Layout dasar (Sidebar menu).
   - Buat halaman Login dan hubungkan ke backend Golang.

2. **Fase 2: Refactor Golang Routing & Buat Endpoint Dasar**
   - Pecah `api.go` dan buat `admin_routes.go`.
   - Buat `dashboard_controller.go` untuk menarik data statistik awal.
   - Tampilkan data statistik tersebut di halaman depan Next.js.

3. **Fase 3: Selesaikan Fitur per Modul**
   - Modul Keuangan (Withdrawal & Top-Up).
   - Modul User (List & Banned).
   - Modul Moderasi & Report.

Apakah desain arsitektur dan urutan eksekusinya sudah sesuai dengan yang kamu bayangkan? Atau ada fitur khusus lain yang ingin ditambahkan?
