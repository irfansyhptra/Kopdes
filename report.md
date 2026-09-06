# KOPDES — Laporan Fitur, Endpoint, dan Status Pengembangan

Dokumen ini memetakan tiga hal: **fitur apa yang tersedia untuk setiap peran**,
**endpoint API mana yang sudah dibuat untuk peran itu**, dan **apa saja yang
masih bermasalah atau belum selesai**.

Struktur repo:

| Bagian | Lokasi | Stack |
|---|---|---|
| Aplikasi mobile | `lib/` | Flutter, Riverpod, go_router, Dio, Isar |
| API | `backend/` (git terpisah) | NestJS, Prisma, PostgreSQL, Redis, MinIO, Qdrant |
| Landing page | `website/landing/` | Next.js (static export) |

**Base URL API:** `https://backend-kopdes.vercel.app/api/v1`
(prefix di-set lewat `setGlobalPrefix('api/v1')` — `backend/src/main.ts:14`)

**Peran yang dikenali sistem** (`enum Role`, `backend/prisma/schema.prisma:10`):
`SUPER_ADMIN`, `ADMIN_KOPDES`, `PEGAWAI_KOPDES`, `CUSTOMER`, `UMKM`, `COURIER`.

> Catatan: `PEGAWAI_KOPDES` ada di schema dan dipakai di banyak `@Roles(...)`,
> tapi belum punya tampilan sendiri di aplikasi — praktis ia mewarisi seluruh
> hak akses `ADMIN_KOPDES`.

---

## 1. Fitur per Peran

### 1.1 Customer (Warga Desa)

Peran default saat mendaftar. Rutenya memakai shell dengan bottom navigation.

| Fitur | Layar | Status |
|---|---|---|
| Registrasi & login | `/register`, `/login` | Berfungsi penuh |
| Onboarding & splash | `/onboarding`, `/splash` | Berfungsi penuh |
| Beranda — kategori, produk, promo | `/home` | Data live dari API |
| Katalog marketplace | `/products` | **Menampilkan data hardcoded** (lihat §3.6) |
| Detail produk | `/products/detail/:id` | Data live |
| Keranjang belanja | `/cart` | Berfungsi penuh |
| Checkout QRIS / COD | `/checkout` | Berfungsi, tapi alamat masih hardcoded (§3.5) |
| Riwayat & detail pesanan | `/orders/history`, `/orders/:id` | Berfungsi penuh |
| Lihat invoice | Widget di detail pesanan | Berfungsi |
| Lacak pengiriman | `/tracking/:id` | **UI saja, tanpa data** (§3.8) |
| Konfirmasi "barang diterima" | — | **Belum ada tombolnya di aplikasi** (§3.7) |
| Notifikasi | `/notifications` | **Isinya data contoh statis** (§3.9) |
| Asisten AI | `/ai-assistant` | Berfungsi (mode "Umum") |
| Usulan produk komunitas | — | Backend siap, **UI belum dibuat** (§3.10) |
| Profil | `/profile` | Berfungsi |

### 1.2 UMKM (Penjual Mitra)

UMKM mendaftar, lalu menunggu verifikasi Admin Kopdes sebelum bisa berjualan.
Statusnya: `PENDING_VERIFICATION` → `ACTIVE` / `REJECTED` / `SUSPENDED`.

| Fitur | Layar | Status |
|---|---|---|
| Dashboard penjualan | `/umkm` | Berfungsi — omzet hari ini, omzet bulanan, jumlah produk, pesanan baru, rating toko, produk menipis |
| Daftar produk toko | `/umkm/products` | Berfungsi, dengan pencarian & filter kategori |
| Tambah / ubah produk | `/umkm/products/new`, `/umkm/products/edit/:id` | Berfungsi, termasuk unggah gambar |
| Detail produk | `/umkm/products/detail/:id` | Berfungsi (bagian ulasan masih contoh) |
| Kelola pesanan masuk | `/umkm/orders` | Berfungsi — tab pesanan baru / siap dipickup / selesai |
| Ubah status pesanan | `/umkm/orders` | Berfungsi |
| Inventaris toko | `/umkm/inventory` | Menampilkan stok dari daftar produk; **belum ada pencatatan stok masuk/keluar** (§3.4) |
| Profil toko | `/umkm/profile` | Berfungsi |
| Statistik penjualan | Dashboard | Berfungsi |
| Asisten AI khusus UMKM | — | Endpoint `POST /ai/umkm` sudah ada, **belum dipanggil aplikasi** |

