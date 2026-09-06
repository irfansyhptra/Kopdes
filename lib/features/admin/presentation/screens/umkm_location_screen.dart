import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../data/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_ui.dart';

/// Form Admin Kopdes untuk mengisi koordinat Mitra UMKM.
///
/// UMKM tanpa koordinat tidak pernah muncul di pencarian terdekat — data
/// lokasinya memang belum pernah diminta saat pendaftaran. Layar ini yang
/// melengkapinya.
class UmkmLocationScreen extends ConsumerWidget {
  const UmkmLocationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mitraListProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: AppBar(title: const Text('Lokasi Mitra UMKM')),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => Center(
          child: OutlinedButton(
            onPressed: () => ref.invalidate(mitraListProvider),
            child: const Text('Coba Lagi'),
          ),
        ),
        data: (mitras) {
          if (mitras.isEmpty) {
            return const Center(child: Text('Belum ada Mitra UMKM.'));
          }
          final belumDiisi = mitras.where((m) => !m.hasCoordinates).length;

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.base),
            itemCount: mitras.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _Banner(count: belumDiisi, total: mitras.length);
              }
              return _MitraLocationTile(mitra: mitras[index - 1]);
            },
          );
        },
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final int count;
  final int total;

  const _Banner({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final done = count == 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFE8F5E9) : AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppleRadii.card),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_outline : Icons.info_outline,
            size: 18,
            color: done ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              done
                  ? 'Semua $total mitra sudah punya koordinat.'
                  : '$count dari $total mitra belum punya koordinat dan tidak '
                        'muncul di pencarian terdekat.',
              style: AppTypography.bodyMedium.copyWith(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _MitraLocationTile extends ConsumerStatefulWidget {
  final Mitra mitra;

  const _MitraLocationTile({required this.mitra});

  @override
  ConsumerState<_MitraLocationTile> createState() => _MitraLocationTileState();
}

class _MitraLocationTileState extends ConsumerState<_MitraLocationTile> {
  late final TextEditingController _lat = TextEditingController(
    text: widget.mitra.latitude?.toString() ?? '',
  );
  late final TextEditingController _lng = TextEditingController(
    text: widget.mitra.longitude?.toString() ?? '',
  );
  late String _category = widget.mitra.category;
  bool _saving = false;

  static const _categories = [
    'KULINER',
    'SWALAYAN',
    'MINUMAN',
    'KERAJINAN',
    'JASA',
    'LAINNYA',
  ];

  @override
  void dispose() {
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());

    // Divalidasi juga di server; di sini supaya pesannya langsung terlihat.
    if (lat == null || lng == null) {
      _toast('Latitude dan longitude harus berupa angka.', error: true);
      return;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      _toast('Koordinat di luar rentang yang sah.', error: true);
      return;
    }

    setState(() => _saving = true);
    final ok = await ref
        .read(adminActionProvider.notifier)
        .updateUmkmLocation(
          widget.mitra.id,
          latitude: lat,
          longitude: lng,
          category: _category,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    _toast(ok ? 'Lokasi tersimpan.' : 'Gagal menyimpan lokasi.', error: !ok);
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      accentColor: widget.mitra.hasCoordinates
          ? AppColors.success
          : AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.mitra.businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!widget.mitra.hasCoordinates)
                const AppleBadge(label: 'Belum ada lokasi'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _numberField(_lat, 'Latitude')),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _numberField(_lng, 'Longitude')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Kategori usaha'),
            items: [
              for (final c in _categories)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Menyimpan...' : 'Simpan Lokasi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
      decoration: InputDecoration(labelText: label),
    );
  }
}
