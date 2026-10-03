import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../data/review_repository.dart';

/// Lembar penulisan ulasan untuk produk pada satu pesanan.
///
/// Dibuka dari kartu pesanan selesai, dan hanya menampilkan produk yang
/// menurut server memang belum diulas pengguna ini.
Future<void> showReviewSheet(
  BuildContext context,
  String orderId,
  List<ReviewableItem> items,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _ReviewSheet(orderId: orderId, items: items),
  );
}

class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.orderId, required this.items});

  final String orderId;
  final List<ReviewableItem> items;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  late ReviewableItem _target = widget.items.first;
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.base,
        right: AppSpacing.base,
        top: AppSpacing.base,
        // Keyboard tidak boleh menutupi tombol kirim.
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.base,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Beri Ulasan',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Ulasanmu membantu warga lain memilih.',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.base),

            // Pemilih produk hanya muncul bila memang ada lebih dari satu
            // yang belum diulas.
            if (widget.items.length > 1) ...[
              Text('Produk', style: AppTypography.captionSmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final item in widget.items)
                    ChoiceChip(
                      label: Text(item.name),
                      selected: item.key == _target.key,
                      onSelected: (_) => setState(() => _target = item),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.base),
                child: Text(
                  _target.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            _StarPicker(
              rating: _rating,
              onChanged: (value) => setState(() {
                _rating = value;
                _error = null;
              }),
            ),
            const SizedBox(height: AppSpacing.base),

            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Ceritakan pengalamanmu (opsional)',
                border: OutlineInputBorder(),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                // Bintang wajib; komentar tidak. Rating nol bukan "nol
                // bintang", melainkan pengguna belum memilih.
                onPressed: _rating == 0 || _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(0, 48),
                ),
                child: Text(_submitting ? 'Mengirim…' : 'Kirim Ulasan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref
          .read(reviewRepositoryProvider)
          .submit(
            orderId: widget.orderId,
            productId: _target.productId,
            umkmProductId: _target.umkmProductId,
            rating: _rating,
            comment: _commentController.text,
          );
      // Daftar "boleh diulas" ikut berubah, jadi dibuang supaya tombolnya
      // hilang sendiri untuk produk yang baru diulas.
      ref.invalidate(reviewableItemsProvider(widget.orderId));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terima kasih, ulasanmu tersimpan')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = extractDioMessage(e, fallback: 'Ulasan gagal dikirim');
      });
    }
  }
}

/// Lima bintang yang bisa ditekan.
///
/// Setiap bintang adalah tombol tersendiri dengan label semantik, bukan satu
/// gambar yang dibaca dari posisi sentuhan — pembaca layar perlu tahu ia
/// sedang memilih "3 dari 5", dan target 44 dp tetap dipenuhi.
class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  static const _labels = [
    'Sangat kurang',
    'Kurang',
    'Cukup',
    'Bagus',
    'Sangat bagus',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 1; i <= 5; i++)
              Semantics(
                button: true,
                selected: rating == i,
                label: '$i bintang, ${_labels[i - 1]}',
                child: InkWell(
                  onTap: () => onChanged(i),
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Icon(
                        i <= rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 28,
                        color: i <= rating
                            ? const Color(0xFFF59E0B)
                            : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (rating > 0)
          Text(
            _labels[rating - 1],
            style: AppTypography.captionSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
