# jadiGuna — Dokumen Rancangan Aplikasi Mobile

> **Nama tema/aplikasi:** jadiGuna
> **Tema:** Marketplace barang bekas dan berbagi barang berbasis lokasi  
> **Inspirasi konsep:** Jimoty, platform iklan lokal asal Jepang  
> **Platform:** Android menggunakan Flutter  
> **Status dokumen:** Rancangan awal untuk Tugas Akhir Pemrograman Aplikasi Mobile

---

## 1. Ringkasan Proyek

**jadiGuna** adalah aplikasi mobile yang mempertemukan orang-orang di sekitar lokasi pengguna untuk menjual, membeli, menukar, atau memberikan barang yang masih layak pakai. Aplikasi berfokus pada barang fisik, seperti furnitur, elektronik, buku, pakaian, perlengkapan rumah, alat olahraga, dan barang sehari-hari.

Konsep utama jadiGuna adalah membantu pengguna menemukan barang yang dibutuhkan dengan lebih terjangkau sekaligus memperpanjang masa pakai barang yang masih layak digunakan. Pengguna dapat memasang iklan barang, melihat detail barang, menyimpan barang favorit, menghubungi pemilik, dan menyepakati transaksi atau pengambilan barang.

Aplikasi ini terinspirasi oleh konsep marketplace lokal Jimoty, tetapi **bukan aplikasi resmi Jimoty dan tidak berafiliasi dengan Jimoty**.

### Batasan ruang lingkup

jadiGuna hanya berfokus pada barang. Aplikasi **tidak menyediakan** fitur pencarian pekerjaan, properti, layanan/jasa, komunitas, atau aktivitas lokal.

## 2. Latar Belakang

Barang yang sudah tidak digunakan sering kali masih layak pakai, tetapi akhirnya disimpan atau dibuang karena pemiliknya tidak mengetahui siapa yang membutuhkannya. Di sisi lain, orang lain mungkin sedang mencari barang serupa dengan harga yang lebih terjangkau.

jadiGuna dirancang untuk mempertemukan pemilik barang dan calon penerima/pembeli berdasarkan lokasi. Dengan adanya fitur iklan, pencarian, chat, dan penentuan lokasi, proses menemukan serta menyerahkan barang dapat menjadi lebih mudah.

## 3. Tujuan Aplikasi

1. Mempermudah pengguna menjual barang bekas yang masih layak pakai.
2. Memungkinkan pengguna memberikan barang secara gratis.
3. Membantu pengguna menemukan barang berdasarkan kategori, harga, dan lokasi.
4. Memfasilitasi komunikasi antara pemilik barang dan calon pembeli/penerima.
5. Mendorong penggunaan kembali barang dan mengurangi barang yang terbuang.
6. Menerapkan teknologi mobile seperti autentikasi, database lokal dan online, API, lokasi, sensor, notifikasi, AI/LLM, serta fitur tambahan sesuai ketentuan tugas.

## 4. Target Pengguna

- Mahasiswa dan penghuni kos yang membutuhkan barang dengan harga terjangkau.
- Keluarga atau individu yang ingin menjual barang yang tidak terpakai.
- Pengguna yang ingin memberikan barang secara gratis.
- Pengguna yang mencari barang bekas di sekitar wilayahnya.
- Pengguna yang ingin menukar barang dengan barang lain.

## 5. Teknologi yang Direncanakan

