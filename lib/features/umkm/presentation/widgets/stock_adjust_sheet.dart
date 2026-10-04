import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../data/models/product_model.dart';
import '../../data/models/seller_product_page.dart';
import 'seller_product_list_ui.dart';

/// Isian yang sudah sah dari [StockAdjustSheet].
class StockAdjustment {
  /// Positif = masuk, negatif = keluar. Tidak pernah 0.
  final int delta;
  final String reason;

  const StockAdjustment(this.delta, this.reason);
}

/// Membuka isian "Atur stok": arah, jumlah, alasan.
///
/// Hanya mengumpulkan isian — penyimpanan dan modal hasilnya dijalankan
/// halaman pemanggil, yang konteksnya masih hidup setelah sheet tertutup.
Future<StockAdjustment?> showStockAdjustSheet(
  BuildContext context, {
  required ProductModel product,
  required int lowStockThreshold,
}) {
  return showModalBottomSheet<StockAdjustment>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppleRadii.card),
      ),
    ),
    builder: (_) => StockAdjustSheet(
      product: product,
      lowStockThreshold: lowStockThreshold,
    ),
  );
}

enum StockDirection { add, reduce }

/// Alasan siap pakai per arah. "Lainnya" membuka isian bebas.
const _reasons = {
  StockDirection.add: [
    'Restok dari pemasok',
    'Retur pembeli',
    'Koreksi hitung',
  ],
  StockDirection.reduce: [
    'Barang rusak',
    'Kedaluwarsa',
    'Terjual di luar aplikasi',
    'Koreksi hitung',
  ],
};
const _otherReason = 'Lainnya';

/// Batas atas satu penyesuaian: angka sebesar ini hampir pasti salah ketik.
const int maxStockStep = 99999;

/// Validasi jumlah — dipisah dari widget supaya bisa diuji langsung.
///
/// Mengembalikan pesan galat, atau null bila sah.
String? validateStockStep({
  required String raw,
  required StockDirection direction,
  required int currentStock,
}) {
  final text = raw.trim();
  if (text.isEmpty) return 'Isi jumlahnya dulu.';
  final qty = int.tryParse(text);
  if (qty == null) return 'Jumlah harus angka bulat.';
  if (qty < 1) return 'Jumlah minimal 1.';
  if (qty > maxStockStep) return 'Jumlah maksimal $maxStockStep sekali atur.';
  if (direction == StockDirection.reduce && qty > currentStock) {
    return currentStock == 0
        ? 'Stok sudah habis — tidak ada yang bisa dikurangi.'
        : 'Stok hanya $currentStock — tidak bisa dikurangi $qty.';
  }
  return null;
}

class StockAdjustSheet extends StatefulWidget {
  final ProductModel product;
  final int lowStockThreshold;

  const StockAdjustSheet({
    super.key,
    required this.product,
    required this.lowStockThreshold,
  });

  @override
  State<StockAdjustSheet> createState() => _StockAdjustSheetState();
}

class _StockAdjustSheetState extends State<StockAdjustSheet> {
  final _qty = TextEditingController(text: '1');
  final _otherText = TextEditingController();
  StockDirection _direction = StockDirection.add;
  String? _reason;
  bool _touched = false;

  @override
  void dispose() {
    _qty.dispose();
    _otherText.dispose();
    super.dispose();
  }

  String? get _qtyError => validateStockStep(
    raw: _qty.text,
    direction: _direction,
    currentStock: widget.product.stock,
  );

  String? get _finalReason {
    if (_reason == null) return null;
    if (_reason != _otherReason) return _reason;
    final t = _otherText.text.trim();
    return t.isEmpty ? null : t;
  }

  bool get _valid => _qtyError == null && _finalReason != null;

  int get _delta {
    final q = int.tryParse(_qty.text.trim()) ?? 0;
    return _direction == StockDirection.add ? q : -q;
  }

  void _step(int by) {
    final q = (int.tryParse(_qty.text.trim()) ?? 0) + by;
    setState(() {
      _touched = true;
      _qty.text = q.clamp(1, maxStockStep).toString();
    });
  }

  void _save() {
    setState(() => _touched = true);
    if (!_valid) return;
    Navigator.of(context).pop(StockAdjustment(_delta, _finalReason!));
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.product.stock;
    final qtyError = _touched ? _qtyError : null;
    final preview = _qtyError == null ? current + _delta : null;
    final previewLevel = preview == null
        ? null
        : StockLevel.of(preview, widget.lowStockThreshold);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.sm,
          AppSpacing.base,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Atur Stok',
              style: AppTypography.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.product.name} · stok sekarang ${formatThousands(current)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13.5,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.base),

            SegmentedButton<StockDirection>(
              segments: const [
                ButtonSegment(
                  value: StockDirection.add,
                  icon: Icon(Icons.add_rounded),
                  label: Text('Tambah'),
                ),
                ButtonSegment(
                  value: StockDirection.reduce,
                  icon: Icon(Icons.remove_rounded),
                  label: Text('Kurangi'),
                ),
              ],
              selected: {_direction},
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(44, 44),
                selectedBackgroundColor: AppColors.primaryTint,
                selectedForegroundColor: AppColors.primaryText,
              ),
              onSelectionChanged: (s) => setState(() {
                _direction = s.first;
                // Alasan milik arah lain tidak berlaku lagi.
                if (_reason != _otherReason &&
                    !_reasons[_direction]!.contains(_reason)) {
                  _reason = null;
                }
              }),
            ),
            const SizedBox(height: AppSpacing.base),

            _Label('Jumlah'),
            Row(
              children: [
                _StepButton(
                  icon: Icons.remove_rounded,
                  label: 'Kurangi jumlah',
                  onTap: () => _step(-1),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _qty,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    onChanged: (_) => setState(() => _touched = true),
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      errorText: qtyError,
                      errorMaxLines: 2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppleRadii.control),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StepButton(
                  icon: Icons.add_rounded,
                  label: 'Tambah jumlah',
                  onTap: () => _step(1),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),

            _Label('Alasan perubahan'),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final r in [..._reasons[_direction]!, _otherReason])
                  ChoiceChip(
                    label: Text(r),
                    selected: _reason == r,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onSelected: (_) => setState(() => _reason = r),
                  ),
              ],
            ),
            if (_reason == _otherReason) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _otherText,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tulis alasannya',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppleRadii.control),
                  ),
                ),
              ),
            ],
            if (_touched && _finalReason == null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Pilih alasannya — tercatat di riwayat stok.',
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 12.5,
                    color: AppColors.errorText,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.base),

            if (preview != null)
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppleRadii.control),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 14,
                        color: AppColors.body,
                      ),
                      children: [
                        TextSpan(text: 'Stok ${formatThousands(current)} → '),
                        TextSpan(
                          text: formatThousands(preview),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        TextSpan(
                          text: ' · ${previewLevel!.label}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: previewLevel.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.base),

            FilledButton(
              onPressed: _valid ? _save : () => setState(() => _touched = true),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: _valid
                    ? AppColors.primary
                    : AppColors.surfaceStrong,
                foregroundColor: _valid ? AppColors.onPrimary : AppColors.muted,
              ),
              child: const Text('Simpan Perubahan Stok'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      text,
      style: AppTypography.bodyMedium.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    ),
  );
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: label,
    onPressed: onTap,
    style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    icon: Icon(icon),
  );
}
