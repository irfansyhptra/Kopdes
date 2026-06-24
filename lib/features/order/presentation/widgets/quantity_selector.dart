import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
// Premium Minimalist Quantity Selector
// Kopdes Merah Putih — Apple-quality UI Component
// ─────────────────────────────────────────────────────────

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;

  const QuantitySelector({
    super.key,
    required this.quantity,
    this.maxQuantity = 999,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool canDecrease = quantity > 1;
    final bool canIncrease = quantity < maxQuantity;

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6), // soft background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canDecrease ? () => onChanged(quantity - 1) : null,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: Icon(
                Icons.remove_rounded,
                size: 14,
                color: canDecrease ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
              ),
            ),
          ),
          
          // Quantity display with micro-animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: SizedBox(
              key: ValueKey<int>(quantity),
              width: 20,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ),

          // Increase button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canIncrease ? () => onChanged(quantity + 1) : null,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: Icon(
                Icons.add_rounded,
                size: 14,
                color: canIncrease ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
