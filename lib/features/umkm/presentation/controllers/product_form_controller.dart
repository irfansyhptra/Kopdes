import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/product_draft_store.dart';
import '../../domain/product_rules.dart';
import '../../domain/repositories/product_repository.dart';
import 'product_controller.dart';
import 'providers.dart';
import 'seller_dashboard_controller.dart';

// ─────────────────────────────────────────────────────────────
// Foto
// ─────────────────────────────────────────────────────────────

enum PhotoStatus { pending, uploading, uploaded, failed }

/// Satu foto di form: berkas lokal yang belum terunggah, atau foto yang
/// sudah tersimpan di server (mode edit).
@immutable
class FormPhoto {
  final String? path;
  final String? url;
  final PhotoStatus status;

  const FormPhoto.local(String this.path, {this.status = PhotoStatus.pending})
    : url = null;
  const FormPhoto.remote(String this.url)
    : path = null,
      status = PhotoStatus.uploaded;

  bool get isRemote => url != null;

  FormPhoto withStatus(PhotoStatus s) =>
      isRemote ? this : FormPhoto.local(path!, status: s);

  @override
  bool operator ==(Object other) =>
      other is FormPhoto && other.path == path && other.url == url;

  @override
  int get hashCode => Object.hash(path, url);
}

enum PhotoSource { camera, gallery }

class PickedPhotos {
  final List<String> paths;

  /// Foto yang tetap di atas batas ukuran setelah dikompres.
  final int tooLarge;

  const PickedPhotos(this.paths, {this.tooLarge = 0});
}

/// Pemilih foto. Dipisah supaya test tidak membuka kamera.
abstract class ProductPhotoPicker {
  Future<PickedPhotos> pick(PhotoSource source, {required int max});
}

class ImagePickerPhotoPicker implements ProductPhotoPicker {
  final ImagePicker _picker = ImagePicker();

  // Kompresi wajar: sisi terpanjang 1600px dan kualitas JPEG 82 — tajam di
  // layar ponsel mana pun, biasanya 200–500 KB alih-alih 3–8 MB.
  static const double _maxSide = 1600;
  static const int _quality = 82;

  @override
  Future<PickedPhotos> pick(PhotoSource source, {required int max}) async {
    final List<XFile> files;
    if (source == PhotoSource.gallery && max > 1) {
      files = await _picker.pickMultiImage(
        maxWidth: _maxSide,
        maxHeight: _maxSide,
        imageQuality: _quality,
        limit: max,
      );
    } else {
      final one = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: _maxSide,
        maxHeight: _maxSide,
        imageQuality: _quality,
      );
      files = [if (one != null) one];
    }

    final ok = <String>[];
    var tooLarge = 0;
    for (final f in files.take(max)) {
      if (await File(f.path).length() > ProductRules.maxPhotoBytes) {
        tooLarge++;
      } else {
        ok.add(f.path);
      }
    }
    return PickedPhotos(ok, tooLarge: tooLarge);
  }
}

final productPhotoPickerProvider = Provider<ProductPhotoPicker>(
  (ref) => ImagePickerPhotoPicker(),
);

// ─────────────────────────────────────────────────────────────
// Isian
// ─────────────────────────────────────────────────────────────

@immutable
class ProductFormData {
  final String name;
  final String? categoryId;
  final String description;

  /// Hanya angka, tanpa pemisah ribuan.
  final String price;
  final String stock;
  final List<FormPhoto> photos;

  const ProductFormData({
    this.name = '',
    this.categoryId,
    this.description = '',
    this.price = '',
    this.stock = '',
    this.photos = const [],
  });

  ProductFormData copyWith({
    String? name,
    String? categoryId,
    String? description,
    String? price,
    String? stock,
    List<FormPhoto>? photos,
  }) => ProductFormData(
    name: name ?? this.name,
    categoryId: categoryId ?? this.categoryId,
    description: description ?? this.description,
    price: price ?? this.price,
    stock: stock ?? this.stock,
    photos: photos ?? this.photos,
  );

  /// Galat per kolom pada [step]; kosong = tahap itu sah.
  Map<String, String> errorsFor(int step, {bool stockLocked = false}) {
    final e = <String, String>{};
    void put(String key, String? message) {
      if (message != null) e[key] = message;
    }

    if (step == 0) {
      put('name', ProductRules.name(name));
      put('category', ProductRules.category(categoryId));
      put('description', ProductRules.description(description));
    } else if (step == 1) {
      put('price', ProductRules.price(price));
      if (!stockLocked) put('stock', ProductRules.stock(stock));
    }
    return e;
  }