| Bagian | Teknologi yang disarankan | Kegunaan |
|---|---|---|
| Mobile | Flutter dan Dart | Membangun aplikasi Android |
| Backend dan layanan online | Supabase | Menyediakan database PostgreSQL, autentikasi, penyimpanan file, realtime, dan fungsi server bila diperlukan |
| Database online | Supabase Database (PostgreSQL) | Menyimpan data utama agar dapat diakses lintas perangkat |
| Database lokal | SQLite melalui paket Flutter seperti `sqflite` atau `drift` | Menyimpan cache iklan, favorit/cache preferensi, dan data lokal yang diperlukan saat offline |
| Autentikasi | Supabase Auth | Mengelola registrasi, login, sesi, dan pemulihan akun; password ditangani secara aman oleh Supabase Auth |
| Penyimpanan gambar | Supabase Storage | Menyimpan foto iklan dan foto profil dengan aturan akses yang sesuai |
| Lokasi | GPS/location service | Menentukan lokasi pengguna dengan izin |
| Sensor | Accelerometer dan gyroscope | Mengimplementasikan fitur berbasis gerakan/perangkat |
| AI/LLM | API model bahasa atau layanan AI yang sesuai | Membantu menulis deskripsi iklan dan memberi rekomendasi kategori |
| Notifikasi | Local notification dan/atau push notification | Mengingatkan pengguna tentang aktivitas aplikasi |
| Konversi | API nilai tukar atau data kurs yang diperbarui | Konversi mata uang pada menu tambahan |

**Catatan arsitektur dan keamanan:** Firebase tidak digunakan. Autentikasi online menggunakan Supabase Auth, database online menggunakan PostgreSQL di Supabase, dan database lokal menggunakan SQLite. Password tidak disimpan atau di-hash sendiri oleh aplikasi; Supabase Auth menangani autentikasi dan penyimpanan kredensial. Aktifkan Row Level Security (RLS) pada tabel yang dapat diakses dari aplikasi. Kunci `service_role` Supabase tidak boleh dimasukkan ke aplikasi Flutter; gunakan hanya publishable/anon key dengan kebijakan RLS yang benar. Operasi yang membutuhkan rahasia, seperti panggilan AI, dilakukan melalui Supabase Edge Functions atau server aman.

## 6. Daftar Fitur Aplikasi

### 6.1 Akun dan keamanan

1. **Registrasi akun** — pengguna membuat akun dengan nama, email, dan password.
2. **Login dengan password aman** — autentikasi ditangani Supabase Auth; password tidak disimpan sebagai teks biasa oleh aplikasi.
3. **Session/token management** — aplikasi mempertahankan sesi login dengan token yang aman, memiliki masa berlaku, dan dapat dicabut saat logout.
4. **Login biometrik** — pengguna dapat membuka akses lokal aplikasi menggunakan sidik jari atau pengenalan wajah perangkat yang didukung. Biometrik perangkat tidak menggantikan autentikasi backend.
5. **Logout** — mengakhiri sesi pengguna dan menghapus token lokal yang sensitif.
6. **Profil pengguna** — menampilkan nama, foto profil, dan informasi dasar yang dipilih pengguna.
7. **Edit profil** — pengguna dapat memperbarui nama, foto, atau informasi profil.
8. **Validasi formulir** — memastikan data wajib terisi dan format email/password sesuai aturan.
9. **Pengelolaan izin** — meminta izin hanya ketika diperlukan, misalnya lokasi atau biometrik.
10. **Lupa password** — alur pemulihan akun melalui fitur pemulihan yang disediakan Supabase Auth.

### 6.2 Beranda dan navigasi

1. **Beranda** — menampilkan pencarian, kategori barang, barang terbaru, dan barang gratis.
2. **Bottom navigation** — menu Beranda, Favorit, Pasang Iklan, Pesan, dan Profil.
3. **Menu profil** — berisi data pengguna, iklan saya, pengaturan, saran dan kesan, serta logout.
4. **Kategori barang** — furnitur, elektronik, buku, pakaian, perlengkapan rumah, alat olahraga, dan kategori lainnya.
5. **Daftar barang terbaru** — menampilkan iklan yang baru diterbitkan.
6. **Barang gratis** — daftar barang yang ditawarkan tanpa harga.
7. **Tampilan loading, error, dan data kosong** — memberi informasi yang jelas saat data sedang dimuat, gagal diambil, atau belum tersedia.

### 6.3 Iklan barang

