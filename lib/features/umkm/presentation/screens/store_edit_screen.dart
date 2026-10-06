import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../data/models/store_model.dart';
import '../../data/store_scope.dart';
import '../controllers/store_controller.dart';
import '../widgets/product_form_ui.dart';
import '../widgets/store_form_page.dart';
import '../widgets/store_page_ui.dart';

/// Batas profil toko — cerminan `UpdateSellerProfileDto` di backend.
class StoreProfileRules {
  static String? name(String v) {
    final t = v.trim();
    if (t.isEmpty) return 'Nama usaha wajib diisi.';
    if (t.length < 3) return 'Nama usaha minimal 3 huruf.';
    if (t.length > 100) return 'Nama usaha maksimal 100 huruf.';
    return null;
  }

  static String? description(String v, {int max = 300}) =>
      v.trim().length > max ? 'Deskripsi maksimal $max huruf.' : null;

  static String? address(String v) {
    final t = v.trim();
    if (t.isEmpty) return 'Alamat wajib diisi.';
    if (t.length < 5) return 'Tulis alamat yang lebih lengkap.';
    if (t.length > 200) return 'Alamat maksimal 200 huruf.';
    return null;
  }

  /// Ponsel Indonesia: 08…, 628…, atau +628…, 10–15 digit.
  ///
  /// Kopdes boleh memakai telepon kantor (`landline`), seperti
  /// `UpdateKopdesProfileDto`: 0 atau +62 lalu 7–13 digit.
  static String? phone(String v, {bool landline = false}) {
    final t = v.replaceAll(RegExp(r'[\s-]'), '');
    if (t.isEmpty) return 'Nomor telepon wajib diisi.';
    if (landline) {
      return RegExp(r'^(\+62|0)\d{7,13}$').hasMatch(t)
          ? null
          : 'Gunakan nomor telepon Indonesia, mis. 0651xxxxxx.';
    }
    if (!RegExp(r'^(\+62|62|0)8\d{7,12}$').hasMatch(t)) {
      return 'Gunakan nomor ponsel Indonesia, mis. 0812xxxxxxx.';
    }
    return null;
  }
}

/// Edit Profil: identitas yang dilihat pembeli.
class StoreEditScreen extends ConsumerStatefulWidget {
  const StoreEditScreen({super.key});

  @override
  ConsumerState<StoreEditScreen> createState() => _StoreEditScreenState();
}

