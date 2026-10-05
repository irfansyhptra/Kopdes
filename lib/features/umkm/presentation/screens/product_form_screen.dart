import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../data/models/product_category_model.dart';
import '../../data/models/seller_product_page.dart';
import '../../domain/product_rules.dart';
import '../../data/store_scope.dart';
import '../controllers/product_controller.dart';
import '../controllers/product_form_controller.dart';
import '../widgets/product_form_ui.dart';
import '../widgets/seller_page_ui.dart';

/// Tambah / ubah produk UMKM dalam tiga tahap: detail, harga & stok, tinjau.
///
/// Isian hidup di [productFormProvider], bukan di widget ini — layar hanya
/// menampilkan dan meneruskan ketikan. Itu yang membuat isian bertahan saat
/// berpindah tahap, bisa disimpan sebagai draf, dan bisa diuji tanpa layar.
class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;
  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  static const _steps = ['Detail produk', 'Harga & stok', 'Tinjau'];

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _minStock = TextEditingController();
  final _scroll = ScrollController();

  AutoDisposeStateNotifierProvider<ProductFormNotifier, ProductFormState>
  get _provider => productFormProvider(widget.productId);

  ProductFormNotifier get _form => ref.read(_provider.notifier);

  @override
  void initState() {
    super.initState();
    _sync(ref.read(_provider).data);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _minStock.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Isian yang datang dari luar ketikan (produk dimuat, draf dipulihkan)
  /// dituang ke kolom. Ketikan sendiri tidak melewati sini.
  void _sync(ProductFormData d) {
    void set(TextEditingController c, String v) {
      if (c.text != v) c.text = v;
    }

    set(_name, d.name);
    set(_description, d.description);
    set(
      _price,
      d.price.isEmpty ? '' : formatThousands(int.tryParse(d.price) ?? 0),
    );
    set(_stock, d.stock);
    set(_minStock, d.minStock);
  }

  void _toTop() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: AppAnimation.normal,
        curve: Curves.easeOut,
      );
    }
  }

  // ── tindakan ────────────────────────────────────────────────

  void _next() {
    FocusScope.of(context).unfocus();
    final moved = _form.next();
    _toTop();
    if (!moved) {
      final s = ref.read(_provider);
      final first = s.visibleErrors(s.step).values.firstOrNull;
      if (first != null) {
        SemanticsService.announce(first, Directionality.of(context));
      }
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final s = ref.read(_provider);
    if (s.submitting) return;
    if (!_form.validateAll()) {
      _toTop();
      return;
    }

    final name = s.data.name.trim();
    final feedback = AppleFeedback.show(
      context,
      s.awaitingPhotos ? 'Mengunggah foto…' : 'Mengirim produk…',
    );
    final result = await _form.submit();

    switch (result) {
      case SubmitSucceeded():
        await feedback.success(
          s.isEdit ? 'Perubahan Tersimpan' : 'Produk Terkirim',
          s.isEdit
              ? '"$name" sudah diperbarui.'
              : '"$name" sudah tampil di toko Anda.',
        );
        if (mounted) context.pop();
      case SubmitInvalid():
        feedback.dismiss();
        _toTop();
      case SubmitFailed(:final error):
        await feedback.failure(
          s.isEdit ? 'Perubahan Belum Tersimpan' : 'Produk Belum Terkirim',
          '${networkErrorMessage(error)} Isian Anda tetap ada di layar ini.',
        );
      case SubmitPhotosPending(:final remaining, :final error):
        await feedback.failure(
          'Sebagian Foto Belum Terunggah',
          'Produk sudah tersimpan, tetapi $remaining foto belum masuk. '
              '${networkErrorMessage(error)} Tekan "Unggah Ulang Foto".',
        );
    }
  }

  Future<void> _saveDraft() async {
    FocusScope.of(context).unfocus();
    final ok = await _form.saveDraft();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            ok
                ? 'Draf tersimpan di ponsel ini. Buka "Tambah Produk" lagi '
                      'untuk melanjutkan.'
                : 'Draf belum tersimpan — ruang penyimpanan ponsel mungkin '
                      'penuh. Coba lagi.',
          ),
        ),
      );
  }

  /// Tombol kembali (header maupun sistem).
  Future<void> _back() async {
    final s = ref.read(_provider);
    if (s.submitting) return;
    if (_form.back()) {
      _toTop();
      return;
    }
    if (!s.isDirty || s.awaitingPhotos) {
      if (mounted) context.pop();
      return;
    }

    final choice = await showDialog<_LeaveChoice>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppleRadii.tile),
        ),
        title: Text(s.isEdit ? 'Buang perubahan?' : 'Simpan isian dulu?'),
        content: Text(
          s.isEdit
              ? 'Perubahan pada produk ini belum disimpan.'
              : 'Isian produk ini belum disimpan. Simpan sebagai draf untuk '
                    'dilanjutkan nanti?',
        ),
        actionsOverflowDirection: VerticalDirection.up,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _LeaveChoice.stay),
            child: Text(s.isEdit ? 'Lanjut Mengedit' : 'Lanjut Mengisi'),
          ),
          if (!s.isEdit)
            TextButton(
              onPressed: () => Navigator.pop(context, _LeaveChoice.draft),
              child: const Text('Simpan Draf'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, _LeaveChoice.leave),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
            child: Text(s.isEdit ? 'Buang Perubahan' : 'Keluar Tanpa Simpan'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _LeaveChoice.draft:
        if (await _form.saveDraft() && mounted) context.pop();
      case _LeaveChoice.leave:
        context.pop();
      case _LeaveChoice.stay || null:
        break;
    }
  }

  Future<void> _addPhotos() async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppleRadii.card),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              minTileHeight: 52,
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil dengan kamera'),
              onTap: () => Navigator.pop(context, PhotoSource.camera),
            ),
            ListTile(
              minTileHeight: 52,
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(context, PhotoSource.gallery),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final picked = await ref
          .read(productPhotoPickerProvider)
          .pick(source, max: _form.photoSlotsLeft);
      _form.addPhotos(picked.paths);
      if (picked.tooLarge > 0 && mounted) {
        _snack(
          '${picked.tooLarge} foto terlalu besar (lebih dari 4 MB) dan tidak '
          'ditambahkan. Pilih foto lain.',
        );
      }
    } on PlatformException {
      if (mounted) {
        _snack(
          source == PhotoSource.camera
              ? 'Kamera tidak bisa dibuka. Izinkan akses kamera di '
                    'Pengaturan, lalu coba lagi.'
              : 'Galeri tidak bisa dibuka. Izinkan akses foto di '
                    'Pengaturan, lalu coba lagi.',
        );
      }
    }
  }

  Future<void> _photoOptions(int i) async {
    final s = ref.read(_provider);
    final count = s.data.photos.length;
    final canEdit = _form.canEditPhoto(i);
    final canReorder = _form.canReorder && !s.submitting;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppleRadii.card),
        ),
      ),
      builder: (context) {
        Widget item(
          IconData icon,
          String label,
          VoidCallback onTap, {
          Color? color,
        }) => ListTile(
          minTileHeight: 52,
          leading: Icon(icon, color: color),
          title: Text(label, style: TextStyle(color: color)),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
        );

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  AppSpacing.base,
                  AppSpacing.base,
                  AppSpacing.xs,
                ),
                child: Text(
                  'Foto ${i + 1}${i == 0 ? ' · foto utama' : ''}',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (canReorder && i > 0)
                item(
                  Icons.star_outline_rounded,
                  'Jadikan foto utama',
                  () => _form.makePrimary(i),
                ),
              if (canReorder && i > 0)
                item(
                  Icons.arrow_back_rounded,
                  'Geser ke kiri',
                  () => _form.movePhoto(i, i - 1),
                ),
              if (canReorder && i < count - 1)
                item(
                  Icons.arrow_forward_rounded,
                  'Geser ke kanan',
                  () => _form.movePhoto(i, i + 1),
                ),
              if (canEdit && !s.submitting)
                item(
                  Icons.delete_outline_rounded,
                  'Hapus foto',
                  () => _form.removePhoto(i),
                  color: AppColors.errorText,
                ),
              if (!canEdit)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.base),
                  child: Text(
                    'Foto yang sudah tersimpan belum bisa dihapus atau '
                    'diurutkan dari aplikasi.',
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickCategory(List<ProductCategoryModel> all) async {
    final current = ref.read(_provider).data.categoryId;
    final picked = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppleRadii.card),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Text(
                'Pilih Kategori',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: all.length,
                itemBuilder: (_, i) {
                  final c = all[i];
                  final selected = c.id == current;
                  return ListTile(
                    minTileHeight: 52,
                    title: Text(
                      c.name,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primaryText,
                          )
                        : null,
                    selected: selected,
                    onTap: () => Navigator.pop(context, c.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) _form.setCategory(picked);
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
    );

  // ── tampilan ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(_provider);
    ref.listen(_provider, (prev, next) {
      // Produk selesai dimuat, atau draf dipulihkan.
      if (prev?.saved != next.saved && next.data == next.saved) {
        _sync(next.data);
      }
    });

    final header = SellerSubpageHeader(
      title: s.isEdit ? 'Edit Produk' : 'Tambah Produk',
      subtitle: s.isEdit
          ? 'Perbarui informasi etalase'
          : 'Siapkan produk untuk dijual di toko Anda',
      onBack: _back,
    );

    if (s.loading || s.loadError != null) {
      return Scaffold(
        backgroundColor: AppColors.surfaceSoft,
        body: Column(
          children: [
            header,
            Expanded(
              child: Center(
                child: s.loading
                    ? const AppleActivityIndicator(size: 28)
                    : Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              networkErrorMessage(s.loadError!),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.base),
                            FilledButton(
                              onPressed: _form.retryLoad,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    }

    final last = s.step == ProductFormNotifier.lastStep;
    final String primaryLabel;
    if (!last) {
      primaryLabel = 'Lanjut';
    } else if (s.awaitingPhotos) {
      primaryLabel = 'Unggah Ulang Foto';
    } else {
      primaryLabel = s.isEdit ? 'Simpan Perubahan' : 'Kirim Produk';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceSoft,
        // Tubuh menyusut saat keyboard muncul; bilah tindakan ada DI DALAM
        // tubuh, jadi ia ikut naik dan tidak pernah tertutup keyboard.
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            header,
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.translucent,
                child: ListView(
                  controller: _scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    AppSpacing.md,
                    AppSpacing.base,
                    AppSpacing.xl,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: productFormMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (s.offeredDraft != null) ...[
                              _DraftOffer(
                                savedAt: s.offeredDraft!.savedAt,
                                onRestore: _form.restoreDraft,
                                onDiscard: _form.discardDraft,
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            FormStepIndicator(
                              labels: _steps,
                              current: s.step,
                              onTap: (i) {
                                _form.goTo(i);
                                _toTop();
                              },
                            ),
                            const SizedBox(height: AppSpacing.base),
                            switch (s.step) {
                              0 => _detailStep(s),
                              1 => _priceStep(s),
                              _ => _reviewStep(s),
                            },
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FormActionBar(
              secondaryLabel: s.isEdit
                  ? null
                  : (s.awaitingPhotos ? 'Selesai' : 'Simpan draf'),
              onSecondary: s.awaitingPhotos ? () => context.pop() : _saveDraft,
              secondaryBusy: s.savingDraft,
              primaryLabel: primaryLabel,
              onPrimary: last ? _submit : _next,
              primaryBusy: s.submitting,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailStep(ProductFormState s) {
    final errors = s.visibleErrors(0);
    final categories = ref.watch(sellerCategoriesProvider);
    final selected = categories.valueOrNull
        ?.where((c) => c.id == s.data.categoryId)
        .firstOrNull;

    return FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormSectionTitle(
            'Foto produk',
            subtitle:
                'Tambahkan hingga ${ProductRules.maxPhotos} foto. Foto '
                'pertama jadi foto utama — ketuk foto untuk mengatur.',
          ),
          PhotoStrip(
            photos: s.data.photos,
            max: ProductRules.maxPhotos,
            onAdd: s.submitting ? null : _addPhotos,
            onPhotoTap: _photoOptions,
          ),
          const Divider(height: AppSpacing.xxl),
          const FormSectionTitle(
            'Informasi produk',
            subtitle:
                'Gunakan nama yang jelas dan informasi yang lengkap agar '
                'mudah ditemukan pembeli.',
          ),
          const FieldLabel('Nama produk', required: true),
          TextField(
            controller: _name,
            onChanged: _form.setName,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              LengthLimitingTextInputFormatter(ProductRules.nameMax),
            ],
            decoration: productInputDecoration(
              hint: 'Contoh: Kopi Arabika Gayo 250 g',
              error: errors['name'],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const FieldLabel('Kategori', required: true),
          CategoryField(
            selectedName: selected?.name,
            loading: categories.isLoading,
            failed: categories.hasError && !categories.hasValue,
            error: errors['category'],
            onTap: categories.hasValue
                ? () => _pickCategory(categories.value!)
                : null,
            onRetry: () => ref.invalidate(sellerCategoriesProvider),
          ),
          const SizedBox(height: AppSpacing.lg),
          const FieldLabel('Deskripsi produk'),
          TextField(
            controller: _description,
            onChanged: _form.setDescription,
            minLines: 4,
            maxLines: 8,
            maxLength: ProductRules.descriptionMax,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: productInputDecoration(
              hint:
                  'Ceritakan keunggulan produk, rasa, kemasan, atau detail '
                  'lainnya…',
              error: errors['description'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceStep(ProductFormState s) {
    final errors = s.visibleErrors(1);
    final threshold = ref
        .watch(sellerProductListProvider)
        .valueOrNull
        ?.lowStockThreshold;

    return FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormSectionTitle(
            'Harga & stok',
            subtitle: 'Harga yang dibayar pembeli dan jumlah barang siap jual.',
          ),
          const FieldLabel('Harga jual', required: true),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [ThousandsInputFormatter()],
            onChanged: (v) =>
                _form.setPrice(ThousandsInputFormatter.digitsOf(v)),
            decoration: productInputDecoration(
              hint: '0',
              error: errors['price'],
              prefix: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.base,
                  right: AppSpacing.sm,
                ),
                child: Text(
                  'Rp',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ).copyWith(prefixIconConstraints: const BoxConstraints()),
          ),
          const SizedBox(height: AppSpacing.lg),
          FieldLabel(s.stockLocked ? 'Stok' : 'Stok awal', required: true),
          if (s.stockLocked)
            _StockLockedNote(stock: s.data.stock, isEdit: s.isEdit)
          else
            TextField(
              controller: _stock,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
              onChanged: _form.setStock,
              decoration: productInputDecoration(
                hint: '0',
                error: errors['stock'],
              ),
            ),
          // Barang Kopdes punya batas menipisnya sendiri; UMKM memakai satu
          // batas untuk seluruh toko (keterangan di bawahnya).
          if (ref.watch(storeScopeProvider).isKopdes) ...[
            const SizedBox(height: AppSpacing.lg),
            const FieldLabel('Batas stok menipis'),
            TextField(
              controller: _minStock,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
              onChanged: _form.setMinStock,
              decoration: productInputDecoration(
                hint: '5',
                error: errors['minStock'],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Stok sama atau di bawah angka ini ditandai "Menipis". Kosong = 5.',
              style: AppTypography.captionSmall.copyWith(
                fontSize: 12.5,
                color: AppColors.muted,
              ),
            ),
          ] else if (threshold != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Stok $threshold atau kurang ditandai "Menipis" di daftar '
              'produk, dan 0 ditandai "Habis".',
              style: AppTypography.captionSmall.copyWith(
                fontSize: 12.5,
                color: AppColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reviewStep(ProductFormState s) {
    final d = s.data;
    final category = ref
        .watch(sellerCategoriesProvider)
        .valueOrNull
        ?.where((c) => c.id == d.categoryId)
        .firstOrNull;
    final threshold = ref
        .watch(sellerProductListProvider)
        .valueOrNull
        ?.lowStockThreshold;
    final stock = int.tryParse(d.stock) ?? 0;
    final level = threshold == null ? null : StockLevel.of(stock, threshold);

    Widget edit(int step) => TextButton(
      onPressed: s.submitting
          ? null
          : () {
              _form.goTo(step);
              _toTop();
            },
      style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
      child: const Text('Ubah'),
    );

    final primary = d.photos.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormSectionTitle('Detail produk', trailing: edit(0)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppleRadii.control),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: ColoredBox(
                        color: AppColors.surfaceSoft,
                        child: primary == null
                            ? const Icon(
                                Icons.image_outlined,
                                color: AppColors.mutedSoft,
                              )
                            : primary.isRemote
                            ? Image.network(primary.url!, fit: BoxFit.cover)
                            : Image.file(
                                File(primary.path!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.mutedSoft,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name.trim(),
                          style: AppTypography.bodyLarge.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          d.photos.isEmpty
                              ? 'Tanpa foto'
                              : '${d.photos.length} foto',
                          style: AppTypography.captionSmall.copyWith(
                            fontSize: 12.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ReviewRow('Kategori', category?.name ?? '—'),
              ReviewRow(
                'Deskripsi',
                d.description.trim().isEmpty
                    ? 'Tanpa deskripsi'
                    : d.description.trim(),
                muted: d.description.trim().isEmpty,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormSectionTitle('Harga & stok', trailing: edit(1)),
              ReviewRow('Harga jual', formatRupiah(int.tryParse(d.price) ?? 0)),
              ReviewRow(
                s.stockLocked ? 'Stok' : 'Stok awal',
                '${formatThousands(stock)}'
                '${level == null ? '' : ' · ${level.label}'}',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _InfoNote(
          icon: s.awaitingPhotos
              ? Icons.cloud_upload_outlined
              : Icons.storefront_outlined,
          text: s.awaitingPhotos
              ? 'Produk sudah tersimpan. Foto yang ditandai "Gagal" belum '
                    'masuk — tekan "Unggah Ulang Foto", atau "Selesai" untuk '
                    'menambahkannya nanti lewat Edit.'
              : s.isEdit
              ? 'Perubahan langsung tampil di marketplace setelah disimpan.'
              : 'Setelah dikirim, produk langsung tampil di marketplace desa '
                    'Anda. Admin Kopdes dapat menurunkannya bila melanggar '
                    'aturan.',
          warning: s.awaitingPhotos,
        ),
        if (s.awaitingPhotos) ...[
          const SizedBox(height: AppSpacing.md),
          PhotoStrip(
            photos: d.photos,
            max: d.photos.length,
            onAdd: null,
            onPhotoTap: _photoOptions,
          ),
        ],
      ],
    );
  }
}

enum _LeaveChoice { stay, draft, leave }

class _DraftOffer extends StatelessWidget {
  final DateTime savedAt;
  final VoidCallback onRestore;
  final VoidCallback onDiscard;

  const _DraftOffer({
    required this.savedAt,
    required this.onRestore,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final t = savedAt;
    final when =
        '${t.day}/${t.month} ${t.hour.toString().padLeft(2, '0')}.'
        '${t.minute.toString().padLeft(2, '0')}';
    return FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: AppColors.primaryText),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Ada draf produk yang tersimpan ($when).',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              FilledButton(
                onPressed: onRestore,
                style: FilledButton.styleFrom(minimumSize: const Size(44, 44)),
                child: const Text('Lanjutkan Draf'),
              ),
              TextButton(
                onPressed: onDiscard,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  foregroundColor: AppColors.errorText,
                ),
                child: const Text('Buang Draf'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockLockedNote extends StatelessWidget {
  final String stock;
  final bool isEdit;

  const _StockLockedNote({required this.stock, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppleRadii.control),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatThousands(int.tryParse(stock) ?? 0),
            style: AppTypography.titleMedium.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isEdit
                ? 'Ubah stok lewat "Atur stok" di daftar produk supaya '
                      'tercatat di riwayat.'
                : 'Stok awal sudah tersimpan bersama produk.',
            style: AppTypography.captionSmall.copyWith(
              fontSize: 12.5,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool warning;

  const _InfoNote({
    required this.icon,
    required this.text,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: warning ? AppColors.primaryTint : AppColors.canvas,
        borderRadius: BorderRadius.circular(AppleRadii.control),
        border: Border.all(
          color: warning ? AppColors.primarySoft : AppColors.hairlineSoft,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: warning ? AppColors.primaryText : AppColors.muted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13.5,
                color: AppColors.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
