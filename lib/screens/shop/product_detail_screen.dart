import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/product_service.dart';
import 'cart_screen.dart';
import '../auth/login_screen.dart';
import '../../core/utils/string_utils.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  final _pageController = PageController();
  final _productService = ProductService();

  List<ProductModel> _similarProducts = [];

  @override
  void initState() {
    super.initState();
    _loadSimilarProducts();
  }

  Future<void> _loadSimilarProducts() async {
    final catId = widget.product.categoryId;
    if (catId == null) return;
    try {
      final results = await _productService.listProducts(categoryId: catId, page: 1);
      if (!mounted) return;
      setState(() {
        _similarProducts = results.where((p) => p.id != widget.product.id).take(10).toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleAddToCart(CartProvider cart) {
    if (!context.read<AuthProvider>().isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    final success = cart.addItem(widget.product);
    if (!success) {
      _showClearCartDialog(cart);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Added to cart'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showClearCartDialog(CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Replace cart?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Your cart has items from a different vendor. Add this product to start a new cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              cart.clearCart();
              cart.addItem(widget.product);
              Navigator.pop(ctx);
            },
            child: const Text('Replace', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cart = context.watch<CartProvider>();
    final qty = cart.quantityOf(product.id);
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final screenH = MediaQuery.of(context).size.height;
    final imageH = screenH * 0.45;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── SCROLLABLE CONTENT ──────────────────────────────────────
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HERO IMAGE AREA ─────────────────────────────────
                  SizedBox(
                    height: imageH,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Hero image / page view
                        if (product.images.isEmpty)
                          Hero(
                            tag: 'product-img-${product.id}',
                            child: Container(
                              color: AppColors.grey100,
                              child: const Center(
                                child: Icon(Icons.inventory_2_outlined,
                                    size: 64, color: AppColors.grey300),
                              ),
                            ),
                          )
                        else
                          PageView.builder(
                            controller: _pageController,
                            itemCount: product.images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentImageIndex = i),
                            itemBuilder: (_, i) => i == 0
                                ? Hero(
                                    tag: 'product-img-${product.id}',
                                    child: Image.network(
                                      product.images[0],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, e, s) => Container(
                                        color: AppColors.grey100,
                                        child: const Icon(
                                            Icons.inventory_2_outlined,
                                            color: AppColors.grey300,
                                            size: 64),
                                      ),
                                    ),
                                  )
                                : Image.network(
                                    product.images[i],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, e, s) => Container(
                                      color: AppColors.grey100,
                                      child: const Icon(
                                          Icons.inventory_2_outlined,
                                          color: AppColors.grey300,
                                          size: 64),
                                    ),
                                  ),
                          ),

                        // Gradient overlay — top fade for status bar
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 120,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Out of stock overlay
                        if (product.stock == 0)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.35),
                              child: const Center(
                                child: Text(
                                  'Out of Stock',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Dot indicators
                        if (product.images.length > 1)
                          Positioned(
                            bottom: 24,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                product.images.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: i == _currentImageIndex ? 20 : 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: i == _currentImageIndex
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── CONTENT SHEET ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name
                        Text(
                          product.productName.toTitleCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            height: 1.15,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Price row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${product.pricing.finalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '/${product.unit}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.grey400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (product.pricing.basePrice > product.pricing.finalPrice) ...[
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹${product.pricing.basePrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColors.grey400,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${(((product.pricing.basePrice - product.pricing.finalPrice) / product.pricing.basePrice) * 100).toStringAsFixed(0)}% off',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Stock badge
                        if (product.stock != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: product.stock! > 5
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : product.stock! > 0
                                      ? AppColors.warning.withValues(alpha: 0.1)
                                      : AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: product.stock! > 5
                                        ? AppColors.success
                                        : product.stock! > 0
                                            ? AppColors.warning
                                            : AppColors.error,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  product.stock! > 5
                                      ? 'In Stock'
                                      : product.stock! > 0
                                          ? 'Only ${product.stock} left'
                                          : 'Out of Stock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: product.stock! > 5
                                        ? AppColors.success
                                        : product.stock! > 0
                                            ? AppColors.warning
                                            : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),
                        const Divider(height: 1, color: AppColors.grey100),
                        const SizedBox(height: 20),

                        // Description
                        if (product.description != null &&
                            product.description!.isNotEmpty) ...[
                          const Text(
                            'About this product',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            product.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.65,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(height: 1, color: AppColors.grey100),
                          const SizedBox(height: 20),
                        ],

                        // Similar products
                        if (_similarProducts.isNotEmpty) ...[
                          const Divider(height: 1, color: AppColors.grey100),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'You May Also Like',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (widget.product.categoryName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.product.categoryName!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 220,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(right: 4),
                              itemCount: _similarProducts.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (_, i) => _SimilarProductCard(product: _similarProducts[i]),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // Reviews
                        _ReviewsSection(productId: widget.product.id),

                        // Extra bottom padding so content isn't hidden behind action bar
                        SizedBox(height: bottomPad + 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── FLOATING TOP BUTTONS ────────────────────────────────────
            Positioned(
              top: topPad + 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FloatBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  if (cart.totalItems > 0)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _FloatBtn(
                            icon: Icons.shopping_bag_outlined,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CartScreen()),
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  '${cart.totalItems}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── BOTTOM ACTION BAR ──────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    20, 12, 20, bottomPad > 0 ? bottomPad : 16),
                decoration: BoxDecoration(
                  color: Colors.white,                ),
                child: product.stock == 0
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: AppColors.grey500,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    : qty == 0
                        ? Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  label: 'Add to Cart',
                                  icon: Icons.shopping_bag_outlined,
                                  outlined: true,
                                  onTap: () => _handleAddToCart(cart),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ActionButton(
                                  label: 'Buy Now',
                                  icon: Icons.flash_on_rounded,
                                  outlined: false,
                                  onTap: () {
                                    _handleAddToCart(cart);
                                    if (cart.quantityOf(product.id) > 0 ||
                                        cart.items.any(
                                            (i) => i.product.id == product.id)) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const CartScreen()),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.grey200),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    _QtyButton(
                                      icon: Icons.remove_rounded,
                                      onTap: () =>
                                          cart.decreaseQuantity(product.id),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Center(
                                        child: Text(
                                          '$qty',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                    _QtyButton(
                                      icon: Icons.add_rounded,
                                      onTap: () => _handleAddToCart(cart),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ActionButton(
                                  label: 'Go to Cart',
                                  icon: Icons.shopping_bag_outlined,
                                  outlined: false,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const CartScreen()),
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.outlined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: outlined ? Colors.white : AppColors.primary,
          border: outlined ? Border.all(color: AppColors.grey200) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: outlined ? AppColors.textPrimary : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: outlined ? AppColors.textPrimary : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 46,
        height: 52,
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

// ─────────────────────────── SIMILAR PRODUCT CARD ────────────────────────────

class _SimilarProductCard extends StatelessWidget {
  final ProductModel product;
  const _SimilarProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stock == 0;

    return GestureDetector(
      onTap: () => Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => ProductDetailScreen(product: product),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 280),
        ),
      ),
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area — separate grey bg, contained image
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.primaryImage.isNotEmpty
                      ? Image.network(
                          product.primaryImage,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.38),
                        child: const Center(
                          child: Text(
                            'Out of\nStock',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, height: 1.3),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Divider line between image and info
            Container(height: 1, color: AppColors.grey100),

            // Info — white bg, clearly separated
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${product.pricing.finalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: Text(
                          '/${product.unit}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey400,
                          ),
                        ),
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

  Widget _placeholder() => Container(
    color: AppColors.grey100,
    child: const Center(child: Icon(Icons.inventory_2_outlined, color: AppColors.grey300, size: 32)),
  );
}

// ─────────────────────────── REVIEWS SECTION ─────────────────────────────────

class _ReviewsSection extends StatefulWidget {
  final String productId;
  const _ReviewsSection({required this.productId});

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  final _service = ProductService();
  List<dynamic> _reviews = [];
  Map<String, dynamic> _meta = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _service.getProductReviews(widget.productId);
      if (mounted) setState(() { _reviews = result['reviews'] as List; _meta = result['meta'] as Map<String, dynamic>; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avgRating = (_meta['avgRating'] as num?)?.toDouble() ?? 0.0;
    final total = (_meta['total'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: AppColors.grey100),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Reviews', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.2)),
            Text('$total reviews', style: const TextStyle(fontSize: 12, color: AppColors.grey400, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 14),

        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (total == 0)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.grey100)),
            child: const Center(child: Text('No reviews yet. Be the first to review!', style: TextStyle(fontSize: 13, color: AppColors.grey400))),
          )
        else ...[
          // Rating summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.grey100)),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1)),
                    const SizedBox(height: 6),
                    _StarRow(rating: avgRating.round()),
                    const SizedBox(height: 4),
                    const Text('out of 5', style: TextStyle(fontSize: 11, color: AppColors.grey400)),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      for (int s = 5; s >= 1; s--)
                        _RatingBar(stars: s, reviews: _reviews, total: total),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          for (final review in _reviews) ...[
            _ReviewCard(review: review as Map<String, dynamic>),
            const SizedBox(height: 10),
          ],
        ],

        const SizedBox(height: 4),
      ],
    );
  }
}

class _RatingBar extends StatelessWidget {
  final int stars;
  final List<dynamic> reviews;
  final int total;
  const _RatingBar({required this.stars, required this.reviews, required this.total});

  @override
  Widget build(BuildContext context) {
    final count = reviews.where((r) => (r['rating'] as num).round() == stars).length;
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars', style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 10, color: Color(0xFFFFA726)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: AppColors.grey200,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFFA726)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 14,
          color: const Color(0xFFFFA726),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final user = review['userId'] as Map<String, dynamic>?;
    final name = user?['name'] as String? ?? 'User';
    final rating = (review['rating'] as num).round();
    final comment = review['reviewText'] as String?;
    final avatar = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final date = review['createdAt'] != null
        ? DateTime.tryParse(review['createdAt'].toString())
        : null;
    final dateStr = date != null
        ? '${date.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][date.month - 1]} ${date.year}'
        : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(avatar, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    _StarRow(rating: rating),
                  ],
                ),
              ),
              Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(comment, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          ],
        ],
      ),
    );
  }
}