class _StoreEditScreenState extends ConsumerState<StoreEditScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  String _category = 'LAINNYA';
  StoreModel? _original;
  bool _saving = false;
  bool _touched = false;
  Uint8List? _logoBytes;
  String? _logoName;
  Uint8List? _bannerBytes;
  String? _bannerName;

  bool get _kopdes => ref.read(storeScopeProvider).isKopdes;

  @override
  void initState() {
    super.initState();
    ref.listenManual(storeProfileProvider, (_, next) {
      final s = next.valueOrNull;
      if (s == null || _original != null) return;
      setState(() {
        _original = s;
        _name.text = s.businessName;
        _description.text = s.description;
        _address.text = s.address;
        _category = s.category;
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    super.dispose();
  }

  bool get _dirty {
    final o = _original;
    if (o == null) return false;
    return _name.text.trim() != o.businessName ||
        _description.text.trim() != o.description ||
        _address.text.trim() != o.address ||
        (!_kopdes && _category != o.category) ||
        _logoBytes != null ||
        _bannerBytes != null;
  }

  Future<void> _pickMedia({required bool banner}) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: banner ? 2200 : 1400,
      imageQuality: 88,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 4 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukuran gambar maksimal 4 MB.')),
      );
      return;
    }
    setState(() {
      if (banner) {
        _bannerBytes = bytes;
        _bannerName = file.name;
      } else {
        _logoBytes = bytes;
        _logoName = file.name;
      }
    });
  }

  Map<String, String> get _errors => {
    'name': ?StoreProfileRules.name(_name.text),
    'description': ?StoreProfileRules.description(
      _description.text,
      max: _kopdes ? 500 : 300,
    ),
    'address': ?StoreProfileRules.address(_address.text),
  };

  Future<void> _save() async {
    setState(() => _touched = true);
    if (_errors.isNotEmpty || _saving) return;
    setState(() => _saving = true);
    final ok = await runWithFeedback(
      context,
      waiting: 'Menyimpan profil…',
      action: () async {
        await saveStoreProfile(
          ref,
          businessName: _name.text.trim(),
          description: _description.text.trim(),
          address: _address.text.trim(),
          category: _kopdes ? null : _category,
        );
        if (_logoBytes != null || _bannerBytes != null) {
          await saveStoreMedia(
            ref,
            logoBytes: _logoBytes,
            logoName: _logoName,
            bannerBytes: _bannerBytes,
            bannerName: _bannerName,
          );
        }
        return true;
      },
      successTitle: 'Profil Tersimpan',
      successMessage: 'Perubahan langsung terlihat oleh pembeli.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(storeProfileProvider);
    final errors = _touched ? _errors : const <String, String>{};

    return StoreFormPage(
      title: 'Edit Profil',
      subtitle: _kopdes
          ? 'Informasi Kopdes yang dilihat warga'
          : 'Informasi toko yang dilihat pembeli',
      dirty: _dirty,
      saving: _saving,
      onSave: _original != null && _dirty ? _save : null,
      children: [
        if (_original == null)
          async.hasError
              ? SectionError(
                  message: networkErrorMessage(async.error!),
                  onRetry: () => ref.invalidate(storeProfileProvider),
                )
              : const SectionSkeleton(height: 420)
        else ...[
          StoreSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Identitas Visual',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 76,
                        height: 76,
                        child: _mediaImage(
                          _logoBytes,
                          _original!.photoUrl,
                          Icons.storefront_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.base),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _kopdes ? 'Logo Kopdes' : 'Logo atau foto toko',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'JPG, PNG, atau WebP · maksimal 4 MB',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => _pickMedia(banner: false),
                            child: const Text('Pilih Logo'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: AspectRatio(
                    aspectRatio: 16 / 6,
                    child: _mediaImage(
                      _bannerBytes,
                      _original!.bannerUrl,
                      Icons.image_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => _pickMedia(banner: true),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(
                    _kopdes ? 'Pilih Banner Kopdes' : 'Pilih Banner Toko',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          StoreSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FieldLabel(
                  _kopdes ? 'Nama Kopdes' : 'Nama usaha',
                  required: true,
                ),
                TextField(
                  controller: _name,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [LengthLimitingTextInputFormatter(100)],
                  decoration: productInputDecoration(
                    hint: _kopdes
                        ? 'Contoh: Kopdes Merah Putih Lamteh'
                        : 'Contoh: Warung Nasi Mami Yose',
                    error: errors['name'],
                  ),
                ),
                // Kopdes tidak punya kategori usaha.
                if (!_kopdes) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const FieldLabel('Kategori usaha', required: true),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final e in umkmCategories.entries)
                        ChoiceChip(
                          label: Text(e.value),
                          selected: _category == e.key,
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          onSelected: (_) => setState(() => _category = e.key),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FieldLabel(_kopdes ? 'Tentang Kopdes' : 'Tentang toko'),
                TextField(
                  controller: _description,
                  onChanged: (_) => setState(() {}),
                  minLines: 3,
                  maxLines: 6,
                  // Batas backend: 300 untuk UMKM, 500 untuk Kopdes.
                  maxLength: _kopdes ? 500 : 300,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: productInputDecoration(
                    hint: 'Apa yang Anda jual dan apa keunggulannya?',
                    error: errors['description'],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FieldLabel(
                  _kopdes ? 'Alamat Kopdes' : 'Alamat toko',
                  required: true,
                ),
                TextField(
                  controller: _address,
                  onChanged: (_) => setState(() {}),
                  minLines: 2,
                  maxLines: 4,
                  inputFormatters: [LengthLimitingTextInputFormatter(200)],
                  textCapitalization: TextCapitalization.sentences,
                  decoration: productInputDecoration(
                    hint: 'Jalan, gampong/desa, kecamatan',
                    error: errors['address'],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!_kopdes)
                  Text(
                    'Titik lokasi di peta diatur oleh Admin Kopdes.',
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _mediaImage(Uint8List? bytes, String? url, IconData fallback) {
    if (bytes != null) return Image.memory(bytes, fit: BoxFit.cover);
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _mediaFallback(fallback),
      );
    }
    return _mediaFallback(fallback);
  }

  Widget _mediaFallback(IconData icon) => ColoredBox(
    color: AppColors.primarySoft,
    child: Center(child: Icon(icon, color: AppColors.primary, size: 30)),
  );
}
