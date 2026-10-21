# jadiGuna — Marketplace Barang Bekas dan Berbagi Barang Berbasis Lokasi

> **Tugas Akhir Pemrograman Aplikasi Mobile**  
> Inspirasi Konsep: Jimoty (Platform Iklan & Komunitas Lokal)  
> Platform: Android menggunakan Flutter & Dart  
> Backend & Database: Supabase (PostgreSQL, Auth, Storage, Realtime) + SQLite Lokal (`sqflite`)

---

## 📱 Ringkasan Proyek

**jadiGuna** adalah aplikasi mobile berbasis lokasi yang memfasilitasi transaksi jual, beli, barter, dan pemberian (hibah) barang bekas yang masih layak pakai. Aplikasi dirancang khusus untuk mempermudah mahasiswa, penghuni kos, dan keluarga menemukan barang kebutuhan sehari-hari secara terjangkau, sekaligus mempromosikan gaya hidup sirkular (*circular economy*) guna mengurangi penumpukan limbah padat.

---

## 🌟 Fitur Utama & Kesesuaian Dokumen Rancangan (`jadiguna.md`)

### 1. Akun & Keamanan (Autentikasi & Session)
- **Registrasi & Login Akun**: Email dan password dengan validasi ketat. Password tidak disimpan sebagai teks biasa dan dikelola melalui Supabase Auth / Local Session.
- **Login Biometrik**: Dukungan autentikasi sidik jari (*fingerprint*) dan pengenalan wajah perangkat via `local_auth`.
- **Session Management**: Mempertahankan sesi aktif pengguna secara aman pada SharedPreferences & Supabase SDK.
- **Profil & Edit Profil**: Mengubah nama, bio, nomor WhatsApp/telepon, kota, dan foto profil.

### 2. Marketplace Iklan Barang
- **Beranda Interaktif**: Banner eco-lifestyle, filter kategori horizontal, daftar barang gratis, dan daftar barang terbaru di sekitar.
- **Pasang & Edit Iklan**: Pengisian judul, kategori, kondisi barang, opsi barang gratis (Rp 0) vs berbayar (IDR), lokasi, dan unggah foto.
- **Detail Barang**: Carousel foto, badge status ("Tersedia", "Dalam Kesepakatan", "Selesai"), perkiraan jarak lokasi LBS, tips keamanan transaksi COD, dan profil pemilik barang.
- **Iklan Saya**: Tab status untuk mengelola iklan yang dimiliki (Tersedia, Dalam Kesepakatan, Selesai) serta opsi ubah status dan hapus.
- **Favorit**: Menyimpan barang yang disukai untuk dilihat kembali kapan saja.

### 3. Pencarian & Filter Multi-Kriteria
- Pencarian kata kunci real-time (*search debounce*).
- Filter kategori (Furnitur, Elektronik, Buku, Pakaian, Perlengkapan Rumah, Alat Olahraga, Hobi & Mainan, dll).
- Filter khusus **Hanya Barang Gratis (Rp 0)**.
- Filter rentang harga dan kondisi fisik barang.
- Pengurutan hasil: Terbaru, Termurah, Termahal, dan Terdekat berdasarkan koordinat GPS pengguna.

### 4. Layanan Berbasis Lokasi (LBS - Location-Based Service)
- Membaca koordinat satelit GPS perangkat via `geolocator`.
- Menghitung jarak perkiraan secara otomatis menggunakan formula Haversine (contoh: *"850 m dari Anda"* atau *"2.4 km dari Anda"*).
- Pemilihan kota/wilayah manual jika izin GPS tidak diaktifkan.
- Menjaga privasi: alamat detail spesifik tidak dipublikasikan ke publik demi keselamatan.

### 5. Chat & Negosiasi Barang
- Menghubungi pemilik barang secara langsung dari halaman detail barang.
- Riwayat pesan chat dengan timestamp dan status terbaca.
- Template pertanyaan cepat (*Quick Reply Chips*): *"Apakah barang masih ada kak?"*, *"Bisa nego harga?"*, *"Bisa ketemuan COD di mana ya?"*.
- Simulasi auto-reply penjual interaktif untuk demonstrasi pengujian.