### 1.3 Admin Kopdes (Pengurus Koperasi)

| Fitur | Layar | Status |
|---|---|---|
| Dashboard ringkasan | `/admin` | Berfungsi — tapi angkanya dihitung di sisi aplikasi (§3.12) |
| Kelola produk koperasi | `/admin/products` + `new` / `edit/:id` | Berfungsi penuh |
| Kelola kategori | `/admin/categories` | Berfungsi penuh |
| Verifikasi mitra UMKM | `/admin/mitra` | Berfungsi — approve / reject / suspend |
| Takedown produk UMKM | `/admin/umkm-products` | Berfungsi |
| Kelola semua pesanan | `/admin/orders` | Berfungsi — lihat, filter status, ubah status |
| Kelola kurir & penugasan | `/admin/couriers` | Berfungsi — daftar kurir, daftar pengiriman, assign kurir |
| Chat dengan pelanggan/mitra | `/admin/chat`, `/chat/:id` | Berfungsi |
| Profil admin | `/admin/profile` | Berfungsi |
| AI: ringkasan manajemen | Asisten AI mode "Gudang" | Berfungsi |
| AI: analisis permintaan komunitas | Asisten AI mode "Gudang" | Berfungsi |
| AI: saran pengadaan stok | Asisten AI mode "Gudang" | Berfungsi |
| AI: deteksi anomali stok | Asisten AI mode "Gudang" | Berfungsi |
| AI: dashboard eksekutif | — | Endpoint ada, **belum dipakai aplikasi** |

### 1.4 Kurir

| Fitur | Layar | Status |
|---|---|---|
| Dashboard tugas antar | `/courier` | **UI saja — belum tersambung ke API sama sekali** (§3.8) |
| Daftar pengiriman | — | Endpoint ada, belum dipanggil |
| Tandai "sudah diantar" | — | Endpoint ada, belum dipanggil |
| Kirim titik GPS | — | Endpoint ada, belum dipanggil |

Seluruh endpoint kurir sudah siap di backend. Yang belum ada adalah lapisan
`data/` di aplikasi Flutter untuk memanggilnya.

### 1.5 Super Admin

| Fitur | Layar | Status |
|---|---|---|
| Ringkasan sistem | `/super-admin` | Berfungsi |
| Kelola akun staf | `/super-admin/accounts` | Berfungsi — buat, ubah, hapus |
| Daftar seluruh pengguna | `/super-admin/users` | Berfungsi, dengan filter |
| Pantau kesehatan sistem | — | Endpoint `/health/*` ada, **belum ada layarnya** |

---

## 2. Endpoint per Peran

Semua path relatif terhadap `/api/v1`. Kolom **Dipakai app** menandai apakah
endpoint tersebut benar-benar dipanggil aplikasi Flutter saat ini.

### 2.1 Publik (tanpa login)

| Method | Path | Fungsi | Dipakai app |
|---|---|---|---|
| POST | `/auth/register` | Daftar akun | Ya |
| POST | `/auth/login` | Masuk | Ya |
| POST | `/auth/refresh` | Perbarui token | Ya |
| GET | `/products` | Daftar produk | Ya |
| GET | `/products/:id` | Detail produk | Ya |
| GET | `/categories` | Daftar kategori | Ya |
| GET | `/categories/:id` | Detail kategori | Tidak |
| GET | `/community/suggestions` | Daftar usulan warga | Tidak |
| POST | `/ai/chat` | Tanya asisten AI | Ya |
| GET | `/health` | Status sistem | Tidak |
| GET | `/health/database` \| `/redis` \| `/storage` \| `/qdrant` | Status per komponen | Tidak |
| POST | `/admin/seed` | Isi data awal | Tidak — **tidak terkunci sama sekali** (§3.3) |

