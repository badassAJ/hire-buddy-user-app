import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';

class ProductReviewSheet extends StatefulWidget {
  final ProductOrder order;
  final VoidCallback? onSubmitted;

  const ProductReviewSheet({super.key, required this.order, this.onSubmitted});

  @override
  State<ProductReviewSheet> createState() => _ProductReviewSheetState();
}

class _ProductReviewSheetState extends State<ProductReviewSheet> {
  final _service = ProductService();
  final Map<String, int> _ratings = {};
  final Map<String, TextEditingController> _controllers = {};
  Set<String> _alreadyReviewed = {};
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final item in widget.order.items) {
      _ratings[item.productId] = 0;
      _controllers[item.productId] = TextEditingController();
    }
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final ids = await _service.getReviewedProductIds(widget.order.id);
    if (mounted) setState(() { _alreadyReviewed = ids.toSet(); _loading = false; });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final toSubmit = widget.order.items
        .where((i) => !_alreadyReviewed.contains(i.productId) && (_ratings[i.productId] ?? 0) > 0)
        .map((i) => {
              'productId': i.productId,
              'rating': _ratings[i.productId],
              if (_controllers[i.productId]!.text.trim().isNotEmpty)
                'reviewText': _controllers[i.productId]!.text.trim(),
            })
        .toList();

    if (toSubmit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate at least one product')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _service.submitProductReviews(widget.order.id, toSubmit);
      if (mounted) {
        Navigator.pop(context);
        widget.onSubmitted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your review!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreviewed = widget.order.items
        .where((i) => !_alreadyReviewed.contains(i.productId))
        .toList();

    final navBarHeight = MediaQuery.of(context).viewPadding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Rate Your Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('How were the products?', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ),
          const SizedBox(height: 16),

          if (_loading)
            const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())
          else if (unreviewed.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
                  const SizedBox(height: 12),
                  Text('All products reviewed!', style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: unreviewed.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, i) {
                  final item = unreviewed[i];
                  final rating = _ratings[item.productId] ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 10),
                      // Star rating
                      Row(
                        children: List.generate(5, (star) {
                          final filled = star < rating;
                          return GestureDetector(
                            onTap: () => setState(() => _ratings[item.productId] = star + 1),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: filled ? const Color(0xFFFFC107) : Colors.grey[300],
                                size: 32,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _controllers[item.productId],
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Write a review (optional)',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF8F8F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          if (!_loading && unreviewed.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(context).viewPadding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