### 6. Notifikasi Mobile
- Menggunakan `flutter_local_notifications`.
- Notifikasi lokal instan untuk pesan masuk baru dan pembaruan status iklan.
- Pengaturan aktif/nonaktif notifikasi di menu Pengaturan.

---

## 🎯 Fitur Tambahan Sesuai Ketentuan Tugas Akhir

### 7. Konversi Mata Uang
- Konversi nominal antara **IDR (Rupiah)**, **USD (Dollar)**, **JPY (Yen)**, **EUR (Euro)**, dan **SGD (Dollar Singapura)**.
- Integrasi API nilai tukar waktu nyata (*live exchange rate*) dengan penanganan **mode offline** dan penanda waktu pembaruan terakhir.

### 8. Konversi Waktu & Zona
- Konversi tanggal dan jam antar zona waktu Indonesia dan internasional:
  - **WIB** (Asia/Jakarta, UTC+7)
  - **WITA** (Asia/Makassar, UTC+8)
  - **WIT** (Asia/Jayapura, UTC+9)
  - **London** (Europe/London, GMT UTC+0 / BST UTC+1 dengan penyesuaian otomatis *Daylight Saving Time*).
- Pemilihan tanggal dan jam fleksibel (*Date & Time Picker*).

### 9. Sensor Perangkat (2 Sensor)
- **Sensor 1 — Accelerometer (Goyangan / Shake Detection)**:
  - Menggoyangkan perangkat untuk mengacak dan me-refresh rekomendasi barang di beranda.
  - Dilengkapi tombol simulasi alternatif di layar agar dapat diuji pada emulator Android tanpa sensor fisik.
- **Sensor 2 — Gyroscope (Kemiringan / Tilt Orientation)**:
  - Mendeteksi rotasi perangkat untuk efek pratinjau 3D tilt kartu foto barang.
  - Dilengkapi slider kemiringan manual untuk pengujian emulator.

### 10. Mini Game: Pilah Barang
- Mini game bertema lingkungan untuk memilah barang bekas ke wadah kategori yang sesuai (Elektronik, Furnitur, Buku, Pakaian, Perlengkapan).
- Sistem skor, batas waktu 35 detik, combo multiplier, dan pesan edukasi daur ulang serta *circular economy*.

### 11. Demonstrasi Blockchain Sederhana (SHA-256)
- Rantai blok kriptografis yang mencatat riwayat perubahan status barang (Dibuat -> Dalam Kesepakatan -> Selesai).
- Setiap blok memuat: `block_index`, `timestamp`, `listing_id`, `item_title`, `status`, `actor_name`, `previous_hash`, dan `hash` (SHA-256).
- **Fitur Verifikasi Keutuhan Rantai**: Memeriksa apakah seluruh rantai blok valid.
- **Fitur Simulasi Manipulasi Data (Tamper Test)**: Memungkinkan dosen penguji mengubah isi data satu blok untuk membuktikan secara visual bagaimana algoritma SHA-256 mendeteksi kecurangan/manipulasi data!

### 12. Asisten AI / LLM (Iklan Pintar)
- Membantu pengguna menyusun draf deskripsi iklan yang rapi dan informatif hanya dari judul dan kata kunci ringkas.
- Rekomendasi kategori otomatis berdasarkan analisis teks judul.
- Saran kata kunci pencarian (*search tags*).
- Fitur *Poles Teks* untuk merapikan gaya bahasa deskripsi.

### 13. Saran dan Kesan
- Formulir masukan aplikasi dengan rating bintang (1-5), kategori masukan, pesan, dan riwayat masukan yang tersimpan di database lokal.

---

## 📂 Struktur Folder Proyek