1. **Pasang iklan barang** — pengguna mengisi judul, kategori, deskripsi, kondisi, harga, lokasi umum, dan foto.
2. **Unggah beberapa foto** — pengguna menambahkan foto barang dari galeri atau kamera.
3. **Status barang** — tersedia, sedang dalam kesepakatan, atau sudah selesai.
4. **Barang gratis** — pengguna dapat memilih opsi gratis jika ingin memberikan barang.
5. **Edit iklan** — pemilik dapat memperbarui iklannya.
6. **Hapus iklan** — pemilik dapat menghapus iklannya.
7. **Iklan saya** — menampilkan seluruh iklan yang dibuat oleh pengguna.
8. **Detail barang** — menampilkan foto, judul, deskripsi, kondisi, harga, lokasi umum, dan informasi pengiklan.
9. **Tandai selesai** — pemilik dapat menandai barang sudah terjual, diberikan, atau tidak tersedia.
10. **Laporkan iklan** — pengguna dapat melaporkan iklan yang mencurigakan atau melanggar aturan.

### 6.4 Pencarian dan filter barang

1. **Pencarian kata kunci** — mencari barang berdasarkan nama atau deskripsi.
2. **Filter kategori** — membatasi hasil pada kategori tertentu.
3. **Filter harga** — menentukan batas harga minimum dan maksimum.
4. **Filter barang gratis** — hanya menampilkan barang yang ditawarkan gratis.
5. **Filter kondisi** — misalnya baru, sangat baik, baik, atau perlu perbaikan.
6. **Filter lokasi** — mencari barang di wilayah tertentu.
7. **Pengurutan hasil** — berdasarkan terbaru atau harga.
8. **Penyimpanan favorit** — menyimpan barang untuk dilihat kembali.
9. **Hapus dari favorit** — menghapus barang dari daftar tersimpan.

### 6.5 Lokasi berbasis LBS

1. **Lokasi pengguna** — membaca lokasi perangkat setelah pengguna memberikan izin.
2. **Pencarian barang sekitar** — menampilkan barang di sekitar wilayah pengguna.
3. **Jarak perkiraan** — menampilkan jarak perkiraan antara pengguna dan lokasi barang bila koordinat tersedia.
4. **Pilih lokasi manual** — pengguna tetap dapat memilih wilayah secara manual jika tidak memberikan izin GPS.
5. **Peta lokasi barang** — menampilkan lokasi umum atau titik pertemuan yang disepakati.
6. **Privasi lokasi** — alamat rumah lengkap tidak ditampilkan secara publik secara default.

Fitur LBS digunakan untuk menemukan barang, bukan untuk melacak pengguna secara terus-menerus.

### 6.6 Chat dan kesepakatan barang

1. **Mulai percakapan** — calon pembeli/penerima menghubungi pemilik barang dari halaman detail.
2. **Daftar percakapan** — menampilkan percakapan yang dimiliki pengguna.
3. **Riwayat chat** — menampilkan pesan berdasarkan waktu.
4. **Kirim pesan** — mengirim pertanyaan mengenai kondisi, harga, dan ketersediaan barang.
5. **Kesepakatan pengambilan** — pengguna menentukan waktu dan tempat penyerahan melalui percakapan.
6. **Blokir atau laporkan pengguna** — fitur keselamatan yang dapat dikembangkan pada tahap berikutnya.

### 6.7 Notifikasi mobile

1. Notifikasi pesan baru.
2. Notifikasi ketika iklan milik pengguna mendapat aktivitas penting.
3. Notifikasi perubahan status iklan jika relevan.
4. Pengingat untuk menanggapi percakapan yang belum selesai, jika diaktifkan.
5. Pengaturan notifikasi di halaman profil.

Untuk tahap awal, notifikasi lokal dapat digunakan. Push notification membutuhkan konfigurasi backend dan layanan pengiriman notifikasi yang sesuai.

### 6.8 AI dan LLM

