import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/network/paginated.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../admin/data/kopdes_console.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../koperasi/domain/koperasi.dart';
import '../../../koperasi/presentation/providers/koperasi_provider.dart';
import '../../data/models/store_model.dart';
import '../widgets/product_form_ui.dart';
import '../widgets/store_form_page.dart';
import '../widgets/store_page_ui.dart';
import 'store_edit_screen.dart';
import 'store_profile_screen.dart' show verificationPill;

/// Kopdes terdekat lebih dulu — Kopdes desa sendiri hampir pasti di atas.
final applyKopdesProvider = FutureProvider.autoDispose<Paginated<Koperasi>>((
  ref,
) {
  final loc = ref.watch(userCoordinatesProvider);
  return ref
      .watch(koperasiRepositoryProvider)
      .allKoperasi(latitude: loc?.latitude, longitude: loc?.longitude);
});

/// Daftar Mitra UMKM: pemilik usaha (akun Customer) mengajukan diri ke
/// Kopdes desanya, lalu menunggu pengurus memverifikasi.
class UmkmApplyScreen extends ConsumerWidget {
  const UmkmApplyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myUmkmApplicationProvider);
    return async.when(
      loading: () => const _Shell(children: [SectionSkeleton(height: 320)]),
      error: (e, _) => _Shell(
        children: [
          SectionError(
            message: networkErrorMessage(e),
            onRetry: () => ref.invalidate(myUmkmApplicationProvider),
          ),
        ],
      ),
      // Ditolak boleh mengajukan ulang; selain itu tampilkan statusnya.
      data: (app) => app == null || app.status == 'REJECTED'
          ? _ApplyForm(rejected: app)
          : _Shell(children: [_StatusCard(app: app)]),
    );
  }
}

class _Shell extends StatelessWidget {
  final List<Widget> children;
  const _Shell({required this.children});

  @override
  Widget build(BuildContext context) => StoreFormPage(
    title: 'Daftar Mitra UMKM',
    subtitle: 'Jual produk Anda lewat Kopdes desa',
    dirty: false,
    saving: false,
    onSave: null,
    children: children,
  );
}