```text
lib/
├── main.dart                      # Inisialisasi awal app, DB, dan notifikasi
├── app.dart                       # Root MaterialApp dan MultiProvider
├── core/
│   ├── constants/                 # AppColors, AppConstants, SupabaseConstants
│   ├── theme/                     # AppTheme (Light & Dark Mode)
│   ├── utils/                     # CurrencyFormatter, DateFormatter, LocationHelper
│   └── database/                  # LocalDatabase (SQLite sqflite) & SampleData
├── models/                        # UserModel, ListingModel, CategoryModel, MessageModel, BlockModel, FeedbackModel
├── services/                      # AuthService, ListingService, FavoriteService, ChatService, LocationService,
│                                  # CurrencyService, AiService, BiometricService, NotificationService, SensorService, BlockchainService
├── providers/                     # AuthProvider, ListingProvider, ChatProvider, ThemeProvider
├── screens/
│   ├── splash/                    # SplashScreen (Logo, animasi, routing)
│   ├── onboarding/                # OnboardingScreen (Pengenalan konsep Jimoty & fitur)
│   ├── auth/                      # LoginScreen, RegisterScreen, ForgotPasswordScreen
│   ├── main_navigation_screen.dart# Navigasi 5 Tab Bottom Bar + Listener Shake
│   ├── home/                      # HomeScreen (Hero banner, kategori, barang gratis, terbaru)
│   ├── search/                    # SearchScreen (Pencarian & multi-filter)
│   ├── listing/                   # ListingDetailScreen, AddEditListingScreen, MyListingsScreen
│   ├── favorites/                 # FavoritesScreen
│   ├── chat/                      # ChatListScreen, ChatDetailScreen
│   ├── profile/                   # ProfileScreen, EditProfileScreen, SettingsScreen, HelpPrivacyScreen
│   ├── converters/                # CurrencyConverterScreen, TimeConverterScreen
│   ├── sensors/                   # SensorsScreen (Accelerometer & Gyroscope live dashboard)
│   ├── mini_game/                 # PilahBarangGameScreen
│   ├── blockchain/                # BlockchainHistoryScreen (Ledger SHA-256 & Tamper Test)
│   ├── ai/                        # AiAssistantScreen
│   └── feedback/                  # FeedbackScreen (Saran dan Kesan)
└── widgets/                       # ListingCard, CategoryChip, CustomButton, CustomTextField, EmptyState, ErrorState
```

---

## 🚀 Panduan Menjalankan Aplikasi

### Prasyarat
- Flutter SDK (versi >= 3.13)
- Android Studio / VS Code / Antigravity IDE
- Perangkat Android fisik atau Emulator Android (dengan developer mode & sensor aktif)

### Langkah Menjalankan:
1. Unduh atau clone repositori ini:
   ```bash
   cd jadiguna
   ```
2. Pasang dependensi Flutter:
   ```bash
   flutter pub get
   ```
3. Jalankan analisis kode untuk memastikan tidak ada error:
   ```bash
   flutter analyze
   ```
4. Jalankan aplikasi pada emulator atau perangkat fisik Android:
   ```bash
   flutter run
   ```

### Mode Offline / SQLite First
Aplikasi secara bawaan telah dilengkapi **database lokal SQLite (`sqflite`)** dan data awal (*sample data*) realistis dalam Bahasa Indonesia. Aplikasi dapat langsung digunakan untuk demonstrasi seluruh alur login, pasang iklan, pencarian, favorit, chat, sensor, game, konversi, dan blockchain **tanpa memerlukan internet**.

### Menghubungkan ke Supabase Cloud (Opsional)
Jika ingin mengaktifkan backend online Supabase:
1. Buat proyek baru di [Supabase.com](https://supabase.com).
2. Buka menu **SQL Editor** di dashboard Supabase dan jalankan skrip `supabase_schema.sql` yang telah disediakan di root proyek ini.
3. Buka file `lib/core/constants/supabase_constants.dart` dan masukkan `supabaseUrl` serta `supabaseAnonKey` Anda.
4. Aplikasi otomatis beralih ke mode sinkronisasi Supabase Cloud!
