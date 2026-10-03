import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../features/umkm/data/models/inventory_model.dart';
import '../widgets/apple_ui.dart';

class InventoryCard extends StatefulWidget {
  final InventoryModel inventory;
  final Function(int newStock)? onUpdateStock;

  const InventoryCard({super.key, required this.inventory, this.onUpdateStock});

  @override
  State<InventoryCard> createState() => _InventoryCardState();
}

class _InventoryCardState extends State<InventoryCard> {
  late int _localStock;
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _localStock = widget.inventory.stock;
    _controller = TextEditingController(text: _localStock.toString());
  }

  @override
  void didUpdateWidget(covariant InventoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inventory.stock != widget.inventory.stock && !_isEditing) {
      setState(() {
        _localStock = widget.inventory.stock;
        _controller.text = _localStock.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _increment() {
    setState(() {
      _localStock++;
      _controller.text = _localStock.toString();
    });
  }

  void _decrement() {
    if (_localStock > 0) {
      setState(() {
        _localStock--;
        _controller.text = _localStock.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLowStock = _localStock <= 5;

    return AppleCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.inventory.categoryName,
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.inventory.productName,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                constraints: const BoxConstraints(minHeight: 28),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isLowStock
                      ? AppColors.error.withValues(alpha: 0.08)
                      : AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: (isLowStock ? AppColors.error : AppColors.success)
                        .withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLowStock
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 13,
                      color: isLowStock ? AppColors.error : AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _localStock == 0
                          ? 'Habis'
                          : (isLowStock ? 'Stok tipis' : 'Stok aman'),
                      style: AppTypography.badge.copyWith(
                        color: isLowStock
                            ? AppColors.errorText
                            : AppColors.success,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Text('Stok saat ini', style: AppTypography.captionSmall),
          const SizedBox(height: 2),
          Text(
            '$_localStock Pcs',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: isLowStock ? AppColors.errorText : AppColors.ink,
            ),
          ),
          if (!_isEditing) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 17,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Perbarui stok',
                  style: AppTypography.buttonSm.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTint,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
          ],
          if (_isEditing) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _StockIconButton(
                  icon: Icons.remove_rounded,
                  label: 'Kurangi stok',
                  onTap: _localStock > 0 ? _decrement : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: AppColors.surfaceSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed >= 0) {
                          setState(() => _localStock = parsed);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StockIconButton(
                  icon: Icons.add_rounded,
                  label: 'Tambah stok',
                  onTap: _increment,
                ),
                const SizedBox(width: AppSpacing.sm),
                ApplePressable(
                  onTap: () {
                    setState(() => _isEditing = false);
                    widget.onUpdateStock?.call(_localStock);
                  },
                  semanticLabel: 'Simpan jumlah stok',
                  pressedScale: 0.92,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: AppElevation.accent,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StockIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _StockIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      semanticLabel: label,
      pressedScale: 0.92,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.hairlineSoft : AppColors.canvas,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Icon(
          icon,
          color: onTap == null ? AppColors.mutedSoft : AppColors.primary,
        ),
      ),
    );
  }
}
