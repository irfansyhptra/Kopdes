import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/product_image_loader.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;
  final String? discountLabel;
  final bool isFavorite;
  final ValueChanged<bool>? onFavoriteToggle;
  final bool showActions;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onBuyNow,
    this.discountLabel,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.showActions = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompact = screenWidth < 360;

    // Determine deterministic simulated values for rating, sold count, and store label
    final double rating = 4.7 + (widget.product.id.hashCode % 4) * 0.1; // 4.7 to 5.0
    final int soldCount = 50 + (widget.product.id.hashCode % 900); // 50 to 950
    final String soldStr = soldCount > 500
        ? 'Terjual ${(soldCount / 100).toStringAsFixed(1)}rb'
        : 'Terjual $soldCount';
    final String reviewStr = '${soldCount + 23}';
    final String storeLabel = widget.product.stock % 2 == 0
        ? 'Kopdes Merah Putih'
        : 'UMKM Desa Lamteh';

    // Promo badge example
    final String badgeText = widget.discountLabel ?? 
        (widget.product.stock < 5 
            ? 'BEST SELLER' 
            : (widget.product.stock % 3 == 0 ? '-15%' : 'BARU'));

    // Crossed out original price (simulated 25% higher)
    final double crossedPrice = widget.product.price * 1.25;

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isPressed 
                  ? AppColors.primary.withValues(alpha: 0.15) 
                  : const Color(0xFFF0F0F0), 
              width: 1.2,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double cardWidth = constraints.maxWidth;
                final double cardHeight = constraints.maxHeight;

                // Detect layout conditions
                final bool isNarrow = cardWidth > 0 && cardWidth < 150;
                final bool isShort = cardHeight > 0 && cardHeight < 340;
                final bool isVeryShort = cardHeight > 0 && cardHeight < 290;

                // Outer padding inside details
                final double detailsPadding = isNarrow 
                    ? 8.0 
                    : (isShort ? 10.0 : 12.0);

                // Aspect ratio of the image:
                // Browse grid (showActions=false): use landscape 1.4 so image is shorter
                // Action cards (list/detail): use square or near-square
                double imageAspectRatio;
                if (!widget.showActions) {
                  // Landscape ratio — image height = cardWidth / 1.4 (much shorter)
                  imageAspectRatio = isNarrow ? 1.2 : 1.4;
                } else {
                  imageAspectRatio = isVeryShort ? 1.15 : (isShort ? 1.05 : 1.0);
                }

                // Estimated image height to calculate remaining detail space
                final double estImageHeight = cardWidth > 0 ? cardWidth / imageAspectRatio : 0;
                final double detailsAvailHeight = cardHeight - estImageHeight;

                // Visibility configurations — based on remaining detail space
                final bool showCategory = detailsAvailHeight > 90;
                final bool showStoreName = widget.showActions && detailsAvailHeight > 130;
                final bool showCrossedPrice = detailsAvailHeight > 80;
                final bool showActions = widget.showActions && cardHeight > 275;

                // Text sizing adjustments
                final double titleFontSize = isNarrow ? 11 : (isCompact ? 12 : 13);
                final int titleMaxLines = detailsAvailHeight > 110 ? 2 : 1;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Image Area with Aspect Ratio
                    AspectRatio(
                      aspectRatio: imageAspectRatio,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ProductImageLoader(
                              imageUrl: widget.product.primaryImageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Floating Promo Badge (Top Left)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: DiscountBadge(label: badgeText),
                          ),
                          // Floating Favorite Button (Top Right)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: FavoriteButton(
                              isFavorite: widget.isFavorite,
                              onToggle: widget.onFavoriteToggle,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Info Details Area
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(detailsPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Label
                            if (showCategory) ...[
                              Text(
                                (widget.product.category?.name ?? 'Koperasi').toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                            ],

                            // Product Title
                            Text(
                              widget.product.name,
                              style: TextStyle(
                                color: const Color(0xFF1A1A1A),
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                              maxLines: titleMaxLines,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),

                            // Store Name
                            if (showStoreName) ...[
                              Text(
                                storeLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                            ],

                            // Rating & Sold Count
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                               children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 13),
                                const SizedBox(width: 2),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '($reviewStr)',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '•',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 9,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  soldStr,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                             ),
                            ),
                            
                            const Spacer(),

                            // Price container & crossed out original price
                             Row(
                              children: [
                                Flexible(
                                  child: Text(
                                  'Rp ${widget.product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                                  style: const TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (showCrossedPrice) ...[
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Rp ${crossedPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                                      style: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 9,
                                        decoration: TextDecoration.lineThrough,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 4),
                                StockBadge(stock: widget.product.stock),
                              ],
                            ),

                            // Bottom Actions Row (only if height is enough and enabled)
                            if (widget.showActions && showActions) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  AddToCartButton(
                                    onTap: widget.onAddToCart ?? () {},
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: BuyNowButton(
                                      onTap: widget.onBuyNow ?? () {},
                                      label: isNarrow ? 'Beli' : 'Beli Sekarang',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Sub-Components
// ────────────────────────────────────────────────────────────────

class FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final ValueChanged<bool>? onToggle;

  const FavoriteButton({
    super.key,
    this.isFavorite = false,
    this.onToggle,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    _controller.forward(from: 0.0);
    if (widget.onToggle != null) {
      widget.onToggle!(_isFavorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: AppColors.primary,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class PriceCapsule extends StatefulWidget {
  final double price;

  const PriceCapsule({super.key, required this.price});

  @override
  State<PriceCapsule> createState() => _PriceCapsuleState();
}

class _PriceCapsuleState extends State<PriceCapsule>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceStr =
        'Rp ${widget.price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}';

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD32F2F), Color(0xFFE53935)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD32F2F).withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          priceStr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class DiscountBadge extends StatelessWidget {
  final String label;

  const DiscountBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class RatingWidget extends StatelessWidget {
  final double rating;
  final String reviewCount;

  const RatingWidget({
    super.key,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 13),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '($reviewCount)',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class StockBadge extends StatelessWidget {
  final int stock;

  const StockBadge({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final bool hasStock = stock > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: hasStock ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        hasStock ? 'Stok $stock' : 'Habis',
        style: TextStyle(
          color: hasStock ? const Color(0xFF2E7D32) : AppColors.primary,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AddToCartButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddToCartButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAEA), // Accent tint
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.primary.withValues(alpha: 0.15),
          highlightColor: Colors.transparent,
          child: const Icon(
            Icons.add_shopping_cart_rounded,
            color: AppColors.primary,
            size: 15,
          ),
        ),
      ),
    );
  }
}

class BuyNowButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const BuyNowButton({
    super.key,
    required this.onTap,
    this.label = 'Beli Sekarang',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9.5,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
