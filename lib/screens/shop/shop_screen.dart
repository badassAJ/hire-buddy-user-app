import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/product_service.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import '../auth/login_screen.dart';
import '../../core/utils/string_utils.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _productService = ProductService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocus = FocusNode();

  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  bool _isScrolled = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String _search = '';
  Timer? _debounce;

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts(reset: true);
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _productService.getProductCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    setState(() => _isSearching = value.isNotEmpty);
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _search = value;
      _loadProducts(reset: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    _search = '';
    setState(() => _isSearching = false);
    _loadProducts(reset: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoadingMore && _hasMore) _loadMore();
    }
    final scrolled = _scrollController.offset > 60;
    if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
        _products = [];
      });
    }
    try {
      final results = await _productService.listProducts(
        search: _search.isEmpty ? null : _search,
        page: _currentPage,
        categoryId: _selectedCategoryId,
      );
      if (!mounted) return;
      setState(() {
        _products = results;
        _isLoading = false;
        _hasMore = results.length >= 10;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final results = await _productService.listProducts(
        search: _search.isEmpty ? null : _search,
        page: _currentPage + 1,
        categoryId: _selectedCategoryId,
      );
      if (!mounted) return;
      setState(() {
        _currentPage++;
        _products.addAll(results);
        _isLoadingMore = false;
        _hasMore = results.length >= 10;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  String _titleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  Widget _buildShopCategoryGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 40 - 3 * 14) / 4;
    final cardH = itemWidth * 0.68;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ..._categories.take(3).map((cat) {
          final isSelected = _selectedCategoryId == cat['_id'];
          final iconUrl = cat['icon'] as String?;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategoryId = isSelected ? null : cat['_id'] as String);
              _loadProducts(reset: true);
            },
            child: SizedBox(
              width: itemWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: itemWidth,
                    height: cardH,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: iconUrl != null && iconUrl.startsWith('http')
                        ? Image.network(
                            iconUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, e, s) => const _CategoryFallbackIcon(),
                          )
                        : const _CategoryFallbackIcon(),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _titleCase(cat['categoryName'] as String),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : const Color(0xFF1A1A1A),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        // "All" tile — opens full category sheet
        GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _ShopAllCategoriesSheet(
              categories: _categories,
              selectedId: _selectedCategoryId,
              onSelect: (id) {
                setState(() => _selectedCategoryId = id);
                _loadProducts(reset: true);
              },
            ),
          ),
          child: SizedBox(
            width: itemWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: itemWidth,
                  height: cardH,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int r = 0; r < 3; r++) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int c = 0; c < 3; c++) ...[
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF888888),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (c < 2) const SizedBox(width: 4),
                              ],
                            ],
                          ),
                          if (r < 2) const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'All',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
        Column(
        children: [
          // ── HEADER ──────────────────────────────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  height: _isScrolled ? 0 : null,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Shop',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Fresh products, delivered fast',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.grey400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Cart button — always visible
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CartScreen()),
                            ),
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: cart.totalItems > 0
                                    ? AppColors.primary
                                    : AppColors.grey100,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    color: cart.totalItems > 0
                                        ? Colors.white
                                        : AppColors.grey500,
                                    size: 22,
                                  ),
                                  if (cart.totalItems > 0)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppColors.primary,
                                              width: 1.5),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (cart.totalItems > 0) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CartScreen()),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.grey100,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${cart.totalItems}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '₹${cart.totalAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_categories.isNotEmpty) ...[
                        _buildShopCategoryGrid(),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),

                // Search bar — always visible
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: const TextStyle(
                        color: AppColors.grey400, fontSize: 15),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.grey400, size: 22),
                    suffixIcon: _isSearching
                        ? GestureDetector(
                            onTap: _clearSearch,
                            child: const Icon(Icons.close_rounded,
                                color: AppColors.grey400, size: 20),
                          )
                        : null,
                    filled: false,
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── PRODUCT COUNT BAR ────────────────────────
          if (!_isLoading && _products.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _search.isEmpty
                        ? '${_products.length}${_hasMore ? '+' : ''} products available'
                        : '${_products.length} results for "$_search"',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),

          // ── GRID / LOADING / EMPTY ───────────────────
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _products.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: () => _loadProducts(reset: true),
                        color: AppColors.primary,
                        child: _buildGrid(),
                      ),
          ),
        ],
        ),

        // ── FLOATING CART PILL ────────────────────────
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              offset: cart.totalItems > 0
                  ? Offset.zero
                  : const Offset(0, 2.5),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: cart.totalItems > 0 ? 1.0 : 0.0,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(50),                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${cart.totalItems}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'View Cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 1,
                          height: 14,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '₹${cart.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  // ── 2-COLUMN GRID ─────────────────────────────────────
  Widget _buildGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: _products.length + (_isLoadingMore ? 2 : 0),
      itemBuilder: (_, i) {
        if (i >= _products.length) {
          return const _ShimmerCard();
        }
        return _ProductCard(product: _products[i]);
      },
    );
  }

  // ── SHIMMER ───────────────────────────────────────────
  Widget _buildShimmer() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: 4,
      itemBuilder: (_, _i) => const _ShimmerCard(),
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  size: 44, color: AppColors.grey400),
            ),
            const SizedBox(height: 20),
            Text(
              _search.isEmpty
                  ? 'No products yet'
                  : 'No results for "$_search"',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _search.isEmpty
                  ? 'Check back later for new products'
                  : 'Try a different keyword',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.grey400,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (_search.isNotEmpty) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _clearSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Clear Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── PRODUCT CARD ────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isAuth = context.read<AuthProvider>().isAuthenticated;
    final qty = cart.quantityOf(product.id);
    final isOutOfStock = product.stock == 0;

    void guardedAddToCart() {
      if (!isAuth) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        return;
      }
      final success = cart.addItem(product);
      if (!success) _showClearDialog(context, cart, product);
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => ProductDetailScreen(product: product),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── IMAGE ──────────────────────────────────
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Hero(
                    tag: 'product-img-${product.id}',
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: product.primaryImage.isNotEmpty
                          ? Image.network(
                              product.primaryImage,
                              fit: BoxFit.contain,
                              errorBuilder: (_, e, s) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                  ),
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                        ),
                        child: const Center(
                          child: Text(
                            'Out of\nStock',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!isOutOfStock &&
                      product.stock != null &&
                      product.stock! <= 5 &&
                      product.stock! > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Only ${product.stock} left',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── INFO ───────────────────────────────────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName.toTitleCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.unit,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.grey400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '₹${product.pricing.finalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (!isOutOfStock)
                          qty == 0
                              ? _AddBtn(onTap: guardedAddToCart)
                              : _QtyControl(
                                  qty: qty,
                                  onDec: () => cart.decreaseQuantity(product.id),
                                  onInc: guardedAddToCart,
                                ),
                      ],
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

  void _showClearDialog(
      BuildContext context, CartProvider cart, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Replace cart?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text(
          'Your cart has items from another vendor. Start a new cart with this item?',
          style: TextStyle(color: AppColors.grey600, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.grey500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              cart.clearCart();
              cart.addItem(product);
              Navigator.pop(ctx);
            },
            child: const Text('Replace',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => const Center(
        child: Icon(Icons.inventory_2_outlined, color: AppColors.grey300, size: 32),
      );
}

class _ShopAllCategoriesSheet extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String? selectedId;
  final void Function(String?) onSelect;

  const _ShopAllCategoriesSheet({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  String _titleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final itemWidth = (MediaQuery.of(context).size.width - 40 - 3 * 14) / 4;
    final cardH = itemWidth * 0.68;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.88,
      expand: false,
      builder: (context, scrollController) {
        final navBarHeight = MediaQuery.of(context).viewPadding.bottom;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -48,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 20, color: Colors.black87),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 32 + navBarHeight),
                      children: [
                        // "All Products" clear-filter row
                        GestureDetector(
                          onTap: () {
                            onSelect(null);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: selectedId == null
                                  ? AppColors.primary
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'All Products',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: selectedId == null ? Colors.white : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 14,
                          runSpacing: 16,
                          children: categories.map((cat) {
                            final iconUrl = cat['icon'] as String?;
                            final isSelected = selectedId == cat['_id'];
                            return GestureDetector(
                              onTap: () {
                                onSelect(cat['_id'] as String);
                                Navigator.pop(context);
                              },
                              child: SizedBox(
                                width: itemWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: itemWidth,
                                      height: cardH,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary.withValues(alpha: 0.12)
                                            : const Color(0xFFF0F0F0),
                                        borderRadius: BorderRadius.circular(16),
                                        border: isSelected
                                            ? Border.all(color: AppColors.primary, width: 1.5)
                                            : null,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: iconUrl != null && iconUrl.startsWith('http')
                                          ? Image.network(
                                              iconUrl,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, e, s) => const _CategoryFallbackIcon(),
                                            )
                                          : const _CategoryFallbackIcon(),
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      _titleCase(cat['categoryName'] as String),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? AppColors.primary : const Color(0xFF1A1A1A),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryFallbackIcon extends StatelessWidget {
  const _CategoryFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.category_outlined, color: Color(0xFF888888), size: 28),
    );
  }
}

class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onDec;
  final VoidCallback onInc;
  const _QtyControl(
      {required this.qty, required this.onDec, required this.onInc});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDec,
            child: const SizedBox(
              width: 24,
              height: 28,
              child: Icon(Icons.remove_rounded, color: Colors.white, size: 13),
            ),
          ),
          Text(
            '$qty',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          GestureDetector(
            onTap: onInc,
            child: const SizedBox(
              width: 24,
              height: 28,
              child: Icon(Icons.add_rounded, color: Colors.white, size: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── SHIMMER CARD ────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, child) => Container(
                width: double.infinity,
                decoration: _shimmerDecoration(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(double.infinity, 12),
                const SizedBox(height: 6),
                _shimmerBox(80, 10),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _shimmerBox(50, 16),
                    _shimmerBox(32, 32, radius: 10),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _shimmerDecoration() => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [AppColors.grey100, AppColors.grey200, AppColors.grey100],
          stops: [
            (_anim.value - 0.5).clamp(0.0, 1.0),
            _anim.value.clamp(0.0, 1.0),
            (_anim.value + 0.5).clamp(0.0, 1.0),
          ],
        ),
      );

  Widget _shimmerBox(double w, double h, {double radius = 6}) =>
      AnimatedBuilder(
        animation: _anim,
        builder: (_, child) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [AppColors.grey100, AppColors.grey200, AppColors.grey100],
              stops: [
                (_anim.value - 0.5).clamp(0.0, 1.0),
                _anim.value.clamp(0.0, 1.0),
                (_anim.value + 0.5).clamp(0.0, 1.0),
              ],
            ),
          ),
        ),
      );
}
