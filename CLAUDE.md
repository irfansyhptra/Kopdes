# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project Overview

**KOPDES — Smart Cooperative Intelligence System.** Ekosistem digital koperasi
desa (marketplace + logistik + AI). Repo ini berisi **dua codebase**:

- **Frontend** — aplikasi Flutter (Dart) di `lib/`.
- **Backend** — API NestJS (TypeScript) di `backend/`. Folder ini **di-`.gitignore`
  dari repo utama dan punya `.git` sendiri** — commit backend dilakukan terpisah,
  bukan dari repo root.

## Business Domain (baca ini sebelum menyentuh alur bisnis)

- **1 desa = 1 Kopdes.** Kopdes adalah koperasi desa: toko ritel (seperti
  minimarket) sekaligus operator marketplace di desanya.
- **Marketplace** menampilkan barang milik Kopdes **dan** barang UMKM mitra.
- **UMKM harus jadi mitra** di bawah Kopdes desanya untuk bisa berjualan:
  1. UMKM mengajukan pendaftaran mitra lewat sistem, melengkapi data yang
     membuktikan lokasinya **sedesa** dengan Kopdes.
  2. **Admin Kopdes memverifikasi** — approve/reject (lihat `UMKMStatus`:
     `PENDING_VERIFICATION` → `ACTIVE` / `REJECTED` / `SUSPENDED`).
- **Aliran uang:**
  - **Fee penjualan UMKM → rekening Kopdes** (biaya promosi/platform).
  - **Ongkir → rekening UMKM** bila UMKM mengantar sendiri.
- **Kurir:** default kurir milik Kopdes. UMKM boleh mengantar pesanannya sendiri.
- **Checkout customer — dua metode fulfillment:**
  1. **Pickup** — barang disiapkan Kopdes/UMKM, customer ambil di tempat (tanpa antri).
  2. **Delivery** — barang disiapkan lalu diantar kurir; delivery dual-validation
     (koordinat GPS kurir saat antar + customer saat terima).

### Roles (`enum Role`)
`SUPER_ADMIN`, `ADMIN_KOPDES`, `CUSTOMER`, `UMKM`, `COURIER`.

### Status enums (backend/prisma/schema.prisma)
`OrderStatus`, `PaymentStatus` (QRIS/COD), `DeliveryStatus`, `UMKMStatus`,
`InventoryTransactionType`. Selalu rujuk schema sebagai sumber kebenaran, jangan
hardcode string status.

## Architecture

### Frontend (`lib/`) — Flutter + Clean Architecture
Tiap fitur di `lib/features/<fitur>/` dipecah menjadi `data / domain / presentation`:
- `data/` — models, datasources (remote/local), repositories impl, services
- `domain/` — entities, repository interfaces, usecases
- `presentation/` — screens, widgets, providers/controllers (Riverpod)

Fitur yang ada: `auth`, `product` (+ `admin`), `umkm` (seller), `home`, `splash`,
`delivery`, `ai_assistant`.

Kode lintas-fitur:
- `lib/core/` — `network` (Dio + interceptor JWT), `storage` (Isar), `routing`
  (go_router), `theme`, `config`, `error`, `constants`
- `lib/shared/` — komponen & widget reusable

Stack: **Riverpod** (state), **go_router** (routing), **Dio** (HTTP, JWT auto),
**Isar** (cache offline), **flutter_secure_storage** (token), **Freezed** +
**json_serializable** (models).

### Backend (`backend/src/`) — NestJS + Prisma
- Modul di `backend/src/modules/<modul>/`: `auth`, `product`, `order`, `cart`,
  `delivery`, `umkm`, `inventory`, `admin`, `community`, `seller`, `ai`, `health`
- `database/` (Prisma service), `cache/` (Redis/Valkey), `storage/` (MinIO S3),
  `qdrant/` (vector DB)
- Auth: JWT + `RolesGuard` (`@Roles(...)` decorator). Deploy serverless di Vercel.
- AI: Gemini + LangChain; Qdrant untuk RAG/semantic search.

## Commands

### Frontend (dari repo root)
```bash
flutter pub get
flutter run
flutter analyze                              # lint (flutter_lints)
flutter test
dart run build_runner build --delete-conflicting-outputs   # regen *.g.dart / *.freezed.dart
flutter build apk
```
Setelah mengubah model Freezed/Isar/json → **wajib jalankan build_runner**.

### Backend (dari `backend/`)
```bash
npm run start:dev        # nest watch mode
npm run lint             # eslint --fix
npm test                 # jest
npx prisma generate      # setelah ubah schema.prisma
npx prisma migrate dev   # buat migration
```

