import 'package:flutter/material.dart';
import 'package:hirebuddy/core/theme/app_colors.dart';
import 'package:hirebuddy/services/service_service.dart';
import 'package:hirebuddy/services/api_service.dart';
import 'package:hirebuddy/core/constants/api_constants.dart';
import 'package:hirebuddy/models/service_model.dart';
import 'package:hirebuddy/providers/auth_provider.dart';
import 'package:hirebuddy/screens/auth/login_screen.dart';
import 'package:hirebuddy/screens/booking/checkout_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/utils/string_utils.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;
  final String? heroTag;

  const ServiceDetailScreen({super.key, required this.serviceId, this.heroTag});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final ServiceService _serviceService = ServiceService();
  final ApiService _api = ApiService();
  ServiceModel? _service;
  bool _isLoading = true;
  List<ServiceModel> _similarServices = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _reviewsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }

  Future<void> _loadServiceDetails() async {
    setState(() => _isLoading = true);
    try {
      final result = await _serviceService.getServiceDetails(widget.serviceId);
      if (result['success'] && mounted) {
        final service = ServiceModel.fromJson(result['data']['data']);
        setState(() {
          _service = service;
          _isLoading = false;
        });
        _loadSimilarServices(service);
        _loadReviews();
      }
    } catch (e) {
      debugPrint('Error loading service details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _reviewsLoading = true);
    try {
      final res = await _api.get('${ApiConstants.serviceReviews}/${widget.serviceId}');
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true && mounted) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Reviews fetch error: $e');
    } finally {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  Future<void> _loadSimilarServices(ServiceModel service) async {
    final catId = service.categoryId?.id;
    if (catId == null) return;
    try {
      final result = await _serviceService.getServices(categoryId: catId);
      if (result['success'] && mounted) {
        final list = (result['data']['data'] as List)
            .map((e) => ServiceModel.fromJson(e))
            .where((s) => s.id != service.id)
            .take(10)
            .toList();
        setState(() => _similarServices = list);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service Not Found')),
        body: const Center(child: Text('Service details could not be loaded')),
      );
    }

    final imageUrl = _service!.primaryImageUrl ?? '';
    final price = _service!.pricing?.retailPrice ?? 0;
    final basePrice = _service!.pricing?.basePrice ?? price;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. HERO HEADER
              SliverPersistentHeader(
                pinned: true,
                delegate: _ServiceDetailHeaderDelegate(
                  minHeight: MediaQuery.of(context).padding.top + 60,
                  maxHeight: 350,
                  imagePath: imageUrl,
                  title: _service!.serviceName,
                  heroTag: widget.heroTag ?? _service!.id,
                  avgRating: _service!.avgRating,
                  totalRatings: _service!.totalRatings,
                ),
              ),

              // 2. CONTENT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Discount Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _service!.serviceName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _service!.description ??
                                      'Professional service',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Rating Badge
                          _buildRatingBadge(),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Base Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (basePrice > price)
                            Text(
                              '₹${basePrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.6,
                                ),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        'Service Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _service!.description ??
                            'Professional service with quality assurance.',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // SIMILAR SERVICES
                      if (_similarServices.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'You May Also Like',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (_service?.categoryId?.categoryName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _service!.categoryId!.categoryName,
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
                          height: 190,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _similarServices.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (_, i) => _SimilarServiceCard(service: _similarServices[i]),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // CUSTOMER REVIEWS
                      if (_reviewsLoading || _reviews.isNotEmpty) ...[
                        const Text(
                          'Customer Reviews',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_reviewsLoading)
                          const SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          SizedBox(
                            height: 160,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              clipBehavior: Clip.none,
                              itemCount: _reviews.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final r = _reviews[index];
                                final user = r['userId'] as Map<String, dynamic>?;
                                final profile = user?['profile'] as Map<String, dynamic>?;
                                final name = profile?['fullName'] as String? ?? 'User';
                                final rating = (r['ratings']?['overall'] ?? 0).toInt();
                                final text = r['reviewText'] as String? ?? '';
                                final date = r['createdAt'] != null
                                    ? DateFormat('d MMM yyyy').format(DateTime.parse(r['createdAt']))
                                    : '';
                                return _buildReviewCard(name, rating, text, date, context);
                              },
                            ),
                          ),
                      ],

                      // Extra space at bottom for the fixed action bar
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // BOTTOM ACTION BAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,              ),
              child: Row(
                children: [
                  // Price Tag Container
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.grey300),
                    ),
                    child: Text(
                      '₹${(_service?.pricing?.retailPrice ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Book Now Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_service != null) {
                          final auth = context.read<AuthProvider>();
                          if (!auth.isAuthenticated) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckoutScreen(
                                serviceId: _service!.id,
                                serviceName: _service!.serviceName,
                                price: _service!.pricing?.retailPrice ?? 0,
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge() {
    final rating = _service?.avgRating ?? 0;
    if (rating <= 0) return const SizedBox.shrink();

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    String name,
    int rating,
    String review,
    String date,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.5),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 13, color: Colors.amber,
                        )),
                        const SizedBox(width: 6),
                        if (date.isNotEmpty)
                          Text(date, style: const TextStyle(fontSize: 11, color: AppColors.grey500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// SIMILAR SERVICE CARD
// -------------------------------------------------------------------
class _SimilarServiceCard extends StatelessWidget {
  final ServiceModel service;
  const _SimilarServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final price = service.pricing?.retailPrice ?? 0;
    final imageUrl = service.primaryImageUrl ?? '';

    return GestureDetector(
      onTap: () => Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => ServiceDetailScreen(serviceId: service.id),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 280),
        ),
      ),
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),

            Container(height: 1, color: AppColors.grey100),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.serviceName.toTitleCase(),
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
                        '₹${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 1),
                        child: Text(
                          'onwards',
                          style: TextStyle(
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

  Widget _placeholder() => const Center(
    child: Icon(Icons.home_repair_service_rounded, color: AppColors.grey300, size: 32),
  );
}

// -------------------------------------------------------------------
// CUSTOM HEADER DELEGATE FOR THE TOP IMAGES
// -------------------------------------------------------------------
class _ServiceDetailHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final String imagePath;
  final String title;
  final String heroTag;
  final double avgRating;
  final int totalRatings;

  _ServiceDetailHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.imagePath,
    required this.title,
    required this.heroTag,
    this.avgRating = 0,
    this.totalRatings = 0,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // We adjust border radius as you scroll up
    double shrinkRatio = shrinkOffset / (maxExtent - minExtent);
    double radius = (40.0 * (1 - shrinkRatio)).clamp(0.0, 40.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryLight.withValues(alpha: 0.25),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Color / Image wrapper
          // Hero wrapper for the full image asset
          Hero(
            tag: heroTag,
            child: imagePath.startsWith('http')
                ? Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.grey200,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: AppColors.grey400,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.grey100,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  )
                : Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.grey200,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: AppColors.grey400,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // AppBar Controls (Back)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 20,
            child: _buildAppBarButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ServiceDetailHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        imagePath != oldDelegate.imagePath ||
        heroTag != oldDelegate.heroTag ||
        avgRating != oldDelegate.avgRating;
  }
}
