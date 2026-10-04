import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../data/models/store_model.dart';
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

  static String? description(String v) =>
      v.trim().length > 300 ? 'Deskripsi maksimal 300 huruf.' : null;

  static String? address(String v) {
    final t = v.trim();
    if (t.isEmpty) return 'Alamat wajib diisi.';
    if (t.length < 5) return 'Tulis alamat yang lebih lengkap.';
    if (t.length > 200) return 'Alamat maksimal 200 huruf.';
    return null;
  }

  /// Ponsel Indonesia: 08…, 628…, atau +628…, 10–15 digit.
  static String? phone(String v) {
    final t = v.replaceAll(RegExp(r'[\s-]'), '');
    if (t.isEmpty) return 'Nomor telepon wajib diisi.';
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
        _category != o.category;
  }

  Map<String, String> get _errors => {
    'name': ?StoreProfileRules.name(_name.text),
    'description': ?StoreProfileRules.description(_description.text),
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
          category: _category,
        );
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
      subtitle: 'Informasi toko yang dilihat pembeli',
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
        else
          StoreSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FieldLabel('Nama usaha', required: true),
                TextField(
                  controller: _name,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [LengthLimitingTextInputFormatter(100)],
                  decoration: productInputDecoration(
                    hint: 'Contoh: Warung Nasi Mami Yose',
                    error: errors['name'],
                  ),
                ),
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
                const SizedBox(height: AppSpacing.lg),
                const FieldLabel('Tentang toko'),
                TextField(
                  controller: _description,
                  onChanged: (_) => setState(() {}),
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: productInputDecoration(
                    hint: 'Apa yang Anda jual dan apa keunggulannya?',
                    error: errors['description'],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const FieldLabel('Alamat toko', required: true),
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
    );
  }
}