### 2.2 Customer (butuh login)

| Method | Path | Fungsi | Dipakai app |
|---|---|---|---|
| GET | `/auth/me` | Profil sendiri | Ya |
| PUT | `/auth/profile` | Ubah profil | Ya |
| GET | `/cart` | Isi keranjang | Ya |
| POST | `/cart/add` | Tambah ke keranjang | Ya |
| PUT | `/cart/update` | Ubah jumlah | Ya |
| DELETE | `/cart/remove` | Hapus satu item | Ya |
| DELETE | `/cart/clear` | Kosongkan keranjang | Ya |
| POST | `/orders/checkout` | Checkout dari keranjang | Ya |
| POST | `/orders` | Pesan langsung tanpa keranjang | Ya |
| GET | `/orders/history` | Riwayat pesanan | Ya |
| GET | `/orders/:id` | Detail pesanan | Ya |
| GET | `/orders/:id/invoice` | Invoice | Tidak |
| GET | `/orders/:id/timeline` | Jejak status pesanan | Ya |
| PUT | `/orders/:id/status` | Ubah status pesanan | Tidak — **tanpa penjagaan peran** (§3.2) |
| POST | `/orders/:id/confirm-receipt` | Konfirmasi barang diterima | **Tidak** (§3.7) |
| POST | `/community/suggestions` | Ajukan usulan produk | Tidak |
| POST | `/community/suggestions/:id/support` | Dukung usulan | Tidak |
| GET | `/chat/conversations` | Daftar percakapan | Ya |
| POST | `/chat/conversations` | Mulai percakapan | Ya |
| GET | `/chat/conversations/:id/messages` | Baca pesan | Ya |
| POST | `/chat/conversations/:id/messages` | Kirim pesan | Ya |
| PATCH | `/chat/conversations/:id/read` | Tandai sudah dibaca | Ya |

### 2.3 UMKM

Seluruhnya dijaga `@Roles(Role.UMKM)`.

| Method | Path | Fungsi | Dipakai app |
|---|---|---|---|
| GET | `/seller/dashboard` | Ringkasan toko | Ya |
| GET | `/seller/statistics` | Statistik penjualan | Ya |
| GET | `/seller/profile` | Profil toko | Ya |
| PUT | `/seller/profile` | Ubah profil toko | Ya |
| GET | `/seller/products` | Daftar produk toko | Ya |
| POST | `/seller/products` | Tambah produk | Ya |
| PUT | `/seller/products/:id` | Ubah produk | Ya |
| DELETE | `/seller/products/:id` | Hapus produk | Ya |
| GET | `/seller/orders` | Pesanan masuk | Ya |
| GET | `/seller/orders/:id` | Detail pesanan | Ya |
| PUT | `/seller/orders/:id/status` | Ubah status pesanan | Ya |
| POST | `/ai/umkm` | Saran bisnis dari AI | Tidak |

### 2.4 Admin Kopdes & Pegawai Kopdes

Dijaga `@Roles(ADMIN_KOPDES, PEGAWAI_KOPDES, SUPER_ADMIN)` — kecuali CRUD
produk & kategori yang hanya `ADMIN_KOPDES` dan `SUPER_ADMIN`.