class _StatusCard extends ConsumerWidget {
  final UmkmApplication app;
  const _StatusCard({required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kopdes = app.kopdesName ?? 'Kopdes';
    final (title, body) = switch (app.status) {
      'ACTIVE' => (
        'Pendaftaran disetujui',
        'Selamat! $kopdes telah memverifikasi usaha Anda. Masuk ulang '
            'untuk membuka halaman Toko dan mulai berjualan.',
      ),
      'SUSPENDED' => (
        'Toko ditangguhkan',
        'Hubungi pengurus $kopdes untuk mengetahui alasannya.',
      ),
      _ => (
        'Menunggu verifikasi',
        // Belum ada notifikasi dari server: notifikasi aplikasi hanya
        // mencatat kejadian di ponsel ini. Jangan menjanjikan kabar.
        'Pengurus $kopdes sedang memeriksa data usaha Anda. Buka halaman '
            'ini lagi untuk melihat keputusannya.',
      ),
    };
    return StoreSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          verificationPill(app.status),
          const SizedBox(height: AppSpacing.md),
          Text(
            app.businessName,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.body),
          ),
          if (app.status == 'ACTIVE') ...[
            const SizedBox(height: AppSpacing.lg),
            // Peran tersimpan di token; token baru dari masuk ulang memuat
            // peran UMKM.
            FilledButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Masuk Ulang sebagai Penjual'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ApplyForm extends ConsumerStatefulWidget {
  final UmkmApplication? rejected;
  const _ApplyForm({this.rejected});

  @override
  ConsumerState<_ApplyForm> createState() => _ApplyFormState();
}

class _ApplyFormState extends ConsumerState<_ApplyForm> {
  late final _name = TextEditingController(text: widget.rejected?.businessName);
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  String _category = 'KULINER';
  String? _kopdesId;
  bool _touched = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _description, _address, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _errors => {
    'name': ?StoreProfileRules.name(_name.text),
    'description': ?StoreProfileRules.description(_description.text),
    'address': ?StoreProfileRules.address(_address.text),
    'phone': ?StoreProfileRules.phone(_phone.text),
    if (_kopdesId == null) 'kopdes': 'Pilih Kopdes desa Anda.',
  };

  bool get _dirty =>
      _name.text.isNotEmpty ||
      _description.text.isNotEmpty ||
      _address.text.isNotEmpty;

  Future<void> _submit() async {
    setState(() => _touched = true);
    if (_errors.isNotEmpty || _saving) return;
    setState(() => _saving = true);
    final loc = ref.read(userCoordinatesProvider);
    final ok = await runWithFeedback(
      context,
      waiting: 'Mengirim pendaftaran…',
      action: () async {
        await ref.read(kopdesConsoleServiceProvider).applyUmkm({
          'businessName': _name.text.trim(),
          if (_description.text.trim().isNotEmpty)
            'description': _description.text.trim(),
          'address': _address.text.trim(),
          'phone': _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
          'category': _category,
          'kopdesId': _kopdesId,
          // Bukti sedesa untuk pengurus; tidak wajib bila izin lokasi ditolak.
          if (loc != null) ...{
            'latitude': loc.latitude,
            'longitude': loc.longitude,
          },
        });
        return true;
      },
      successTitle: 'Pendaftaran Terkirim',
      successMessage: 'Pengurus Kopdes akan memverifikasi data usaha Anda.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) ref.invalidate(myUmkmApplicationProvider);
  }

  @override
  Widget build(BuildContext context) {
    final errors = _touched ? _errors : const <String, String>{};
    final loc = ref.watch(userCoordinatesProvider);
    final kopdes = ref.watch(applyKopdesProvider);
    void changed(_) => setState(() {});

    return StoreFormPage(
      title: 'Daftar Mitra UMKM',
      subtitle: 'Jual produk Anda lewat Kopdes desa',
      dirty: _dirty,
      saving: _saving,
      saveLabel: 'Kirim Pendaftaran',
      onSave: _submit,
      children: [
        if (widget.rejected != null) ...[
          StoreSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                verificationPill('REJECTED'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Alasan: ${widget.rejected!.rejectionReason ?? 'tidak disebutkan'}. '
                  'Perbaiki datanya lalu kirim ulang.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.errorText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        const StoreSectionHeader(
          'Kopdes desa Anda',
          subtitle: 'UMKM hanya bisa bermitra dengan Kopdes di desanya.',
        ),
        kopdes.when(
          loading: () => const SectionSkeleton(height: 160),
          error: (e, _) => SectionError(
            message: networkErrorMessage(e),
            onRetry: () => ref.invalidate(applyKopdesProvider),
          ),
          data: (page) => StoreSurface(
            padding: EdgeInsets.zero,
            child: RadioGroup<String>(
              groupValue: _kopdesId,
              onChanged: (v) => setState(() => _kopdesId = v),
              child: Column(
                children: [
                  for (final k in page.items)
                    RadioListTile<String>(
                      value: k.id,
                      title: Text(
                        k.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          k.village,
                          k.district,
                        ].where((s) => s.isNotEmpty).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (errors['kopdes'] case final e?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              e,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.errorText,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        StoreSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FieldLabel('Nama usaha', required: true),
              TextField(
                controller: _name,
                onChanged: changed,
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
              const FieldLabel('Tentang usaha'),
              TextField(
                controller: _description,
                onChanged: changed,
                minLines: 2,
                maxLines: 5,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                decoration: productInputDecoration(
                  hint: 'Apa yang Anda jual?',
                  error: errors['description'],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const FieldLabel('Alamat usaha', required: true),
              TextField(
                controller: _address,
                onChanged: changed,
                minLines: 2,
                maxLines: 4,
                inputFormatters: [LengthLimitingTextInputFormatter(200)],
                textCapitalization: TextCapitalization.sentences,
                decoration: productInputDecoration(
                  hint: 'Jalan, dusun, desa',
                  error: errors['address'],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const FieldLabel('Nomor ponsel / WhatsApp', required: true),
              TextField(
                controller: _phone,
                onChanged: changed,
                keyboardType: TextInputType.phone,
                decoration: productInputDecoration(
                  hint: '0812xxxxxxxx',
                  error: errors['phone'],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    loc != null
                        ? Icons.my_location_rounded
                        : Icons.location_off_outlined,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      loc != null
                          ? 'Lokasi Anda saat ini ikut dikirim sebagai bukti '
                                'usaha berada di desa yang sama.'
                          : 'Lokasi belum aktif. Pengurus akan memastikan '
                                'alamat usaha Anda secara langsung.',
                      style: AppTypography.captionSmall.copyWith(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
