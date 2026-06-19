import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import 'order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  final _productService = ProductService();
  late TabController _tabController;
  bool _isLoading = true;
  List<ProductOrder> _allOrders = [];

  final _tabs = ['All', 'Pending', 'Confirmed', 'Preparing', 'Delivered', 'Cancelled'];
  final _statusMap = {
    'All': null,
    'Pending': 'pending',
    'Confirmed': 'confirmed',
    'Preparing': 'preparing',
    'Delivered': 'delivered',
    'Cancelled': 'cancelled',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _productService.getMyOrders();
      if (!mounted) return;
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<ProductOrder> _filteredOrders(String tab) {
    final status = _statusMap[tab];
    if (status == null) return _allOrders;
    return _allOrders.where((o) => o.orderStatus == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('My Orders',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          dividerColor: AppColors.grey100,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final orders = _filteredOrders(tab);
                if (orders.isEmpty) return _buildEmpty(tab);
                return RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (_, i) => _OrderCard(
                      order: orders[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                OrderDetailScreen(orderId: orders[i].id),
                          ),
                        );
                        _loadOrders();
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildEmpty(String tab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 64, color: AppColors.grey300),
          const SizedBox(height: 16),
          Text(
            tab == 'All'
                ? 'No orders yet'
                : 'No ${tab.toLowerCase()} orders',
            style: const TextStyle(
              color: AppColors.grey500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final ProductOrder order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  Color get _statusColor {
    switch (order.orderStatus) {
      case 'pending': return const Color(0xFFF59E0B);
      case 'confirmed': return const Color(0xFF3B82F6);
      case 'preparing': return const Color(0xFF8B5CF6);
      case 'out_for_delivery': return const Color(0xFF06B6D4);
      case 'delivered': return const Color(0xFF10B981);
      case 'cancelled': return const Color(0xFFEF4444);
      default: return AppColors.grey500;
    }
  }

  IconData get _statusIcon {
    switch (order.orderStatus) {
      case 'pending': return Icons.schedule_rounded;
      case 'confirmed': return Icons.check_circle_outline_rounded;
      case 'preparing': return Icons.soup_kitchen_rounded;
      case 'out_for_delivery': return Icons.delivery_dining_rounded;
      case 'delivered': return Icons.done_all_rounded;
      case 'cancelled': return Icons.cancel_outlined;
      default: return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstImage = order.items.isNotEmpty && order.items.first.images.isNotEmpty
        ? order.items.first.images.first
        : null;
    final itemCount = order.items.length;
    final extraCount = itemCount - 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Column(
          children: [
            // Top row — image + info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: firstImage != null
                          ? Image.network(firstImage, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imagePlaceholder())
                          : _imagePlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.orderNumber,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grey500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              _formatDate(order.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          order.items.first.productName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (extraCount > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '+$extraCount more item${extraCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom row — status + amount
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon, size: 12, color: _statusColor),
                        const SizedBox(width: 5),
                        Text(
                          order.statusLabel,
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${order.pricing.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: AppColors.grey400),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.grey100,
      child: const Icon(Icons.shopping_bag_outlined, color: AppColors.grey400, size: 28),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