  @override
  bool operator ==(Object other) =>
      other is ProductFormData &&
      other.name == name &&
      other.categoryId == categoryId &&
      other.description == description &&
      other.price == price &&
      other.stock == stock &&
      listEquals(other.photos, photos);

  @override
  int get hashCode => Object.hash(
    name,
    categoryId,
    description,
    price,
    stock,
    Object.hashAll(photos),
  );
}

// ─────────────────────────────────────────────────────────────
// Keadaan form
// ─────────────────────────────────────────────────────────────

@immutable
class ProductFormState {
  /// null = produk baru.
  final String? productId;
  final ProductFormData data;

  /// Titik pembanding "ada perubahan yang belum disimpan".
  final ProductFormData saved;
  final int step;

  /// Tahap yang sudah dicoba dilewati — galatnya baru ditampilkan setelah
  /// pengguna menekan Lanjut, bukan saat form baru dibuka.
  final Set<int> validated;
  final bool loading;
  final Object? loadError;
  final bool submitting;
  final bool savingDraft;

  /// Produk baru yang sudah dibuat di server tetapi fotonya belum lengkap.
  /// Mencegah "Kirim" kedua membuat produk ganda.
  final String? createdId;
  final ProductDraft? offeredDraft;
  final DateTime? draftSavedAt;

  const ProductFormState({
    this.productId,
    this.data = const ProductFormData(),
    this.saved = const ProductFormData(),
    this.step = 0,
    this.validated = const {},
    this.loading = false,
    this.loadError,
    this.submitting = false,
    this.savingDraft = false,
    this.createdId,
    this.offeredDraft,
    this.draftSavedAt,
  });

  bool get isEdit => productId != null;
  bool get isDirty => data != saved;

  /// Stok yang sudah ada di server hanya boleh diubah lewat "Atur stok",
  /// yang mencatat riwayat. Menimpanya dari form menghapus jejak itu.
  bool get stockLocked => isEdit || createdId != null;

  /// Server sudah punya produknya; tinggal foto yang belum masuk.
  bool get awaitingPhotos =>
      createdId != null &&
      data.photos.any((p) => p.status != PhotoStatus.uploaded);

  Map<String, String> visibleErrors(int forStep) => validated.contains(forStep)
      ? data.errorsFor(forStep, stockLocked: stockLocked)
      : const {};

  ProductFormState copyWith({
    ProductFormData? data,
    ProductFormData? saved,
    int? step,
    Set<int>? validated,
    bool? loading,
    Object? loadError,
    bool clearLoadError = false,
    bool? submitting,
    bool? savingDraft,
    String? createdId,
    ProductDraft? offeredDraft,
    bool clearOfferedDraft = false,
    DateTime? draftSavedAt,
  }) => ProductFormState(
    productId: productId,
    data: data ?? this.data,
    saved: saved ?? this.saved,
    step: step ?? this.step,
    validated: validated ?? this.validated,
    loading: loading ?? this.loading,
    loadError: clearLoadError ? null : (loadError ?? this.loadError),
    submitting: submitting ?? this.submitting,
    savingDraft: savingDraft ?? this.savingDraft,
    createdId: createdId ?? this.createdId,
    offeredDraft: clearOfferedDraft
        ? null
        : (offeredDraft ?? this.offeredDraft),
    draftSavedAt: draftSavedAt ?? this.draftSavedAt,
  );
}

/// Hasil "Kirim".
sealed class SubmitResult {
  const SubmitResult();
}

class SubmitSucceeded extends SubmitResult {
  const SubmitSucceeded();
}

/// Ada kolom wajib yang belum sah; form sudah pindah ke tahapnya.
class SubmitInvalid extends SubmitResult {
  const SubmitInvalid();
}

/// Tidak ada yang tersimpan — isian tetap utuh.
class SubmitFailed extends SubmitResult {
  final Object error;
  const SubmitFailed(this.error);
}