## Pola Data & Jaringan (WAJIB untuk fitur baru)

Fitur `product` adalah implementasi rujukannya. Ikuti bentuk yang sama.

### 1. Data source mengembalikan JSON mentah, bukan model

```dart
Future<Map<String, dynamic>> fetchProducts({...});  // bukan List<ProductModel>
```

Cache menyimpan payload apa adanya, jadi data dari jaringan dan dari cache
melewati `fromJson` yang sama. Kalau data source men-decode lebih dulu, cache
butuh jalur pemetaannya sendiri — jalur kedua itulah yang dulu diam-diam
membuang `categoryId` dan memaksa `isActive = true`.

### 2. Repository membungkus baca dengan `cachedFetch`

```dart
return cachedFetch(
  cache: cache,                       // ref.watch(apiCacheProvider)
  key: CacheKeys.productList(sig),    // kunci HARUS memuat semua filter
  ttl: CacheTtl.short,                // long = 12 jam, short = 5 menit
  forceRefresh: forceRefresh,         // untuk tarik-untuk-muat-ulang
  fetch: () => remote.fetchProducts(...),
  decode: (json) => Paginated.fromJson(json, 'products', ProductModel.fromJson),
);
```

Perilakunya: cache segar → langsung, tanpa jaringan. Cache basi → tampilkan
seketika lalu segarkan di latar belakang. Cache kosong → tunggu jaringan.
Jaringan mati → pakai cache basi sampai `CacheTtl.offlineGrace` (7 hari).

**Setiap operasi tulis wajib membatalkan cache baca yang terdampak**
(`cache.invalidatePrefix(...)` / `cache.invalidate(...)`), kalau tidak pengguna
melihat data lamanya sendiri selama TTL masih berjalan.

Tambahkan kunci baru di `CacheKeys` (`lib/core/storage/api_cache.dart`) — jangan
merangkai string kunci di tempat pemakaian. Fitur baru **tidak perlu skema Isar
baru**; koleksi `CachedResponse` melayani semuanya.

### 3. Daftar selalu berhalaman

Kembalikan `Paginated<T>` dan baca `meta` dari backend. Pola muat-lebih-banyak
ada di `ProductListNotifier`: penjaga `isLoadingMore` mencegah scroll cepat
memicu permintaan ganda untuk halaman yang sama. Jangan mengambil `limit: 100`
untuk "menghindari paginasi".

Filter (kategori, pencarian) dikirim ke server lewat `catalogQueryProvider`,
**bukan** disaring dengan `.where()` di layar — menyaring satu halaman secara
lokal memberi hasil salah begitu data lebih panjang dari satu halaman, dan tetap
mengunduh baris yang akhirnya dibuang.

### 4. Retry hanya untuk metode idempoten

`RetryInterceptor` mengulang GET/HEAD/OPTIONS dan 502/503/504 dengan backoff
eksponensial + jitter. **POST/PUT/DELETE tidak pernah diulang diam-diam**:
timeout tidak berarti server menolak permintaan, jadi mengulang `POST /orders`
bisa membuat pesanan ganda. Endpoint yang benar-benar idempoten di sisi server
boleh ikut serta lewat `retryable()`.

GET identik yang sedang berjalan digabung oleh `InFlightDedupeInterceptor` —
jangan menambah lapisan dedup sendiri di provider.

### 5. Keadaan memuat memakai skeleton, bukan spinner

Pakai `lib/shared/widgets/skeleton_loaders.dart` dan cocokkan ukurannya dengan
widget aslinya supaya tata letak tidak melompat saat data datang. Spinner hanya
untuk indikator "memuat halaman berikutnya" di kaki daftar.

### 6. Jangan log di build rilis

Logger permintaan/respons hanya dipasang saat `EnvConfig.enableLogging`. Jangan
mencetak token ke log.

## Conventions

- **Dart**: nama file `snake_case` (mis. `product_service.dart`), class `PascalCase`.
- **TypeScript**: ikuti pola NestJS yang ada (`*.module.ts`, `*.service.ts`,
  `*.controller.ts`, DTO di `dto/`).
- Jangan edit file generated: `*.g.dart`, `*.freezed.dart`, `dist/`, Prisma client.
- Commit conventional (`feat:`, `fix:`, `docs:`, `chore:`). Backend punya git sendiri.
- `backend/.env` berisi secret — jangan commit / jangan tampilkan isinya.

## Docs
`requirements.md`, `tasks.md`, `design.md`, `new_design.md`, `report.md` — spec &
perencanaan produk. Rujuk saat butuh konteks fitur yang belum ada di kode.