1. **Bantuan membuat deskripsi iklan** — AI menyusun draf deskripsi berdasarkan informasi yang dimasukkan pengguna.
2. **Saran kategori** — AI menyarankan kategori barang dari judul dan deskripsi.
3. **Perbaikan teks** — AI membantu membuat deskripsi lebih jelas dan mudah dipahami.
4. **Saran kata kunci** — AI mengusulkan kata kunci agar iklan lebih mudah ditemukan.
5. **Kontrol pengguna** — hasil AI hanya berupa saran dan harus dapat diperiksa serta diedit sebelum dipublikasikan.

AI tidak boleh mengarang kondisi barang, spesifikasi, atau fakta yang tidak diberikan pengguna. Fitur ini memerlukan koneksi ke API model AI atau model yang tersedia secara lokal.

### 6.9 Menu konversi mata uang

Menu ini merupakan fitur tambahan sesuai ketentuan tugas, bukan inti marketplace.

1. **Konversi mata uang** — memasukkan nominal dan memilih mata uang asal serta tujuan.
2. **Minimal tiga mata uang** — contoh IDR, USD, dan JPY.
3. **Kurs dan waktu pembaruan** — menampilkan sumber atau waktu pembaruan kurs jika data kurs online digunakan.
4. **Perhitungan hasil** — menampilkan nilai konversi berdasarkan kurs yang tersedia.
5. **Penanganan offline** — memberi tanda bahwa kurs terakhir mungkin sudah tidak terbaru jika tidak ada koneksi.

Nilai tukar harus berasal dari sumber kurs yang jelas. Jangan menganggap angka kurs statis sebagai kurs real-time.

### 6.10 Menu konversi waktu

1. **Konversi zona waktu** — mengubah tanggal dan waktu antara zona waktu yang dipilih.
2. **Zona waktu minimum** — WIB (Asia/Jakarta), WITA (Asia/Makassar), WIT (Asia/Jayapura), dan London (Europe/London).
3. **Pemilihan tanggal dan waktu** — pengguna memilih waktu asal yang ingin dikonversi.
4. **Hasil konversi** — menampilkan tanggal, jam, dan zona waktu tujuan.
5. **Penyesuaian daylight saving time** — menggunakan basis data zona waktu agar waktu London menyesuaikan perubahan musim bila didukung library.

### 6.11 Sensor perangkat

Aplikasi menerapkan minimal dua sensor sesuai ketentuan tugas.

**Sensor 1 — Accelerometer**
- Mendeteksi perubahan gerakan perangkat.
- Contoh implementasi: menggoyangkan perangkat untuk mengacak rekomendasi barang atau memperbarui pilihan barang.
- Sediakan tombol alternatif agar fitur tetap dapat digunakan tanpa sensor.

**Sensor 2 — Gyroscope**
- Mendeteksi rotasi atau orientasi perangkat.
- Contoh implementasi: mengaktifkan tampilan pratinjau foto barang atau efek interaksi ketika perangkat dimiringkan.
- Fitur harus memiliki penjelasan dan kontrol untuk mengaktifkan atau menonaktifkannya.

Sensor yang tersedia berbeda menurut perangkat. Aplikasi harus menangani perangkat yang tidak mendukung sensor atau ketika akses sensor tidak tersedia.

### 6.12 Mini game sederhana

**Mini game: Pilah Barang**

- Pengguna mengelompokkan barang ke kategori yang sesuai, misalnya elektronik, pakaian, buku, dan perlengkapan rumah.
- Setiap jawaban benar menambah skor.
- Permainan memiliki batas waktu atau jumlah soal.
- Hasil akhir menampilkan skor.
- Permainan bersifat edukatif dan berkaitan dengan pengenalan kategori barang serta penggunaan kembali barang.
- Tidak menggunakan uang sungguhan atau mekanisme perjudian.

### 6.13 Blockchain sederhana

**Fitur: Catatan riwayat status barang**

Sebagai demonstrasi pembelajaran blockchain, aplikasi dapat membuat rangkaian catatan perubahan status iklan, misalnya dibuat, diperbarui, dan ditandai selesai.

