import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../features/umkm/data/models/inventory_model.dart';

class InventoryCard extends StatefulWidget {
  final InventoryModel inventory;
  final Function(int newStock)? onUpdateStock;

  const InventoryCard({
    super.key,
    required this.inventory,
    this.onUpdateStock,
  });

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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppElevation.card,
      ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isLowStock
                      ? AppColors.error.withOpacity(0.08)
                      : AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  _localStock == 0
                      ? 'Habis'
                      : (isLowStock ? 'Stok Tipis' : 'Stok Aman'),
                  style: AppTypography.badge.copyWith(
                    color: isLowStock ? AppColors.error : AppColors.success,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stok Saat Ini:',
                    style: AppTypography.captionSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_localStock Pcs',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isLowStock ? AppColors.errorText : AppColors.ink,
                    ),
                  ),
                ],
              ),
              if (!_isEditing)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                  label: Text(
                    'Update Cepat',
                    style: AppTypography.buttonSm.copyWith(color: AppColors.primary),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySoft.withOpacity(0.3),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: AppColors.primary,
                      onPressed: _decrement,
                    ),
                    SizedBox(
                      width: 48,
                      height: 36,
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: AppColors.surfaceSoft,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed >= 0) {
                            setState(() {
                              _localStock = parsed;
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: AppColors.primary,
                      onPressed: _increment,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      icon: const Icon(Icons.check_circle_rounded),
                      color: AppColors.success,
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                        });
                        if (widget.onUpdateStock != null) {
                          widget.onUpdateStock!(_localStock);
                        }
                      },
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