/// Produk tersimpan, sebagian foto belum.
class SubmitPhotosPending extends SubmitResult {
  final int remaining;
  final Object error;
  const SubmitPhotosPending(this.remaining, this.error);
}

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  final ProductRepository _repository;
  final ProductDraftStore _drafts;
  final Ref _ref;

  static const int lastStep = 2;

  ProductFormNotifier(
    this._repository,
    this._drafts,
    this._ref, {
    String? productId,
  }) : super(
         ProductFormState(productId: productId, loading: productId != null),
       ) {
    if (productId != null) {
      _loadProduct();
    } else {
      _offerDraft();
    }
  }

  Future<void> _loadProduct() async {
    state = state.copyWith(loading: true, clearLoadError: true);
    try {
      final p = await _repository.getProduct(state.productId!);
      final data = ProductFormData(
        name: p.name,
        categoryId: p.categoryId,
        description: p.description,
        price: p.price.toStringAsFixed(0),
        stock: '${p.stock}',
        photos: [for (final i in p.images) FormPhoto.remote(i.url)],
      );
      if (!mounted) return;
      state = state.copyWith(data: data, saved: data, loading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, loadError: e);
    }
  }

  Future<void> retryLoad() => _loadProduct();

  Future<void> _offerDraft() async {
    final draft = await _drafts.load();
    if (!mounted || draft == null) return;
    // Pengguna yang sudah mulai mengetik tidak disela tawaran draf.
    if (state.isDirty) return;
    state = state.copyWith(offeredDraft: draft);
  }

  void restoreDraft() {
    final d = state.offeredDraft;
    if (d == null) return;
    final data = ProductFormData(
      name: d.name,
      categoryId: d.categoryId,
      description: d.description,
      price: d.price,
      stock: d.stock,
      photos: [for (final p in d.photos) FormPhoto.local(p)],
    );
    state = state.copyWith(
      data: data,
      saved: data,
      draftSavedAt: d.savedAt,
      clearOfferedDraft: true,
    );
  }

  Future<void> discardDraft() async {
    state = state.copyWith(clearOfferedDraft: true);
    await _drafts.clear();
  }

  // ── isian ──────────────────────────────────────────────────

  void _edit(ProductFormData data) => state = state.copyWith(data: data);

  void setName(String v) => _edit(state.data.copyWith(name: v));
  void setCategory(String id) => _edit(state.data.copyWith(categoryId: id));
  void setDescription(String v) => _edit(state.data.copyWith(description: v));
  void setPrice(String digits) => _edit(state.data.copyWith(price: digits));
  void setStock(String digits) => _edit(state.data.copyWith(stock: digits));

  int get photoSlotsLeft => ProductRules.maxPhotos - state.data.photos.length;

  void addPhotos(List<String> paths) {
    final room = photoSlotsLeft;
    if (room <= 0 || paths.isEmpty) return;
    _edit(
      state.data.copyWith(
        photos: [
          ...state.data.photos,
          for (final p in paths.take(room)) FormPhoto.local(p),
        ],
      ),
    );
  }

  /// Foto yang sudah di server tidak bisa dilepas dari sini: belum ada
  /// endpoint penghapus foto, dan tombol yang tidak menyimpan apa-apa
  /// lebih buruk daripada tidak ada tombol.
  bool canEditPhoto(int i) => !state.data.photos[i].isRemote;

  /// Urutan hanya bisa diatur selama belum ada foto di server: foto pertama
  /// yang masuk ke server menjadi foto utama, dan urutannya tidak bisa
  /// diubah setelahnya.
  bool get canReorder => state.data.photos.every((p) => !p.isRemote);

  void removePhoto(int i) {
    if (!canEditPhoto(i)) return;
    _edit(state.data.copyWith(photos: [...state.data.photos]..removeAt(i)));
  }

  void movePhoto(int from, int to) {
    if (!canReorder) return;
    final list = [...state.data.photos];
    if (from < 0 || from >= list.length || to < 0 || to >= list.length) {
      return;
    }
    list.insert(to, list.removeAt(from));
    _edit(state.data.copyWith(photos: list));
  }

  void makePrimary(int i) => movePhoto(i, 0);

  // ── tahap ──────────────────────────────────────────────────

  /// Lanjut dari tahap aktif. Mengembalikan false bila ada kolom wajib yang
  /// belum sah — galatnya tampil di kolomnya.
  bool next() {
    final step = state.step;
    final errors = state.data.errorsFor(step, stockLocked: state.stockLocked);
    state = state.copyWith(validated: {...state.validated, step});
    if (errors.isNotEmpty) return false;
    if (step < lastStep) state = state.copyWith(step: step + 1);
    return true;
  }

  /// Kembali ke tahap mana pun yang sudah dilewati, tanpa kehilangan isian.
  void goTo(int step) {
    if (step < 0 || step > lastStep || step > state.step) return;
    state = state.copyWith(step: step);
  }

  bool back() {
    if (state.step == 0) return false;
    state = state.copyWith(step: state.step - 1);
    return true;
  }

  // ── draf ──────────────────────────────────────────────────

  Future<bool> saveDraft() async {
    if (state.isEdit || state.savingDraft || state.submitting) return false;
    state = state.copyWith(savingDraft: true);
    try {
      final d = state.data;
      final saved = await _drafts.save(
        ProductDraft(
          name: d.name,
          categoryId: d.categoryId,
          description: d.description,
          price: d.price,
          stock: d.stock,
          photos: [
            for (final p in d.photos)
              if (p.path != null) p.path!,
          ],
          savedAt: DateTime.now(),
        ),
      );
      if (!mounted) return true;
      // Path foto kini milik draf; isian yang tampil memakai salinan itu.
      final data = d.copyWith(
        photos: [for (final p in saved.photos) FormPhoto.local(p)],
      );
      state = state.copyWith(
        data: data,
        saved: data,
        savingDraft: false,
        draftSavedAt: saved.savedAt,
      );
      return true;
    } catch (_) {
      if (mounted) state = state.copyWith(savingDraft: false);
      return false;
    }
  }

  // ── kirim ──────────────────────────────────────────────────

  /// Memeriksa tahap 1–2 sebelum mengirim. Bila ada yang belum sah, form
  /// pindah ke tahap itu dan galatnya ditampilkan.
  bool validateAll() {
    for (final step in [0, 1]) {
      if (state.data
          .errorsFor(step, stockLocked: state.stockLocked)
          .isNotEmpty) {
        state = state.copyWith(
          step: step,
          validated: {...state.validated, step},
        );
        return false;
      }
    }
    return true;
  }

  Future<SubmitResult> submit() async {
    // Penjaga pengiriman ganda: ketukan kedua saat yang pertama masih
    // berjalan tidak boleh membuat produk kedua.
    if (state.submitting) return const SubmitInvalid();

    if (!validateAll()) return const SubmitInvalid();

    state = state.copyWith(submitting: true);
    final d = state.data;
    final price = double.parse(d.price);
    final description = d.description.trim();

    String id;
    try {
      final existing = state.productId ?? state.createdId;
      if (existing == null) {
        final created = await _repository.createProduct(
          name: d.name.trim(),
          description: description,
          price: price,
          stock: int.parse(d.stock),
          categoryId: d.categoryId!,
        );
        id = created.id;
        if (mounted) state = state.copyWith(createdId: id);
      } else {
        // Edit, atau mengulang setelah foto gagal: kolom teks dikirim ulang
        // (idempoten), stok TIDAK — lihat [ProductFormState.stockLocked].
        await _repository.updateProduct(
          id: existing,
          name: d.name.trim(),
          description: description,
          price: price,
          categoryId: d.categoryId,
        );
        id = existing;
      }
    } catch (e) {
      if (mounted) state = state.copyWith(submitting: false);
      return SubmitFailed(e);
    }

    // Satu foto per permintaan, berurutan. Berhenti di kegagalan pertama:
    // melompatinya membuat foto kedua menjadi foto utama.
    Object? photoError;
    final photos = [...d.photos];
    for (var i = 0; i < photos.length; i++) {
      if (photos[i].status == PhotoStatus.uploaded) continue;
      photos[i] = photos[i].withStatus(PhotoStatus.uploading);
      _setPhotos(photos);
      try {
        await _repository.addProductImage(id, photos[i].path!);
        photos[i] = photos[i].withStatus(PhotoStatus.uploaded);
      } catch (e) {
        photos[i] = photos[i].withStatus(PhotoStatus.failed);
        photoError = e;
        _setPhotos(photos);
        break;
      }
      _setPhotos(photos);
    }

    _refreshSellerData(id);
    if (!mounted) return const SubmitSucceeded();

    final remaining = photos
        .where((p) => p.status != PhotoStatus.uploaded)
        .length;
    if (photoError != null) {
      state = state.copyWith(submitting: false);
      return SubmitPhotosPending(remaining, photoError);
    }

    if (!state.isEdit) await _drafts.clear();
    if (mounted) {
      state = state.copyWith(submitting: false, saved: state.data);
    }
    return const SubmitSucceeded();
  }

  void _setPhotos(List<FormPhoto> photos) {
    if (!mounted) return;
    // Status unggah tidak ikut dibandingkan di `FormPhoto.==`, jadi
    // mengubahnya tidak membuat form dianggap punya perubahan baru.
    state = state.copyWith(data: state.data.copyWith(photos: [...photos]));
  }

  void _refreshSellerData(String id) {
    _ref.invalidate(sellerProductListProvider);
    _ref.invalidate(sellerStoreCategoriesProvider);
    _ref.invalidate(sellerProductDetailProvider(id));
    _ref.read(sellerDashboardControllerProvider.notifier).refresh();
  }
}

/// Satu form per produk (null = produk baru). autoDispose: keluar dari
/// halaman membuang isian yang tidak disimpan sebagai draf.
final productFormProvider = StateNotifierProvider.autoDispose
    .family<ProductFormNotifier, ProductFormState, String?>((ref, productId) {
      return ProductFormNotifier(
        ref.watch(productRepositoryProvider),
        ref.watch(productDraftStoreProvider),
        ref,
        productId: productId,
      );
    });