- Setiap catatan berisi ID iklan, status, waktu, dan hash catatan sebelumnya.
- Hash dibuat menggunakan algoritma kriptografi yang sesuai, misalnya SHA-256.
- Perubahan data lama dapat dideteksi dengan memverifikasi rangkaian hash.
- Tampilkan halaman demonstrasi untuk melihat riwayat dan status verifikasi.

**Batasan:** rangkaian hash yang tersimpan hanya di satu server bukan blockchain terdistribusi penuh. Dokumentasi proyek harus menyebutnya sebagai simulasi/rantai hash sederhana kecuali benar-benar memakai jaringan blockchain dan mekanisme konsensus.

### 6.14 Saran dan kesan

1. Formulir saran atau masukan.
2. Kategori masukan, misalnya fitur, tampilan, kendala, atau lainnya.
3. Kolom pesan.
4. Konfirmasi setelah masukan terkirim.
5. Riwayat masukan pengguna bila diperlukan.

### 6.15 Bantuan dan privasi

1. FAQ penggunaan aplikasi.
2. Panduan transaksi yang lebih aman.
3. Ketentuan penggunaan.
4. Kebijakan privasi.
5. Pelaporan iklan atau masalah.
6. Informasi kontak pengelola.

---

## 7. Struktur Halaman

| Halaman | Konten |
|---|---|
| Splash Screen | Logo jadiGuna |
| Onboarding | Pengenalan fitur utama |
| Login | Email dan password |
| Registrasi | Form pembuatan akun |
| Login Biometrik | Autentikasi lokal dengan biometrik perangkat |
| Beranda | Pencarian, kategori, barang terbaru, barang gratis |
| Hasil Pencarian | Daftar barang dan filter |
| Detail Barang | Foto, deskripsi, harga, lokasi, dan tombol hubungi |
| Pasang Iklan | Formulir iklan barang |
| Edit Iklan | Memperbarui iklan sendiri |
| Favorit | Barang yang disimpan |
| Iklan Saya | Iklan milik pengguna |
| Daftar Chat | Percakapan pengguna |
| Detail Chat | Riwayat pesan |
| Peta/Lokasi | Barang sekitar atau lokasi umum |
| Profil | Foto, nama, pengaturan, dan menu akun |
| Konversi Mata Uang | Konversi IDR, USD, JPY, dan mata uang tambahan |
| Konversi Waktu | Konversi WIB, WITA, WIT, dan London |
| Bantuan AI | Saran deskripsi atau kategori iklan |
| Mini Game | Permainan Pilah Barang |
| Riwayat Blockchain | Rantai hash perubahan status iklan |
| Saran dan Kesan | Formulir masukan |
| Pengaturan | Biometrik, notifikasi, dan preferensi |
| Logout | Mengakhiri sesi |

## 8. Navigasi Utama

Bottom navigation disarankan terdiri dari lima menu:

1. **Beranda**
2. **Favorit**
3. **Pasang Iklan**
4. **Pesan**
5. **Profil**

Menu konversi mata uang, konversi waktu, AI, mini game, sensor, blockchain, bantuan, serta saran dan kesan dapat diletakkan di halaman Profil atau menu tambahan agar navigasi utama tetap sederhana.

## 9. Alur Penggunaan Utama

### 9.1 Mencari barang

1. Pengguna membuka Beranda.
2. Pengguna memasukkan kata kunci atau memilih kategori.
3. Pengguna memilih filter harga, kondisi, atau lokasi.
4. Aplikasi menampilkan daftar hasil.
5. Pengguna membuka detail barang.
6. Pengguna menyimpan ke favorit atau menghubungi pemilik.

### 9.2 Memasang barang

1. Pengguna login.
2. Pengguna menekan Pasang Iklan.
3. Pengguna mengisi judul, kategori, deskripsi, kondisi, harga, lokasi umum, dan foto.
4. AI dapat membantu menyusun deskripsi atau menyarankan kategori.
5. Pengguna memeriksa dan mengonfirmasi data.
6. Aplikasi menyimpan iklan melalui Supabase; kebijakan RLS memastikan pengguna hanya dapat mengubah iklan miliknya sendiri.
7. Iklan muncul dalam daftar setelah berhasil disimpan.