| Method | Path | Fungsi | Dipakai app |
|---|---|---|---|
| POST | `/products` | Tambah produk koperasi | Ya |
| PUT | `/products/:id` | Ubah produk | Ya |
| DELETE | `/products/:id` | Hapus produk | Ya |
| POST | `/categories` | Tambah kategori | Ya |
| PUT | `/categories/:id` | Ubah kategori | Ya |
| DELETE | `/categories/:id` | Hapus kategori | Ya |
| GET | `/admin/orders` | Semua pesanan | Ya |
| GET | `/admin/orders/:id` | Detail pesanan | Tidak |
| PATCH | `/admin/orders/:id/status` | Ubah status pesanan | Ya |
| GET | `/admin/umkm` | Daftar mitra UMKM | Ya |
| GET | `/admin/umkm/:id` | Detail mitra | Tidak |
| PATCH | `/admin/umkm/:id/verify` | Verifikasi mitra | Ya |
| GET | `/admin/umkm/products` | Produk seluruh mitra | Ya |
| PATCH | `/admin/umkm/products/:id/takedown` | Turunkan produk mitra | Ya |
| GET | `/admin/couriers` | Daftar kurir | Ya |
| GET | `/admin/deliveries` | Daftar pengiriman | Ya |
| PATCH | `/admin/deliveries/:id/assign` | Tugaskan kurir | Ya |
| POST | `/ai/management` | Ringkasan manajemen | Ya |
| POST | `/ai/community` | Analisis permintaan warga | Ya |
| POST | `/ai/inventory` | Saran pengadaan stok | Ya |
| POST | `/ai/anomaly` | Deteksi anomali stok | Ya |
| GET | `/ai/executive-dashboard` | Dashboard eksekutif | Tidak |
| POST | `/ai/seed-knowledge` | Isi basis pengetahuan AI | Tidak |

### 2.5 Kurir

Dijaga `@Roles(Role.COURIER)`. **Belum satupun dipanggil aplikasi.**

| Method | Path | Fungsi |
|---|---|---|
| GET | `/courier/deliveries` | Daftar tugas antar |
| PATCH | `/courier/deliveries/:id/mark-delivered` | Tandai sudah diantar |
| POST | `/courier/deliveries/:id/location` | Kirim titik GPS |

### 2.6 Super Admin

Dijaga `@Roles(Role.SUPER_ADMIN)`.

| Method | Path | Fungsi | Dipakai app |
|---|---|---|---|
| GET | `/super-admin/overview` | Ringkasan sistem | Ya |
| GET | `/super-admin/accounts` | Daftar akun staf | Ya |
| POST | `/super-admin/accounts` | Buat akun staf | Ya |
| PATCH | `/super-admin/accounts/:id` | Ubah akun staf | Ya |
| DELETE | `/super-admin/accounts/:id` | Hapus akun staf | Ya |
| GET | `/super-admin/users` | Daftar seluruh pengguna | Ya |

---

## 3. Bug & Pekerjaan yang Belum Selesai

Diurutkan dari yang paling mendesak.

### KRITIS — harus ditutup sebelum produksi

#### 3.1 Token palsu diterima sebagai token asli — siapa pun bisa jadi Super Admin

`backend/src/modules/auth/guards/jwt-auth.guard.ts:25`

`JwtAuthGuard` memeriksa token dengan urutan berikut: kalau token diawali
`mock_jwt_access_token_for_`, sisa string di belakangnya langsung dipakai
sebagai **peran**, guard mengembalikan `true`, dan verifikasi JWT yang
sebenarnya tidak pernah dijalankan.

Artinya cukup mengirim header:

```
Authorization: Bearer mock_jwt_access_token_for_SUPER_ADMIN
```

untuk mendapat akses penuh sebagai Super Admin tanpa punya akun apa pun. Hal
yang sama berlaku untuk `ADMIN_KOPDES`, `COURIER`, dan seterusnya. Ada juga
jalur kedua lewat token literal `mock_refreshed_access_token` (baris 35) yang
memberi akses sebagai Customer.

Ini sisa dari mode uji coba offline. **Kedua blok itu harus dihapus.**

