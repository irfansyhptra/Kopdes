import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/error_message.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/apple_feedback.dart';
import '../../../shared/widgets/apple_ui.dart';
import '../../umkm/presentation/widgets/product_form_ui.dart';
import '../../umkm/presentation/widgets/seller_page_ui.dart';
import '../../umkm/presentation/widgets/store_form_page.dart';
import '../../umkm/presentation/widgets/store_page_ui.dart';
import '../data/address_repository.dart';

/// Rute buku alamat.
abstract final class AddressRoutes {
  static const list = '/profile/addresses';
  static const create = '/profile/addresses/new';
  static String edit(String id) => '/profile/addresses/edit/$id';
}

/// Validasi alamat — kolom wajib `CreateAddressDto`.
class AddressRules {
  static String? required(String v, String label) =>
      v.trim().isEmpty ? '$label wajib diisi.' : null;

  static String? phone(String v) {
    final t = v.replaceAll(RegExp(r'[\s-]'), '');
    if (t.isEmpty) return 'Nomor HP penerima wajib diisi.';
    if (!RegExp(r'^(\+62|62|0)8\d{7,12}$').hasMatch(t)) {
      return 'Gunakan nomor ponsel Indonesia, mis. 0812xxxxxxx.';
    }
    return null;
  }

  static String? postalCode(String v) =>
      RegExp(r'^\d{5}$').hasMatch(v.trim()) ? null : 'Kode pos 5 digit angka.';
}

// ─────────────────────────────────────────────────────────────
// Daftar alamat
// ─────────────────────────────────────────────────────────────