### 9.3 Menyelesaikan transaksi

1. Calon pembeli menghubungi pemilik melalui chat.
2. Kedua pihak mendiskusikan kondisi dan harga.
3. Kedua pihak menyepakati metode, waktu, dan lokasi penyerahan.
4. Setelah selesai, pemilik memperbarui status iklan.
5. Perubahan status dapat dicatat pada demonstrasi riwayat blockchain.

## 10. Rancangan Database

### 10.1 Identitas dan profil pengguna

Supabase Auth mengelola identitas dan kredensial pada skema autentikasinya. Jangan membuat kolom `password_hash` di tabel profil aplikasi. Buat tabel `profiles` yang terhubung ke ID pengguna Supabase:

| Kolom | Keterangan |
|---|---|
| id | UUID yang sama dengan ID pengguna Supabase Auth |
| name | Nama tampilan pengguna |
| email | Email profil jika memang diperlukan; identitas utama tetap dikelola Auth |
| profile_photo_path | Path foto profil di Supabase Storage |
| created_at | Waktu pembuatan |
| updated_at | Waktu pembaruan |

### 10.2 Tabel `categories`

- `id`
- `name`
- `slug`
- `is_active`

### 10.3 Tabel `listings`

- `id`
- `user_id`
- `category_id`
- `title`
- `description`
- `price` (nullable atau aturan khusus untuk barang gratis)
- `condition`
- `location_name`
- `latitude` (nullable)
- `longitude` (nullable)
- `status`
- `created_at`
- `updated_at`

### 10.4 Tabel `listing_images`

- `id`
- `listing_id`
- `image_path`
- `sort_order`

### 10.5 Tabel `favorites`

- `id`
- `user_id`
- `listing_id`
- `created_at`

Tambahkan constraint unik untuk kombinasi `user_id` dan `listing_id`.

### 10.6 Tabel `conversations`

- `id`
- `listing_id`
- `buyer_id`
- `seller_id`
- `created_at`
- `updated_at`

### 10.7 Tabel `messages`

- `id`
- `conversation_id`
- `sender_id`
- `message`
- `created_at`
- `read_at` (nullable)

### 10.8 Tabel `reports`

- `id`
- `reporter_id`
- `listing_id` (nullable)
- `reason`
- `description`
- `status`
- `created_at`

### 10.9 Tabel `feedback`

- `id`
- `user_id`
- `category`
- `message`
- `created_at`

### 10.10 Tabel pendukung

- `notifications`: data notifikasi aplikasi.
- `listing_status_history`: riwayat perubahan status iklan untuk demonstrasi rantai hash.
- `user_preferences`: pengaturan pengguna jika diperlukan.

SQLite digunakan pada perangkat untuk cache data yang diperlukan, misalnya daftar iklan terakhir, kategori, dan preferensi. Supabase PostgreSQL menjadi sumber data online utama untuk profil, iklan, favorit, percakapan, pesan, laporan, dan saran/masukan. Tentukan strategi sinkronisasi: data online diperbarui ke cache SQLite saat koneksi tersedia; perubahan offline ditandai sebagai belum tersinkron dan dikirim saat koneksi kembali. Kredensial dan token sesi tidak disimpan dalam tabel cache biasa.

## 11. Integrasi Supabase dan operasi data

Proyek ini tidak memerlukan backend terpisah untuk operasi CRUD standar. Flutter berkomunikasi dengan Supabase menggunakan paket `supabase_flutter`. Supabase menyediakan PostgreSQL, API data otomatis, autentikasi, Storage, dan Realtime. Operasi yang membutuhkan rahasia atau logika server khusus dapat ditempatkan di Supabase Edge Functions.

