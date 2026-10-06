# 📘 User Manual — KMP Mitra (KOPDES)

## *Smart Cooperative Intelligence System*

**Versi Dokumen:** 1.0
**Tanggal:** Oktober 2026

---

## Daftar Isi

1. [Pendahuluan](#1-pendahuluan)
2. [Persyaratan Sistem](#2-persyaratan-sistem)
3. [Instalasi & Memulai Aplikasi](#3-instalasi--memulai-aplikasi)
4. [Panduan Pengguna — Customer (Masyarakat Desa)](#4-panduan-pengguna--customer-masyarakat-desa)
   - [4.1 Registrasi & Login](#41-registrasi--login)
   - [4.2 Beranda](#42-beranda)
   - [4.3 Marketplace](#43-marketplace)
   - [4.4 Detail Produk](#44-detail-produk)
   - [4.5 Keranjang & Pesanan](#45-keranjang--pesanan)
   - [4.6 Checkout & Pembayaran](#46-checkout--pembayaran)
   - [4.7 Saldo KOMIT](#47-saldo-komit)
   - [4.8 Melacak, Menerima, dan Membatalkan Pesanan](#48-melacak-menerima-dan-membatalkan-pesanan)
   - [4.9 Riwayat Pesanan & Invoice](#49-riwayat-pesanan--invoice)
   - [4.10 Asisten AI](#410-asisten-ai)
   - [4.11 Pesan (Chat)](#411-pesan-chat)
   - [4.12 Profil](#412-profil)
   - [4.13 Notifikasi](#413-notifikasi)
   - [4.14 Kopdes & Mitra UMKM](#414-kopdes--mitra-umkm)
   - [4.15 Ulasan & Penilaian](#415-ulasan--penilaian)
5. [Panduan Pengguna — Pemilik UMKM (Seller)](#5-panduan-pengguna--pemilik-umkm-seller)
   - [5.1 Mendaftar Jadi Mitra UMKM](#51-mendaftar-jadi-mitra-umkm)
   - [5.2 Dasbor](#52-dasbor)
   - [5.3 Produk](#53-produk)
   - [5.4 Pesanan](#54-pesanan)
   - [5.5 Pesan](#55-pesan)
   - [5.6 Toko Anda](#56-toko-anda)
   - [5.7 Uang Hasil Penjualan](#57-uang-hasil-penjualan)
   - [5.8 Rekening & Pencairan Saldo](#58-rekening--pencairan-saldo)
   - [5.9 Keamanan Akun](#59-keamanan-akun)
6. [Panduan Pengguna — Admin Koperasi (Pemilik Kopdes)](#6-panduan-pengguna--admin-koperasi-pemilik-kopdes)
   - [6.1 Dasbor](#61-dasbor)
   - [6.2 Produk Kopdes](#62-produk-kopdes)
   - [6.3 Pesanan & Pengantaran](#63-pesanan--pengantaran)
   - [6.4 Pesan](#64-pesan)
   - [6.5 Koperasi](#65-koperasi)
   - [6.6 Verifikasi Mitra UMKM](#66-verifikasi-mitra-umkm)
   - [6.7 Pencairan Saldo Mitra](#67-pencairan-saldo-mitra)
   - [6.8 Pegawai & Kurir](#68-pegawai--kurir)
   - [6.9 Asisten AI Koperasi](#69-asisten-ai-koperasi)
7. [FAQ (Pertanyaan Umum)](#7-faq-pertanyaan-umum)
8. [Kontak & Bantuan](#8-kontak--bantuan)

---

## 1. Pendahuluan

**KMP Mitra (KOPDES)** adalah aplikasi koperasi desa digital berbasis AI yang dirancang untuk menghubungkan koperasi desa, pelaku UMKM, dan masyarakat desa dalam satu ekosistem terintegrasi. Aplikasi ini menyediakan fitur marketplace, logistik, dan kecerdasan buatan untuk mendukung pertumbuhan ekonomi desa.

### Peran Pengguna dalam Sistem

| Peran | Deskripsi |
|:---|:---|
| **Customer** | Masyarakat desa yang berbelanja produk koperasi dan UMKM |
| **UMKM** | Pelaku usaha yang menjual produk melalui marketplace koperasi |
| **Admin Kopdes** | Pengelola koperasi desa yang mengawasi seluruh operasional |
| **Kurir** | Pengantar pesanan kepada customer |
| **Super Admin** | Administrator sistem dengan akses penuh (tidak dibahas di manual ini) |

---

## 2. Persyaratan Sistem

### Perangkat yang Didukung

| Platform | Versi Minimum |
|:---|:---|
| Android | Android 7.0 (API 24) ke atas |
| iOS | iOS 13.0 ke atas |

### Kebutuhan Lain

- Koneksi internet aktif (Wi-Fi atau data seluler)
- Ruang penyimpanan minimal **150 MB** (untuk instalasi)
- **GPS/Lokasi** aktif (untuk fitur pencarian koperasi terdekat dan pengiriman)
- **Kamera** (opsional, untuk upload foto produk — khusus UMKM)

---

## 3. Instalasi & Memulai Aplikasi

### Langkah Instalasi

1. **Dapatkan file `KOMIT-v1.0.0.apk`** dari pengelola koperasi Anda atau unduh melalui tautan resmi.
2. Buka file APK pada perangkat Android Anda.
3. Jika diminta, aktifkan **"Izinkan dari sumber tidak dikenal"** di Pengaturan → Keamanan.
4. Ketuk **"Instal"** dan tunggu proses selesai.
5. Ketuk **"Buka"** untuk memulai aplikasi.

### Alur Pertama Kali Membuka Aplikasi

```
Splash Screen → Onboarding → Izin Sistem → Login/Register → Beranda
```

1. **Splash Screen** — Animasi logo KMP Mitra muncul saat aplikasi memuat data awal.
2. **Onboarding** — Tampil hanya sekali, menampilkan pengenalan fitur utama.
3. **Izin Sistem** — Aplikasi meminta izin lokasi, kamera, dan notifikasi. Sangat disarankan untuk mengizinkan semua agar fitur berfungsi optimal.
4. **Login/Register** — Masuk ke akun atau daftarkan akun baru.

---

## 4. Panduan Pengguna — Customer (Masyarakat Desa)

> Bagian ini mengikuti aplikasi per 4 Oktober 2026 (commit `c3723a6`).

### 4.1 Registrasi & Login

#### Registrasi Akun Baru

1. Pada halaman Masuk, ketuk **"Daftar"**.
2. Isi data berikut:
   - **Nama Lengkap**
   - **Nomor HP**
   - **Email** — alamat email aktif, dipakai untuk masuk
   - **Kata Sandi** — minimal 6 karakter
   - **Konfirmasi Kata Sandi**
3. Centang **"Saya menyetujui syarat dan ketentuan"**.
4. Ketuk **"Daftar"**. Akun yang dibuat sendiri selalu berperan **Customer**;
   akun UMKM, pengurus Kopdes, pegawai, dan kurir dibuatkan oleh pengelola.

> Daftar/masuk dengan Google, Facebook, atau Nomor HP **belum tersedia** —
> gunakan formulir email.

#### Login

1. Masukkan **Email** dan **Kata Sandi**, lalu ketuk **"Masuk"**.
2. **Lupa kata sandi?** Pengaturan ulang lewat email belum tersedia. Hubungi
   pengurus Kopdes desa Anda dengan menyebut email akun; pengurus
   meneruskannya ke pengelola sistem yang dapat mengatur kata sandi baru.

#### Sesi

Anda tetap masuk sampai menekan **Keluar**. Bila sesi tidak berlaku lagi
(misalnya kata sandi diganti di perangkat lain), aplikasi menampilkan layar
**"Sesi Berakhir"** — masuk kembali untuk melanjutkan.

---

### 4.2 Beranda

| Bagian | Fungsi |
|:---|:---|
| **Kepala halaman** | Sapaan, lokasi perangkat, ikon Notifikasi, Keranjang, dan Pesan. Tetap terlihat saat digulir. |
| **Kolom pencarian** | Membuka Marketplace untuk mencari produk |
| **Kartu Saldo** | **Saldo KOMIT**, Poin Belanja, dan Status, dengan aksi **Top Up** (membuka halaman Saldo), **Riwayat** (riwayat pesanan), dan **Detail** (Profil) |
| **Banner** | Diatur pengurus; ketuk untuk membuka halaman tujuannya |
| **Kopdes Terdekat** | Diurutkan menurut lokasi Anda bila izin lokasi diberikan |
| **Mitra UMKM Terdekat** | UMKM mitra di sekitar Anda |
| **Kategori** | Pintasan ke Marketplace per kategori |
| **Produk UMKM Pilihan** | Produk UMKM yang ditandai pengurus |
| **Produk Terlaris** | Produk dengan penjualan tertinggi |
| **Rekomendasi Kebutuhan** | Daftar produk dengan filter kategori |

Tarik layar ke bawah untuk memuat ulang.

---

### 4.3 Marketplace

Buka tab **Produk** atau ketuk kolom pencarian di Beranda.

- **Cari** dengan mengetik nama produk; **filter kategori** dan pencarian
  dikirim ke server sehingga hasilnya mencakup semua produk.
- Ketuk **♡** pada kartu untuk menyimpan ke **Favorit** (tersimpan di ponsel
  ini). Tombol hati di bagian atas menampilkan daftar favorit.
- Ketuk **+** untuk menambahkan ke keranjang, atau ketuk kartu untuk detail.

---

### 4.4 Detail Produk

Menampilkan foto, nama, harga, stok, deskripsi, penjual, penilaian (rata-rata
bintang dan jumlah penilai), 5 ulasan terbaru, dan **Produk lainnya di toko**.

- **Tambah ke Keranjang** — pilih jumlah, lalu tambahkan.
- **Beli Langsung** — pilih jumlah, cara menerima (**Ambil di Koperasi** atau
  **Diantar Kurir**), dan cara bayar (**Bayar Online**, **Saldo KOMIT**, atau
  **COD**), lalu lanjut ke Checkout. Ongkir saat ini **Rp0** dan tidak ada
  biaya layanan.

---

### 4.5 Keranjang & Pesanan

Tab **Pesanan** berisi keranjang dan pesanan Anda.

- Produk dikelompokkan per penjual. Ubah jumlah dengan **+ / −**, hapus
  produk, dan **centang** produk yang ingin dipesan — yang tidak dicentang
  tetap tinggal di keranjang.
- Ketuk **Checkout** untuk memesan produk yang dicentang.
- Pesanan yang sedang berjalan dan yang sudah selesai/dibatalkan tampil
  terpisah, masing-masing dengan status dalam kata (mis. "Menunggu
  pembayaran", "Sedang disiapkan", "Dalam pengiriman").

---

### 4.6 Checkout & Pembayaran

#### Alamat (wajib, juga untuk ambil sendiri)

Pesanan selalu memerlukan alamat sebagai kontak. Bila belum ada, checkout
menampilkan **"Tambah Alamat"**. Alamat utama dipilih otomatis; ketuk
**Ganti** untuk memilih alamat lain atau menambah yang baru. Kelola semua
alamat di **Profil → Alamat Pengiriman**.

#### Langkah checkout

1. Pilih **Cara Menerima**: **Diantar** (kurir Kopdes) atau **Ambil Sendiri**
   (disiapkan penjual, diambil tanpa antre).
2. Periksa produk dan total.
3. Pilih **Metode Pembayaran**:
   - **Bayar Online** — setelah pesanan dibuat, layar Pembayaran terbuka.
   - **COD (Bayar di Tempat)** — bayar tunai kepada kurir. **Hanya untuk
     pesanan yang diantar.**
   - **Saldo KOMIT** — langsung lunas bila saldo mencukupi; bila tidak cukup,
     pilihan ini tidak bisa dipilih dan alasannya ditampilkan.
4. Ketuk **"Konfirmasi & Bayar"**.

#### Layar Pembayaran (Bayar Online)

- **QRIS** (bawaan): scan kode QR dengan aplikasi bank atau e-wallet apa pun.
- **Ganti Metode Pembayaran**: GoPay, ShopeePay (tombol membuka aplikasinya),
  atau Virtual Account BCA/BNI/BRI/Permata dan Mandiri Bill (nomor bisa
  disalin).
- Tampil **hitung mundur** batas waktu bayar. Status diperiksa otomatis;
  bisa juga ketuk **"Cek Status Pembayaran"**.
- Setelah lunas: **"Pembayaran Diterima"** → **Lihat Pesanan**.
- Kedaluwarsa/gagal: tidak ada uang terpotong; ketuk **"Bayar Ulang"**.
- Menutup layar ini tidak membatalkan tagihan. Lanjutkan kapan saja dengan
  **"Bayar Sekarang"** pada kartu pesanan.

| Status pembayaran | Arti |
|:---|:---|
| **Menunggu pembayaran** | Tagihan online belum dibayar |
| **Pembayaran diterima / Lunas** | Pembayaran dikonfirmasi Midtrans atau dipotong dari saldo |
| **COD** | Dibayar tunai saat barang diterima — tidak ada tombol bayar |

---

### 4.7 Saldo KOMIT

Buka dari **Profil → Saldo KOMIT** atau **Top Up** di Beranda.

- Menampilkan saldo dan **Riwayat saldo** (isi ulang, pembayaran pesanan,
  pengembalian dana).
- **Isi Ulang Saldo**: pilih nominal (minimal **Rp10.000**, maksimal
  Rp10.000.000) dan bayar dengan **QRIS, GoPay, atau ShopeePay**.
- Saldo dipakai membayar pesanan (pilih **Saldo KOMIT** saat checkout).
  Pesanan yang dibatalkan setelah dibayar dengan saldo **dikembalikan ke
  saldo**.

---

### 4.8 Melacak, Menerima, dan Membatalkan Pesanan

- Kartu pesanan menampilkan tombol sesuai keadaan:
  - **Bayar Sekarang** — tagihan online yang belum dibayar.
  - **Batalkan** — pesanan yang belum dibayar dan belum diproses.
    Pesanan yang sudah dibayar atau diproses dibatalkan oleh pengurus Kopdes.
  - **Lacak Pesanan / Lihat Detail** — status dan lini masa pesanan.
  - **Konfirmasi Diterima** — muncul setelah kurir menandai barang sampai.
    Tekan setelah barang Anda terima agar pesanan selesai.
  - **Beli Lagi** dan **Beri Ulasan** — setelah pesanan selesai.

---

### 4.9 Riwayat Pesanan & Invoice

Buka dari **Riwayat** di Beranda atau Profil. Setiap pesanan memuat nomor,
tanggal, produk, total, status, dan **invoice digital** di halaman detailnya.

---

### 4.10 Asisten AI

Ketuk tab **AI** untuk bertanya dalam bahasa sehari-hari, misalnya tentang
stok, harga, atau produk UMKM.

---

### 4.11 Pesan (Chat)

Ketuk ikon **Pesan** di Beranda. Percakapan yang tersedia:

| Dengan | Cara memulai |
|:---|:---|
| **Penjual** | Anda memulai dari halaman detail produk. Penjual juga bisa menghubungi Anda tentang pesanan. |
| **Kurir** | Kurir memulai percakapan saat mengantar pesanan Anda; balas dari halaman Pesan. |

Lencana angka menunjukkan pesan yang belum dibaca.

---

### 4.12 Profil

| Menu | Fungsi |
|:---|:---|
| **Saldo KOMIT** | Saldo, riwayat, isi ulang |
| **Aktivitas** | Pesanan, Favorit, Riwayat |
| **Data Pribadi** | Ubah nama dan nomor HP (email tidak bisa diubah) |
| **Alamat Pengiriman** | Tambah, ubah, hapus, dan pilih alamat utama |
| **Keanggotaan Koperasi** | Daftar sebagai anggota Kopdes |
| **Daftar Mitra UMKM** | Ajukan usaha Anda jadi mitra Kopdes (bagian 5.1) |
| **Notifikasi** | Daftar notifikasi di perangkat |
| **Privasi & Keamanan** | Ganti kata sandi (perangkat lain otomatis keluar) dan **Keluar** |
| **Pusat Bantuan** | Panduan memesan, membayar, dan akun |
| **Hubungi Kopdes** | Daftar Kopdes beserta kontaknya |
| **Tentang KOMIT** | Informasi aplikasi |

---

### 4.13 Notifikasi

Ketuk ikon lonceng di Beranda. Notifikasi saat ini **tersimpan di ponsel
ini** dan mencatat aktivitas di perangkat, misalnya produk yang
ditambahkan ke keranjang. Lencana angka menunjukkan yang belum dibaca;
tandai semua dibaca atau hapus semuanya dari layar Notifikasi.

> Notifikasi otomatis untuk perubahan status pesanan, kurir tiba, promo, dan
> pesan baru **belum tersedia**.

---

### 4.14 Kopdes & Mitra UMKM

- **Kopdes Terdekat** dan **Mitra UMKM Terdekat** di Beranda; ketuk
  **Lihat Lainnya** untuk daftar lengkap.
- Halaman Kopdes menampilkan alamat, kontak, jam buka, dan produknya.
- Halaman mitra UMKM menampilkan profil toko, produk, dan penilaian.

---

### 4.15 Ulasan & Penilaian

Setelah pesanan **selesai**, ketuk **Beri Ulasan** pada kartu pesanan, pilih
1–5 bintang, tulis ulasan (opsional), lalu kirim. Tombol hanya muncul bila
masih ada produk di pesanan itu yang belum Anda ulas.

---

## 5. Panduan Pengguna — Pemilik UMKM (Seller)

Konsol penjual punya lima tab di bilah bawah: **Dasbor, Produk, Pesanan, Pesan, Toko**.

### 5.1 Mendaftar Jadi Mitra UMKM

UMKM berjualan sebagai **mitra Kopdes di desanya sendiri**. Pendaftaran dimulai dari akun pembeli biasa.

1. **Daftar akun** seperti customer (bagian 4.1), lalu masuk.
2. Buka tab **Profil** → **Daftar Mitra UMKM**.
3. Pilih **Kopdes desa Anda** — daftar diurutkan dari yang terdekat.
4. Isi data usaha:
   - **Nama usaha** (3–100 huruf)
   - **Kategori usaha** — Kuliner, Swalayan, Minuman, Kerajinan, Jasa, atau Lainnya
   - **Tentang usaha** (opsional, maks. 300 huruf)
   - **Alamat usaha**
   - **Nomor ponsel / WhatsApp** (mis. 0812xxxxxxx)
5. Bila izin lokasi aktif, titik lokasi Anda ikut terkirim sebagai bukti usaha berada sedesa. Bila tidak aktif, pengurus memastikannya secara langsung.
6. Ketuk **Kirim Pendaftaran**. Halaman yang sama kini menampilkan status **Menunggu verifikasi**.
7. Setelah pengurus menyetujui, buka lagi **Profil → Daftar Mitra UMKM** dan ketuk **Masuk Ulang sebagai Penjual**. Setelah masuk ulang, aplikasi langsung membuka konsol penjual.

| Status | Arti |
|:---|:---|
| **Menunggu verifikasi** | Pengurus Kopdes sedang memeriksa data Anda |
| **Toko terverifikasi** | Disetujui — Anda bisa berjualan |
| **Verifikasi ditolak** | Alasan penolakan tampil; perbaiki datanya lalu kirim ulang dari halaman yang sama |
| **Toko ditangguhkan** | Dihentikan sementara oleh pengurus; hubungi Kopdes Anda |

> Satu akun hanya bisa memiliki satu toko. Selama pendaftaran masih menunggu atau sudah disetujui, Anda tidak dapat mengirim pendaftaran kedua.

---

### 5.2 Dasbor

| Bagian | Isi |
|:---|:---|
| **Kepala halaman** | Nama toko, status, ikon pesanan baru, chat, dan notifikasi, serta tombol cari dan tambah produk |
| **Ringkasan Penjualan** | Omzet dan jumlah transaksi **hari ini** dan **bulan ini** |
| **Aksi cepat** | Tambah Produk, Pesanan, Stok, Keuangan |
| **Perlu Perhatian** | Pesanan baru yang menunggu diproses dan produk yang stoknya menipis |
| **Ringkasan Toko** | Produk aktif, jumlah terjual, rating toko |

Tarik layar ke bawah untuk memuat ulang angka.

---

### 5.3 Produk

Tab **Produk** menampilkan seluruh produk Anda per halaman, dengan pencarian, filter kategori, dan filter stok (**Aman / Menipis / Habis**).

#### Menambah produk — tiga tahap

1. Ketuk **+** (Tambah produk).
2. **Tahap 1 — Info produk:** nama, kategori, deskripsi.
3. **Tahap 2 — Harga & stok:** harga jual dan stok awal.
4. **Tahap 3 — Foto:** hingga 5 foto (JPG/PNG/WebP). Foto pertama menjadi foto utama; urutannya bisa diubah.
5. Ketuk **Simpan**. Produk **langsung tampil** di marketplace — tidak perlu persetujuan, tetapi pengurus Kopdes dapat menurunkan produk yang melanggar.

Isian yang belum selesai otomatis disimpan sebagai **draf** dan ditawarkan lagi saat form dibuka. Bila foto gagal terunggah, ketuk **Unggah Ulang Foto** — produknya tidak dibuat dua kali.

#### Mengubah, menonaktifkan, dan melihat produk

- Ketuk kartu produk untuk membuka **detail**: foto, harga, stok, status **Aktif/Nonaktif**, dan ulasan pembeli.
- Dari detail, ketuk ikon **Edit produk** untuk mengubah data atau menonaktifkan produk. Produk nonaktif tidak tampil di marketplace, tetapi datanya tetap tersimpan.

#### Mengatur stok

Stok diatur langsung dari kartu produk lewat **Atur Stok**: pilih tambah atau kurangi, isi jumlah dan alasan. Setiap perubahan tercatat di **aktivitas stok**.

| Label | Arti |
|:---|:---|
| **Aman** | Stok di atas batas menipis |
| **Menipis** | Stok tinggal sedikit — segera tambah |
| **Habis** | Stok 0, produk tidak bisa dibeli |

---

### 5.4 Pesanan

Tab **Pesanan** dibagi menjadi **Baru, Diproses, Siap Kirim, Riwayat**.

1. Buka pesanan di tab **Baru**, periksa barang, jumlah, metode bayar, dan alamat.
2. Ketuk **Proses pesanan** saat mulai menyiapkan barang → pindah ke **Diproses**.
3. Ketuk **Tandai siap dikirim** saat barang siap → kurir Kopdes mengambil dan mengantarnya.

Penjual hanya dapat mengubah status ke **Diproses** dan **Siap Kirim**. Status pengantaran (dikirim, diterima) diperbarui oleh kurir dan pembeli.

---

### 5.5 Pesan

Tab **Pesan** berisi percakapan dengan pembeli. Angka di ikon chat pada Dasbor menunjukkan pesan yang belum dibaca.

---

### 5.6 Toko Anda

Tab **Toko** meringkas toko Anda:

- **Identitas** — logo, nama, Kopdes induk, status verifikasi, dan status **Buka sekarang / Sedang tutup**. **Lihat toko** membuka halaman toko seperti yang dilihat pembeli.
- **Saldo** — saldo yang bisa ditarik, saldo tertahan, dan tombol **Tarik saldo** (bagian 5.8).
- **Profil usaha** — tentang toko, alamat, kontak & jam buka.
- **Kelola toko** — Rekening pencairan, Pengaturan toko, Pusat bantuan, Keamanan akun.

#### Edit profil

Ketuk **Edit** → ubah nama usaha, kategori, deskripsi (maks. 300 huruf), dan alamat → **Simpan**. Titik lokasi di peta diatur oleh pengurus Kopdes.

#### Pengaturan toko

**Kelola toko → Pengaturan toko** berisi:

| Pengaturan | Fungsi |
|:---|:---|
| **Nomor telepon / WhatsApp** | Kontak yang dilihat pembeli |
| **Jam buka** | Jam buka dan tutup per hari; hari yang dimatikan dianggap tutup |

Status "Buka sekarang" di toko dan di etalase pembeli dihitung dari jam buka ini.

---

### 5.7 Uang Hasil Penjualan

- Setiap penjualan dipotong **fee 5%** untuk Kopdes (biaya promosi/platform). Sisanya masuk ke saldo toko Anda.
- Uang dari pesanan yang belum selesai masih **tertahan** dan baru bisa ditarik setelah pesanan selesai.

---

### 5.8 Rekening & Pencairan Saldo

1. **Kelola toko → Rekening pencairan** — isi nama bank, nomor rekening, dan nama pemilik rekening.
2. Di kartu **Saldo**, ketuk **Tarik saldo** dan masukkan nominal. Minimal penarikan **Rp50.000**. Bila tombol tidak aktif, alasannya tertulis di bawah tombol (mis. saldo belum cukup atau rekening belum diisi).
3. Pengurus Kopdes mentransfer dana ke rekening Anda lalu menandainya **Sudah ditransfer**.
4. Pantau di **Riwayat**: **Diproses**, **Sudah ditransfer**, atau **Ditolak** (nominal kembali ke saldo).

---

### 5.9 Keamanan Akun

**Kelola toko → Keamanan akun**:

- **Ubah kata sandi** — masukkan kata sandi lama dan kata sandi baru.
- **Keluar** dari akun.

---

## 6. Panduan Pengguna — Admin Koperasi (Pemilik Kopdes)

Konsol Kopdes dibuat sama dengan konsol UMKM, dengan lima tab: **Dasbor, Produk, Pesanan, Pesan, Koperasi**. Barang yang dikelola di sini adalah **barang milik Kopdes**; barang mitra dikelola oleh mitranya masing-masing.

### 6.1 Dasbor

| Bagian | Isi |
|:---|:---|
| **Kepala halaman** | Nama Kopdes, status buka/tutup, ikon pesanan baru, chat, notifikasi, cari, dan tambah produk |
| **Ringkasan Penjualan** | Omzet dan transaksi **hari ini** dan **bulan ini** — hanya dari barang Kopdes, dihitung dalam WIB |
| **Aksi cepat** | Tambah Produk, Pesanan, Mitra, Keuangan |
| **Perlu Perhatian** | Pesanan baru, stok menipis, **pendaftaran mitra** yang menunggu verifikasi, dan **pencairan mitra** yang menunggu transfer |
| **Ringkasan** | Produk aktif, jumlah terjual, rating Kopdes, total pesanan |

---

### 6.2 Produk Kopdes

Tab **Produk** memakai halaman yang sama dengan UMKM: daftar per halaman, pencarian, filter kategori dan stok, **Atur Stok**, aktivitas stok, serta form **Tambah Produk** tiga tahap (bagian 5.3).

Bedanya untuk Kopdes:

- **Batas stok menipis** diatur per barang (kolom pada tahap Harga & stok). Barang dengan stok di bawah batas ini masuk filter **Menipis**.
- Deskripsi barang boleh dikosongkan.

---

### 6.3 Pesanan & Pengantaran

Tab **Pesanan** berisi dua bagian:

- **Pesanan Masuk** — semua pesanan yang melibatkan barang Kopdes atau mitranya. Saring berdasarkan status, buka detail, lalu perbarui statusnya.
- **Kurir & Pengantaran** — tugaskan kurir ke pesanan yang siap kirim dan pantau pengantaran.

```
Pesanan masuk → Diproses → Siap kirim → Kurir ditugaskan → Diantar → Diterima pembeli → Selesai
```

---

### 6.4 Pesan

Tab **Pesan** berisi percakapan dengan warga.

---

### 6.5 Koperasi

Tab **Koperasi** setara tab **Toko** milik UMKM:

- **Identitas** — logo, nama, status verifikasi Kopdes, status buka/tutup, dan **Lihat toko** (halaman Kopdes yang dilihat warga).
- **Keuangan** — omzet bulan ini dan hari ini, serta tombol **Laporan keuangan** untuk rekap harian, mingguan, dan bulanan (penjualan, jumlah transaksi, COD, dan QRIS).
- **Profil Kopdes** — tentang Kopdes, alamat, kontak & jam buka. Ketuk **Edit** untuk mengubah nama, deskripsi (maks. 500 huruf), dan alamat.
- **Kelola Kopdes** — menu pengurus:

| Menu | Fungsi |
|:---|:---|
| **Mitra UMKM** | Verifikasi pendaftaran mitra (bagian 6.6) |
| **Pencairan mitra** | Transfer saldo mitra (bagian 6.7) |
| **Moderasi produk UMKM** | Turunkan produk mitra yang melanggar |
| **Pengantaran** | Tugaskan kurir dan pantau pengiriman |
| **Pegawai & kurir** | Buat dan kelola akun pegawai/kurir (bagian 6.8) |
| **Kategori barang** | Tambah, ubah, hapus kategori |
| **Lokasi mitra** | Atur titik peta toko mitra UMKM |
| **Asisten AI** | Tanya stok, penjualan, dan tren (bagian 6.9) |
| **Pengaturan Kopdes** | Nomor telepon (boleh telepon kantor) dan jam buka |
| **Keamanan akun** | Ubah kata sandi dan keluar |

Mengubah profil dan pengaturan Kopdes hanya bisa dilakukan oleh **Admin Kopdes**, bukan pegawai.

---

### 6.6 Verifikasi Mitra UMKM

1. **Koperasi → Mitra UMKM** (atau kartu **Pendaftaran mitra** di Dasbor).
2. Buka pendaftaran berstatus **Menunggu verifikasi**. Periksa nama usaha, alamat, nomor ponsel, dan pastikan usahanya **sedesa** dengan Kopdes.
3. Pilih:
   - **Setujui Mitra** — mitra aktif. Akun pemiliknya berubah menjadi akun penjual setelah ia masuk ulang.
   - **Tolak** — tulis alasannya. Pemilik melihat alasan itu dan boleh mengirim ulang.
4. Mitra yang melanggar dapat **ditangguhkan** dengan tombol **Tangguhkan**.

Anda hanya melihat dan memverifikasi mitra **milik Kopdes Anda sendiri**.

---

### 6.7 Pencairan Saldo Mitra

1. **Koperasi → Pencairan mitra** (atau kartu **Pencairan mitra** di Dasbor).
2. Tab **Menunggu** menampilkan permintaan beserta rekening tujuan.
3. Transfer dananya, lalu ketuk **Tandai Sudah Ditransfer**. Bila rekening tidak sesuai, ketuk **Tolak** dan tulis alasannya — nominalnya kembali ke saldo mitra.

---

### 6.8 Pegawai & Kurir

**Koperasi → Pegawai & kurir**:

1. Ketuk **Tambah Pegawai atau Kurir**.
2. Pilih peran **Pegawai** atau **Kurir**, lalu isi nama, email untuk masuk, nomor telepon (opsional), dan kata sandi awal (minimal 8 karakter).
3. Untuk pegawai, atur **Wewenang**: biarkan **Pakai wewenang bawaan pegawai**, atau matikan lalu centang bagian yang boleh dibuka (katalog, pesanan, pengiriman, stok, rekap keuangan, mitra, Asisten AI).
4. Ketuk **Simpan**, lalu berikan email dan kata sandinya kepada yang bersangkutan.

Ketuk akun di daftar untuk mengubah nama, telepon, kata sandi, atau wewenang, atau untuk **Hapus Akun**. Perubahan wewenang berlaku saat pemilik akun masuk berikutnya.

Pegawai yang masuk diarahkan ke **beranda pegawai** sendiri, bukan konsol Admin Kopdes.

---

### 6.9 Asisten AI Koperasi

Buka **Koperasi → Asisten AI**. Ajukan pertanyaan dalam Bahasa Indonesia, misalnya "barang apa yang stoknya hampir habis?" atau "produk apa yang paling laku bulan ini?". Asisten menjawab dari data Kopdes Anda.

---

## 7. FAQ (Pertanyaan Umum)

### Umum

**Q: Apakah aplikasi ini gratis?**
A: Ya, aplikasi KMP Mitra gratis untuk diunduh dan digunakan. Biaya hanya dikenakan saat Anda melakukan pembelian produk.

**Q: Apakah bisa digunakan tanpa internet?**
A: Aplikasi memerlukan koneksi internet untuk sebagian besar fitur. Namun, beberapa data yang sudah dimuat (katalog produk, profil) dapat diakses dalam mode offline melalui cache lokal.

**Q: Bagaimana cara memperbarui aplikasi?**
A: Unduh file APK versi terbaru dan instal. Data akun Anda tetap tersimpan di server.

### Customer

**Q: Bagaimana cara membatalkan pesanan?**
A: Pesanan yang belum diproses dapat dibatalkan melalui halaman Detail Pesanan → ketuk "Batalkan Pesanan". Pesanan yang sudah diproses tidak dapat dibatalkan.

**Q: Berapa lama pengiriman?**
A: Waktu pengiriman tergantung jarak dan ketersediaan kurir. Pantau statusnya di Detail Pesanan → Lacak Pesanan.

**Q: Apakah bisa memilih kurir sendiri?**
A: Saat ini, kurir ditentukan oleh sistem koperasi. Default menggunakan kurir milik Kopdes.

### UMKM

**Q: Berapa lama proses verifikasi UMKM?**
A: Tergantung pengurus Kopdes desa Anda. Aplikasi belum mengirim kabar saat keputusan dibuat, jadi buka Profil → Daftar Mitra UMKM untuk melihat statusnya.

**Q: Apakah ada biaya untuk berjualan?**
A: Tidak ada biaya pendaftaran. Setiap penjualan dipotong fee 5% untuk Kopdes sebagai biaya promosi/platform.

**Q: Bisakah saya mengantar pesanan sendiri?**
A: Belum. Saat ini semua pesanan diantar kurir Kopdes. Pengantaran oleh UMKM sendiri (dengan ongkir masuk ke UMKM) belum tersedia di aplikasi.

### Admin Kopdes

**Q: Bagaimana cara melihat laporan penjualan?**
A: Dasbor menampilkan omzet hari ini dan bulan ini. Rekap lengkap per hari, minggu, dan bulan ada di Koperasi → Laporan keuangan.

**Q: Bagaimana jika ada anomali stok?**
A: Periksa aktivitas stok di tab Produk — setiap penambahan dan pengurangan tercatat beserta alasannya. Asisten AI juga bisa ditanya tentang stok yang janggal.

---

## 8. Kontak & Bantuan

Jika Anda mengalami kendala atau membutuhkan bantuan, silakan hubungi:

| Kanal | Detail |
|:---|:---|
| **Asisten AI** | Tersedia 24/7 di tab AI dalam aplikasi |
| **Chat Admin** | Hubungi admin koperasi melalui fitur Chat |
| **Email** | Hubungi admin koperasi Anda melalui email yang tertera di profil koperasi |

---

> **KMP Mitra — KOPDES: Smart Cooperative Intelligence System**
> *Memberdayakan Koperasi Desa dan UMKM Melalui Teknologi Digital dan Kecerdasan Buatan.*

---

*Dokumen ini dibuat secara otomatis berdasarkan fitur-fitur yang tersedia pada aplikasi KMP Mitra versi 1.0.0. Fitur dapat berubah atau bertambah pada versi selanjutnya.*