#### 3.2 Ubah status pesanan tanpa penjagaan peran maupun kepemilikan

`backend/src/modules/order/order.controller.ts:41` dan
`backend/src/modules/order/order.service.ts:485`

`PUT /orders/:id/status` hanya dijaga `JwtAuthGuard` — tidak ada `RolesGuard`,
dan di dalam `updateStatus()` tidak ada pemeriksaan bahwa pesanan itu milik si
pemanggil. Setiap pengguna yang sudah login bisa mengubah status **pesanan
siapa pun** hanya dengan tahu ID-nya.

Dampak terburuknya: mengirim `status: "PAID"` membuat service ikut menandai
`paymentStatus = PAID` dan mengisi `paidAt` pada tabel `Payment` — pesanan
tercatat lunas tanpa uang benar-benar masuk.

Endpoint `GET /orders/:id/timeline` (baris 61) punya masalah senada: tidak ada
pengecekan kepemilikan sama sekali, sehingga jejak audit pesanan orang lain
bisa dibaca siapa saja yang sudah login.

Perbaikannya: samakan pola dengan `getOrderDetail()` yang sudah menerima
`userId` dan `role` untuk memfilter akses.

#### 3.3 Endpoint seeder terbuka untuk publik

`backend/src/modules/admin/seed.controller.ts:8`

`POST /api/v1/admin/seed` sama sekali tidak memakai `JwtAuthGuard` maupun
`RolesGuard`. Siapa pun yang tahu URL-nya bisa memanggil seeder di server
produksi. Perlu dikunci `@Roles(Role.SUPER_ADMIN)`, atau dimatikan total di
lingkungan produksi.

### TINGGI — fitur yang dijanjikan tapi belum tersambung

#### 3.4 Modul Inventory kosong

`backend/src/modules/inventory/` hanya berisi `inventory.module.ts` — tanpa
controller, tanpa service. Padahal:

- tabel `InventoryTransaction` sudah ada dan sudah diisi otomatis oleh proses
  checkout dan pembatalan pesanan;
- aplikasi punya rute `/umkm/inventory`;
- fitur "deteksi anomali stok" mengandalkan riwayat transaksi ini.

Belum ada satu pun endpoint untuk membaca riwayat stok, melakukan stok opname,
atau mencatat penyesuaian manual. Layar inventaris UMKM saat ini hanya
menampilkan ulang angka stok dari daftar produk.

#### 3.5 Alamat pengiriman masih hardcoded

`lib/features/order/presentation/screens/checkout_screen.dart:18` mengirim
`deliveryAddressId = 'default-mock-address-id'` untuk semua pesanan. Backend
menyambut ID itu dengan membuatkan alamat karangan atas nama "Budi Santoso,
Jl. Merdeka No. 10, Sleman" (`order.service.ts:49`, dan diulang di `:230`).

Akibatnya seluruh pesanan dari aplikasi dikirim ke alamat yang sama dan palsu.
Yang belum ada: layar pemilihan/penambahan alamat, dan endpoint CRUD untuk
tabel `Address` (tabelnya sudah ada di schema, controller-nya belum).

#### 3.6 Katalog marketplace menampilkan produk karangan

`lib/features/product/presentation/screens/product_catalog_screen.dart:589`

```dart
data: (backendProducts) {
  final displayItems = _mockMarketplaceProducts;   // hasil API dibuang
```

Layar ini memanggil API, menunggu hasilnya, lalu **mengabaikan hasil itu** dan
merender daftar produk hardcoded dari `_mockMarketplaceProducts` (baris 67).
Cabang `error` juga jatuh ke daftar yang sama, jadi kegagalan API tidak pernah
terlihat. Perbaikannya satu baris: pakai `backendProducts`.

#### 3.7 Validasi ganda putus di langkah kedua

Alur validasi ganda dirancang dua tahap:

1. Kurir menekan "sudah diantar" → `DeliveryStatus.COURIER_DELIVERED`, pesanan
   jadi `DELIVERED`, notifikasi dikirim ke pembeli.