| Kebutuhan | Implementasi yang direncanakan |
|---|---|
| Registrasi dan login | Supabase Auth (`signUp`, `signInWithPassword`) |
| Logout dan sesi | Supabase Auth (`signOut`) dan pemulihan sesi sesuai SDK |
| Profil | Tabel `profiles` di Supabase Database |
| Kategori dan iklan | Tabel `categories` dan `listings` melalui Supabase client |
| Foto iklan/profil | Supabase Storage dengan aturan akses yang sesuai |
| Favorit | Tabel `favorites` dengan pembatasan akses berdasarkan pengguna |
| Chat | Tabel `conversations` dan `messages`; Supabase Realtime dapat digunakan untuk pesan baru |
| Laporan dan saran | Tabel `reports` dan `feedback` |
| Bantuan AI | Supabase Edge Function atau server aman untuk menyimpan rahasia API AI |
| Data lokal/offline | SQLite untuk cache dan antrean perubahan yang belum tersinkron |

### Kebijakan akses dan keamanan data

- Aktifkan Row Level Security (RLS) untuk tabel yang diakses dari aplikasi.
- Atur policy agar pengguna hanya dapat mengubah profil, favorit, pesan, dan iklan yang memang menjadi haknya.
- Batasi akses bucket Supabase Storage; jangan membuat semua file privat menjadi publik tanpa pertimbangan.
- Jangan pernah memasukkan `service_role` key atau rahasia API AI ke source code Flutter.
- Supabase publishable/anon key dapat berada di aplikasi hanya jika seluruh tabel dan bucket dilindungi oleh konfigurasi policy yang benar.
- Validasi input di aplikasi untuk pengalaman pengguna, dan tegakkan aturan akses utama melalui RLS serta Edge Functions bila diperlukan.

Contoh operasi di atas adalah rancangan integrasi; tabel, policy RLS, bucket, dan fungsi server tetap harus dibuat dan diuji pada proyek Supabase.

## 12. Struktur Folder Flutter

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── network/
├── models/
│   ├── user_model.dart
│   ├── category_model.dart
│   ├── listing_model.dart
│   └── message_model.dart
├── services/
│   ├── auth_service.dart
│   ├── listing_service.dart
│   ├── favorite_service.dart
│   ├── chat_service.dart
│   ├── location_service.dart
│   ├── currency_service.dart
│   └── ai_service.dart
├── screens/
│   ├── auth/
│   ├── home/
│   ├── search/
│   ├── listing/
│   ├── favorites/
│   ├── chat/
│   ├── profile/
│   ├── converters/
│   ├── mini_game/
│   └── feedback/
├── widgets/
│   ├── listing_card.dart
│   ├── category_item.dart
│   └── app_bottom_navigation.dart
└── routes/
    └── app_routes.dart