class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  Future<void> _remove(BuildContext context, WidgetRef ref, Address a) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus alamat?'),
        content: Text('"${a.title}" akan dihapus dari buku alamat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    await runWithFeedback(
      context,
      waiting: 'Menghapus alamat…',
      action: () async {
        await ref.read(addressRepositoryProvider).remove(a.id);
        ref.invalidate(addressesProvider);
        return true;
      },
      successTitle: 'Alamat Dihapus',
    );
  }

  Future<void> _makeDefault(
    BuildContext context,
    WidgetRef ref,
    Address a,
  ) async {
    await runWithFeedback(
      context,
      waiting: 'Menjadikan alamat utama…',
      action: () async {
        await ref.read(addressRepositoryProvider).makeDefault(a.id);
        ref.invalidate(addressesProvider);
        return true;
      },
      successTitle: 'Alamat Utama Diganti',
      successMessage: '"${a.title}" dipakai otomatis saat checkout.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: Column(
        children: [
          SellerSubpageHeader(
            title: 'Alamat Pengiriman',
            subtitle: 'Dipakai saat checkout',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(addressesProvider.future),
              child: async.when(
                loading: () => const StoreSubpageBody(
                  children: [SectionSkeleton(height: 120)],
                ),
                error: (e, _) => StoreSubpageBody(
                  children: [
                    SectionError(
                      message: networkErrorMessage(e),
                      onRetry: () => ref.invalidate(addressesProvider),
                    ),
                  ],
                ),
                data: (list) => StoreSubpageBody(
                  children: [
                    if (list.isEmpty)
                      const StoreSurface(
                        child: Text(
                          'Belum ada alamat. Tambahkan alamat agar bisa '
                          'memesan — termasuk untuk ambil sendiri, sebagai '
                          'kontak pesanan.',
                        ),
                      ),
                    for (final a in list) ...[
                      AddressCard(
                        address: a,
                        onEdit: () => context.push(AddressRoutes.edit(a.id)),
                        onDelete: () => _remove(context, ref, a),
                        onMakeDefault: a.isDefault
                            ? null
                            : () => _makeDefault(context, ref, a),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: () => context.push(AddressRoutes.create),
                      icon: const Icon(Icons.add_rounded),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      label: const Text('Tambah Alamat'),
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
}

class AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMakeDefault;

  /// Dipakai pemilih alamat di checkout.
  final bool selected;
  final VoidCallback? onSelect;

  const AddressCard({
    super.key,
    required this.address,
    this.onEdit,
    this.onDelete,
    this.onMakeDefault,
    this.selected = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final a = address;
    final body = StoreSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                a.title,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              if (a.isDefault)
                const StatusPill(
                  icon: Icons.home_rounded,
                  label: 'Utama',
                  tint: AppColors.primary,
                  text: AppColors.primaryText,
                ),
              if (selected)
                const StatusPill(
                  icon: Icons.check_circle_rounded,
                  label: 'Dipilih',
                  tint: AppColors.success,
                  text: AppColors.successText,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${a.recipientName} · ${a.phone}',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13.5,
              color: AppColors.body,
            ),
          ),
          Text(
            a.oneLine,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13.5,
              color: AppColors.muted,
            ),
          ),
          if (onEdit != null || onDelete != null || onMakeDefault != null)
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                if (onMakeDefault != null)
                  TextButton(
                    onPressed: onMakeDefault,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                    child: const Text('Jadikan Utama'),
                  ),
                if (onEdit != null)
                  TextButton(
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                    child: const Text('Ubah'),
                  ),
                if (onDelete != null)
                  TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      foregroundColor: AppColors.errorText,
                    ),
                    child: const Text('Hapus'),
                  ),
              ],
            ),
        ],
      ),
    );
    if (onSelect == null) return body;
    return ApplePressable(
      onTap: onSelect,
      semanticLabel:
          '${a.title}${selected ? ', dipilih' : ''}. ${a.recipientName}, ${a.oneLine}',
      child: body,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Form alamat
// ─────────────────────────────────────────────────────────────

/// Tambah ([addressId] null) atau ubah alamat. Bila dibuka dengan
/// `context.push<Address>`, alamat yang tersimpan dikembalikan — checkout
/// memakainya untuk langsung memilih alamat baru.
class AddressFormScreen extends ConsumerStatefulWidget {
  final String? addressId;
  const AddressFormScreen({super.key, this.addressId});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _title = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController(text: 'Aceh');
  final _postal = TextEditingController();
  bool _isDefault = false;
  bool _loaded = false;
  bool _saving = false;
  bool _touched = false;
  String _snapshot = '';

  List<TextEditingController> get _all => [
    _title,
    _name,
    _phone,
    _street,
    _city,
    _state,
    _postal,
  ];

  String get _current =>
      [..._all.map((c) => c.text.trim()), '$_isDefault'].join('|');

  @override
  void initState() {
    super.initState();
    if (widget.addressId == null) {
      _loaded = true;
      _snapshot = _current;
      return;
    }
    ref.listenManual(addressesProvider, (_, next) {
      final list = next.valueOrNull;
      if (_loaded || list == null) return;
      final a = list.where((x) => x.id == widget.addressId).firstOrNull;
      if (a == null) return;
      setState(() {
        _title.text = a.title;
        _name.text = a.recipientName;
        _phone.text = a.phone;
        _street.text = a.street;
        _city.text = a.city;
        _state.text = a.state;
        _postal.text = a.postalCode;
        _isDefault = a.isDefault;
        _loaded = true;
        _snapshot = _current;
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _errors => {
    'title': ?AddressRules.required(_title.text, 'Label alamat'),
    'name': ?AddressRules.required(_name.text, 'Nama penerima'),
    'phone': ?AddressRules.phone(_phone.text),
    'street': ?AddressRules.required(_street.text, 'Alamat lengkap'),
    'city': ?AddressRules.required(_city.text, 'Kota/kabupaten'),
    'state': ?AddressRules.required(_state.text, 'Provinsi'),
    'postal': ?AddressRules.postalCode(_postal.text),
  };

  Future<void> _save() async {
    setState(() => _touched = true);
    if (_errors.isNotEmpty || _saving) return;
    setState(() => _saving = true);
    final input = AddressInput(
      title: _title.text.trim(),
      recipientName: _name.text.trim(),
      phone: _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
      street: _street.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      postalCode: _postal.text.trim(),
      isDefault: _isDefault,
    );
    Address? saved;
    final ok = await runWithFeedback(
      context,
      waiting: 'Menyimpan alamat…',
      action: () async {
        final repo = ref.read(addressRepositoryProvider);
        saved = widget.addressId == null
            ? await repo.create(input)
            : await repo.update(widget.addressId!, input);
        ref.invalidate(addressesProvider);
        return true;
      },
      successTitle: 'Alamat Tersimpan',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final errors = _touched ? _errors : const <String, String>{};
    Widget field(
      TextEditingController c,
      String label,
      String key, {
      String? hint,
      TextInputType? type,
      List<TextInputFormatter>? formatters,
      int lines = 1,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(label, required: true),
          TextField(
            controller: c,
            keyboardType: type,
            inputFormatters: formatters,
            minLines: lines,
            maxLines: lines == 1 ? 1 : lines + 2,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: productInputDecoration(hint: hint, error: errors[key]),
          ),
        ],
      ),
    );

    return StoreFormPage(
      title: widget.addressId == null ? 'Tambah Alamat' : 'Ubah Alamat',
      subtitle: 'Alamat pengiriman pesanan',
      dirty: _loaded && _current != _snapshot,
      saving: _saving,
      onSave: _loaded && _current != _snapshot ? _save : null,
      children: [
        if (!_loaded)
          const SectionSkeleton(height: 480)
        else
          StoreSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                field(_title, 'Label alamat', 'title', hint: 'Rumah, Kantor'),
                field(_name, 'Nama penerima', 'name'),
                field(
                  _phone,
                  'Nomor HP penerima',
                  'phone',
                  hint: '0812xxxxxxxx',
                  type: TextInputType.phone,
                ),
                field(
                  _street,
                  'Alamat lengkap',
                  'street',
                  hint: 'Jalan, nomor rumah, gampong/desa, kecamatan',
                  lines: 2,
                ),
                field(_city, 'Kota/kabupaten', 'city', hint: 'Banda Aceh'),
                field(_state, 'Provinsi', 'state'),
                field(
                  _postal,
                  'Kode pos',
                  'postal',
                  type: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                ),
                SwitchListTile(
                  value: _isDefault,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _isDefault = v),
                  title: const Text('Jadikan alamat utama'),
                  subtitle: const Text('Dipilih otomatis saat checkout.'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