2. Pembeli menekan "barang sudah diterima" → pengiriman `COMPLETED`, pesanan
   `COMPLETED`, dan **khusus COD di sinilah pembayaran baru ditandai lunas**.

Backend sudah lengkap (`delivery.service.ts:110` dan `:171`), tapi aplikasi
Flutter **tidak pernah memanggil `POST /orders/:id/confirm-receipt`**. Tidak
ada tombolnya di layar mana pun.

Akibatnya setiap pesanan mentok di status `DELIVERED`, tidak pernah
`COMPLETED`, dan **seluruh transaksi COD tidak pernah tercatat lunas**.

#### 3.8 Fitur kurir sepenuhnya belum tersambung

`lib/features/courier/` hanya berisi satu file layar. Tidak ada folder `data/`,
tidak ada satu pun pemanggilan API. Layar `/courier` menampilkan tampilan statis.

Hal yang sama berlaku untuk `lib/features/delivery/tracking_screen.dart` — peta
pelacakan tidak mengambil data `DeliveryLocation` dari server, padahal kurir
sudah punya endpoint untuk mengirim titik GPS. Jadi rantai lengkapnya belum
tersambung: kurir tidak bisa mengirim posisi, dan pembeli tidak bisa melihatnya.

#### 3.9 Notifikasi tidak nyata

`lib/features/notification/presentation/providers/notification_provider.dart:9`
mengisi daftar notifikasi dengan empat entri contoh yang ditulis langsung di
kode, lengkap dengan tanggal tetap Juni 2026.

Sementara itu backend rajin menulis baris ke tabel `Notification` (misalnya saat
kurir menandai barang diantar), tapi **tidak ada satu pun endpoint untuk
membacanya**. Belum ada `NotificationModule` di backend.

#### 3.10 Fitur usulan komunitas tanpa antarmuka

`POST /community/suggestions` dan `POST /community/suggestions/:id/support`
sudah jadi dan sudah punya unit test. Fitur "suara warga" ini juga jadi sumber
data untuk analisis AI `POST /ai/community`. Tapi belum ada layar di aplikasi
untuk mengajukan atau mendukung usulan, sehingga tabelnya akan selalu kosong
dan analisis AI-nya tidak punya bahan.

### SEDANG — perlu diperbaiki, tapi tidak memblokir

#### 3.11 Timeline pesanan memakai pencarian teks bebas

`backend/src/modules/order/order.service.ts:587`

```ts
where: { details: { contains: orderId } }
```

Riwayat pesanan disusun dengan mencari ID pesanan **di dalam kolom teks bebas**
`AuditLog.details`. Ini rapuh: log apa pun yang kebetulan menyebut ID tersebut
akan ikut terbawa, dan pencarian `LIKE %...%` pada tabel audit yang terus
membesar akan makin lambat. Sebaiknya `AuditLog` diberi kolom `orderId` yang
terindeks.

#### 3.12 Angka dashboard admin dihitung di sisi aplikasi

`lib/features/admin/presentation/screens/admin_dashboard_screen.dart:113`
menggabungkan tiga provider (`adminProductsProvider`, `mitraListProvider`,
`adminOrdersProvider`) lalu menghitung sendiri ringkasannya di perangkat.

Ini menarik seluruh isi tabel pesanan ke ponsel hanya untuk menampilkan
beberapa angka. `listAllForAdmin()` (`order.service.ts:414`) memang belum
mengenal paginasi dan mengambil semua baris beserta relasi produk, gambar,
pembayaran, pengiriman, kurir, pelanggan, dan alamat sekaligus. Akan berat
begitu data bertambah. Sebaiknya dibuat endpoint agregat khusus dashboard.

#### 3.13 Kode QRIS masih string tetap

