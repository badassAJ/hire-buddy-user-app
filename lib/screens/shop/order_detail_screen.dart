import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/product_service.dart';
import '../../utils/invoice_generator.dart';
import '../booking/cancel_reason_sheet.dart';
import 'cart_screen.dart';
import 'product_review_sheet.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _productService = ProductService();
  ProductOrder? _order;
  bool _isLoading = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _productService.getOrderDetail(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showCancelDialog() async {
    final reason = await showCancelReasonSheet(context, isOrder: true);
    if (reason == null || !mounted) return;
    await _cancelOrder(reason);
  }

  Future<void> _cancelOrder(String reason) async {
    setState(() => _isCancelling = true);
    try {
      await _productService.cancelOrder(widget.orderId, reason);
      await _loadOrder();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order cancelled'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(
          _order != null ? '#${_order!.orderNumber}' : 'Order Details',
          style:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.grey100),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _order == null
              ? const Center(
                  child: Text('Failed to load order',
                      style: TextStyle(color: AppColors.grey500)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final order = _order!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          _StatusCard(order: order),
          const SizedBox(height: 16),

          // Progress tracker
          _OrderProgress(status: order.orderStatus),
          const SizedBox(height: 16),

          // Items
          _SectionCard(
            title: 'Items Ordered',
            child: Column(
              children: order.items.map((item) => _OrderItemTile(item: item)).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Price breakdown
          _SectionCard(
            title: 'Payment Details',
            child: Column(
              children: [
                _InfoRow('Subtotal',
                    '₹${order.pricing.subtotal.toStringAsFixed(0)}'),
                _InfoRow('Delivery', '₹${order.pricing.deliveryCharge.toStringAsFixed(0)}'),
                const Divider(color: AppColors.grey100),
                _InfoRow(
                  'Total',
                  '₹${order.pricing.totalAmount.toStringAsFixed(0)}',
                  bold: true,
                ),
                const SizedBox(height: 4),
                _InfoRow('Payment', order.paymentMethod.toUpperCase()),
                _InfoRow(
                  'Payment Status',
                  order.paymentStatus,
                  valueColor: order.paymentStatus == 'paid'
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Delivery address
          if (order.deliveryAddress != null)
            _SectionCard(
              title: 'Delivery Address',
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 18, color: AppColors.grey500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.deliveryAddress!.display,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Rate & Review button — shown only for delivered orders
          if (order.orderStatus == 'delivered')
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ProductReviewSheet(
                  order: order,
                  onSubmitted: _loadOrder,
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Rate & Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),

          if (order.orderStatus == 'delivered') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final bytes = await InvoiceGenerator.generateOrderReceipt(order);
                  await Printing.sharePdf(
                    bytes: bytes,
                    filename: 'receipt-${order.orderNumber}.pdf',
                  );
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not generate receipt')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Download Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: Colors.grey.shade300),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                context.read<CartProvider>().reorderItems(order.items, order.providerId);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
              },
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: const Text('Re-order', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Cancel button
          if (order.canCancel)
            GestureDetector(
              onTap: _isCancelling ? null : _showCancelDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.error),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _isCancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: AppColors.error, strokeWidth: 2),
                        )
                      : const Text(
                          'Cancel Order',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final ProductOrder order;

  const _StatusCard({required this.order});

  Color get _statusColor {
    switch (order.orderStatus) {
      case 'pending': return AppColors.warning;
      case 'confirmed': return AppColors.info;
      case 'preparing': return AppColors.info;
      case 'out_for_delivery': return AppColors.secondary;
      case 'delivered': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.grey500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_statusIcon, color: _statusColor, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.statusLabel,
                style: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                _statusMessage,
                style: const TextStyle(
                  color: AppColors.grey600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData get _statusIcon {
    switch (order.orderStatus) {
      case 'pending': return Icons.schedule_rounded;
      case 'confirmed': return Icons.check_circle_outline_rounded;
      case 'preparing': return Icons.kitchen_rounded;
      case 'out_for_delivery': return Icons.delivery_dining_rounded;
      case 'delivered': return Icons.done_all_rounded;
      case 'cancelled': return Icons.cancel_outlined;
      default: return Icons.info_outline;
    }
  }

  String get _statusMessage {
    switch (order.orderStatus) {
      case 'pending': return 'Waiting for vendor confirmation';
      case 'confirmed': return 'Your order has been confirmed';
      case 'preparing': return 'Vendor is preparing your order';
      case 'out_for_delivery': return 'Out for delivery';
      case 'delivered': return 'Successfully delivered';
      case 'cancelled': return 'This order was cancelled';
      default: return '';
    }
  }
}

class _OrderProgress extends StatelessWidget {
  final String status;

  const _OrderProgress({required this.status});

  static const _steps = [
    'Pending',
    'Confirmed',
    'Preparing',
    'Delivery',
    'Delivered',
  ];

  int get _activeStep {
    switch (status) {
      case 'pending': return 0;
      case 'confirmed': return 1;
      case 'preparing': return 2;
      case 'out_for_delivery': return 3;
      case 'delivered': return 4;
      default: return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIdx = i ~/ 2;
            final filled = stepIdx < _activeStep;
            return Expanded(
              child: Container(
                height: 2,
                color: filled ? AppColors.primary : AppColors.grey200,
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final active = stepIdx <= _activeStep;
          return Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.grey200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  active ? Icons.check_rounded : Icons.circle,
                  size: active ? 14 : 6,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _steps[stepIdx],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w400,
                  color:
                      active ? AppColors.primary : AppColors.grey400,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderItem item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: item.images.isNotEmpty
                  ? Image.network(
                      item.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.grey100),
                    )
                  : Container(color: AppColors.grey100,
                      child: const Icon(Icons.inventory_2_outlined,
                          color: AppColors.grey300, size: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '₹${item.pricePerUnit.toStringAsFixed(0)} × ${item.quantity}',
                  style: const TextStyle(
                    color: AppColors.grey500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${item.totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _InfoRow(this.label, this.value,
      {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: bold ? AppColors.textPrimary : AppColors.grey500,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              fontSize: bold ? 14 : 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ??
                  (bold ? AppColors.textPrimary : AppColors.textSecondary),
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              fontSize: bold ? 14 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