```

## 13. Keamanan dan Privasi

1. Supabase Auth menangani autentikasi dan pengelolaan kredensial; aplikasi tidak menyimpan password dalam bentuk teks biasa atau membuat tabel password sendiri.
2. Sesi dikelola oleh Supabase SDK; gunakan penyimpanan sesi yang sesuai dan jangan menyalin token ke database cache SQLite biasa.
3. Logout dilakukan melalui Supabase Auth dan sesi lokal dibersihkan sesuai mekanisme SDK.
4. Login biometrik menggunakan fasilitas keamanan perangkat; data biometrik tidak disimpan oleh aplikasi.
5. RLS, constraint database, dan Supabase Edge Functions bila diperlukan menegakkan validasi serta hak akses data online.
6. Hanya pemilik iklan yang dapat mengubah atau menghapus iklannya.
7. Foto yang diunggah dibatasi berdasarkan tipe dan ukuran file.
8. Koordinat lokasi dan informasi pribadi tidak dibagikan lebih luas dari yang diperlukan.
9. API AI tidak boleh menyimpan rahasia API di source code aplikasi; panggilan yang memerlukan kunci rahasia sebaiknya melalui backend.
10. Aplikasi menyediakan panduan transaksi aman dan mekanisme pelaporan.

## 14. Tahapan Pengembangan

### Tahap 1 — Fitur inti (MVP)

- Registrasi dan login.
- Session/token.
- Beranda dan kategori.
- Daftar dan detail barang.
- Pencarian dan filter dasar.
- Pasang, edit, dan hapus iklan.
- Profil dan logout.
- SQLite lokal dan Supabase online (PostgreSQL, Auth, Storage, serta Realtime bila diperlukan).

### Tahap 2 — Interaksi dan lokasi

- Favorit.
- Chat.
- LBS dan peta/lokasi umum.
- Notifikasi.
- Laporan iklan.

### Tahap 3 — Fitur wajib tambahan tugas

- Login biometrik.
- Konversi mata uang minimal IDR, USD, dan JPY.
- Konversi waktu WIB, WITA, WIT, dan London.
- Accelerometer.
- Gyroscope.
- Menu saran dan kesan.
- Mini game Pilah Barang.
- Demonstrasi blockchain sederhana.
- Fitur AI/LLM.

### Tahap 4 — Pengujian

- Uji registrasi, login, logout, dan sesi.
- Uji validasi serta hak akses iklan.
- Uji pencarian dan filter.
- Uji unggah gambar.
- Uji penyimpanan lokal dan sinkronisasi online.
- Uji sensor pada perangkat yang mendukung.
- Uji konversi kurs dan zona waktu.
- Uji notifikasi, AI, mini game, dan rantai hash.
- Uji tampilan pada beberapa ukuran layar.
- Dokumentasikan hasil pengujian dan tangkapan layar.

## 15. Kriteria Penerimaan

Aplikasi dapat dianggap memenuhi kebutuhan dasar jika:

- Pengguna dapat registrasi, login, dan logout.
- Password tidak disimpan dalam bentuk teks biasa.
- Sesi login dapat dikelola dengan benar.
- Login biometrik berfungsi pada perangkat yang mendukung.
- Pengguna dapat memasang dan mengelola iklannya sendiri.
- Pengguna dapat mencari barang berdasarkan kata kunci dan kategori.
- Data tertentu tersimpan di SQLite dan data utama tersinkron ke Supabase.
- Aplikasi terhubung ke layanan data Supabase melalui `supabase_flutter`; Edge Functions digunakan untuk kebutuhan server khusus.
- Fitur lokasi bekerja setelah izin diberikan atau menyediakan pemilihan lokasi manual.
- Navigasi memuat profil, saran dan kesan, serta logout.
- Konversi mata uang mendukung minimal tiga mata uang.
- Konversi waktu mendukung WIB, WITA, WIT, dan London.
- Minimal dua sensor digunakan dalam fungsi aplikasi.
- Fitur AI/LLM tersedia untuk membantu penulisan atau kategorisasi iklan.
- Mini game sederhana dapat dimainkan.
- Fitur blockchain sederhana dapat menunjukkan verifikasi rantai hash.
- Notifikasi mobile berjalan sesuai konfigurasi.
- Aplikasi menampilkan pesan yang jelas saat terjadi error.

## 16. Kesimpulan

jadiGuna adalah aplikasi mobile yang berfokus pada jual beli, penukaran, dan pemberian barang bekas berbasis lokasi. Rancangan ini mencakup fitur inti marketplace serta fitur tambahan yang disesuaikan dengan ketentuan Tugas Akhir Pemrograman Aplikasi Mobile, yaitu autentikasi dan sesi aman melalui Supabase Auth, biometrik, penyimpanan lokal SQLite dan database online Supabase, integrasi API Supabase, LBS, navigasi, konversi mata uang dan waktu, dua sensor, AI/LLM, mini game, notifikasi, serta demonstrasi blockchain sederhana.

Untuk menjaga proyek tetap realistis, selesaikan fitur inti marketplace terlebih dahulu, lalu implementasikan fitur tambahan secara bertahap dan dokumentasikan hasil pengujiannya.