`backend/src/modules/order/order.service.ts:173` dan `:348` mengisi kolom
`qrisCode` dengan literal `'mock-qris-data-string'`. Belum ada integrasi ke
penyedia pembayaran, jadi jalur pembayaran QRIS belum bisa dipakai sungguhan.
COD adalah satu-satunya metode yang alurnya nyata — itu pun terhambat oleh §3.7.

#### 3.14 Asisten AI memilih endpoint lewat tebakan kata kunci

`lib/features/ai_assistant/presentation/screens/ai_assistant_screen.dart:74`

Saat mode "Gudang" aktif, aplikasi menentukan endpoint tujuan dengan mencocokkan
potongan kata di pertanyaan pengguna — misalnya kata "restok" mengarah ke
`/ai/inventory`, kata "audit" ke `/ai/anomaly`. Pertanyaan yang tidak memuat
kata-kata itu jatuh ke `/ai/management`.

Dua masalahnya: pemilihannya mudah meleset, dan layar ini berada di navigasi
Customer sementara endpoint-endpoint tujuan tadi hanya boleh diakses admin —
seorang Customer yang mengaktifkan mode "Gudang" akan mendapat error 403.
Pemilihan rute seperti ini lebih tepat dikerjakan di backend.

#### 3.15 Pre-order diam-diam menyembunyikan stok minus

`backend/src/modules/order/order.service.ts` — saat stok tidak mencukupi tapi
produk mengizinkan pre-order, stok dipangkas ke `Math.max(0, ...)`. Selisih
antara jumlah yang dipesan dan stok yang tersedia tidak dicatat di mana pun,
sehingga tidak ada cara mengetahui berapa banyak barang yang statusnya utang
pengiriman.

#### 3.16 Bagian ulasan produk masih contoh

`lib/features/umkm/presentation/screens/product_detail_screen.dart:432`
(`_buildMockReviews`) menampilkan ulasan karangan. Tabel `Review` sudah ada di
schema dan sudah dipakai untuk menghitung rating toko di dashboard UMKM, tapi
belum ada endpoint untuk membuat maupun membaca ulasan.

#### 3.17 `PEGAWAI_KOPDES` belum punya batas hak akses sendiri

Peran ini disertakan di hampir semua `@Roles(...)` bersama `ADMIN_KOPDES`,
sehingga secara praktis keduanya identik. Kalau memang dimaksudkan sebagai
peran dengan wewenang lebih terbatas (misalnya boleh melihat pesanan tapi tidak
boleh menghapus produk), pembedanya belum dibuat.

---

## 4. Ringkasan Status

| Kategori | Jumlah |
|---|---|
| Modul backend terdaftar | 14 (+ 4 modul infrastruktur) |
| Modul backend yang berisi endpoint | 13 — `inventory` masih kosong |
| Total endpoint tersedia | 82 |
| Endpoint yang dipanggil aplikasi | 61 |
| Fitur frontend (folder) | 16 |
| Fitur yang punya lapisan `data/` sendiri | 8 — `auth`, `product`, `order`, `umkm`, `admin`, `superadmin`, `chat`, `ai_assistant` |
| Fitur tanpa sambungan API sama sekali | `courier`, `delivery`, `notification`, `debug` |
| Model Prisma | 24 |

**Tiga hal yang paling mendesak:**

1. Hapus penerimaan token palsu di `JwtAuthGuard` (§3.1) — ini lubang keamanan
   yang membuat seluruh sistem hak akses tidak berarti.
2. Tambahkan penjagaan peran dan pemeriksaan kepemilikan pada
   `PUT /orders/:id/status` (§3.2), lalu kunci `POST /admin/seed` (§3.3).
3. Sambungkan langkah kedua validasi ganda (§3.7) — tanpa itu tidak ada satu
   pun pesanan yang bisa selesai, dan pembayaran COD tidak pernah tercatat lunas.

---

*Disusun sebagai laporan status pengembangan KOPDES — Smart Cooperative
Intelligence System.*
