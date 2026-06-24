import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cart.dart';
import '../providers/cart_provider.dart';
import 'quantity_selector.dart';
import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/shared/widgets/product_image_loader.dart';

class CartItemTile extends ConsumerWidget {
  final CartItem item;
  final bool isSelected;
  final ValueChanged<bool> onSelectedChanged;

  const CartItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onSelectedChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isUmkm = item.umkmProductId != null;

    int stock = 0;
    if (item.product != null) {
      stock = item.product!.stock;
    } else if (item.umkmProduct != null) {
      final s = item.umkmProduct['stock'];
      if (s is num) {
        stock = s.toInt();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF3F4F6),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Custom Checkbox
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelectedChanged(!isSelected),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFD32F2F) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFD32F2F) : const Color(0xFFD1D5DB),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // 2. Rounded Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 80,
                height: 80,
                child: ProductImageLoader(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // 3. Info Details & Controls Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand/Type tag & Trash Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (isUmkm ? 'Produk UMKM' : 'Kopdes').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD32F2F),
                          letterSpacing: 1.1,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ref
                            .read(cartProvider.notifier)
                            .removeItem(
                              productId: item.productId,
                              umkmProductId: item.umkmProductId,
                            ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFD32F2F),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Product Title
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Stock Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Stok $stock tersedia',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price and Quantity Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Active Price
                      Text(
                        'Rp ${item.price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                        style: const TextStyle(
                          color: Color(0xFFD32F2F),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      // Compact Quantity Selector
                      QuantitySelector(
                        quantity: item.quantity,
                        onChanged: (val) {
                          ref
                              .read(cartProvider.notifier)
                              .updateQuantity(
                                productId: item.productId,
                                umkmProductId: item.umkmProductId,
                                quantity: val,
                              );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
