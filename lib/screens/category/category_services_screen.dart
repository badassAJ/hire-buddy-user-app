import 'package:flutter/material.dart';
import 'package:hirebuddy/core/theme/app_colors.dart';
import 'package:hirebuddy/services/service_service.dart';
import 'package:hirebuddy/models/category_model.dart';
import 'package:hirebuddy/models/service_model.dart';
import 'package:hirebuddy/screens/service/service_detail_screen.dart';
import 'package:hirebuddy/core/utils/string_utils.dart';

class CategoryServicesScreen extends StatefulWidget {
  final String categoryName;
  final String? categoryId;

  const CategoryServicesScreen({
    super.key,
    required this.categoryName,
    this.categoryId,
  });

  @override
  State<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  final ServiceService _serviceService = ServiceService();
  List<CategoryModel> _subcategories = [];
  List<ServiceModel> _services = [];
  bool _isLoading = true;
  String? _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch all categories including subcategories
      final categoriesResult = await _serviceService.getCategories(
        includeSubcategories: true,
      );
      if (categoriesResult['success']) {
        final allCategories = (categoriesResult['data']['data'] as List)
            .map((json) => CategoryModel.fromJson(json))
            .toList();

        // Get subcategories for this main category
        _subcategories = allCategories
            .where(
              (cat) =>
                  cat.parentCategoryId == widget.categoryId && cat.isActive,
            )
            .toList();
        _subcategories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        debugPrint(
          'Found ${_subcategories.length} subcategories for ${widget.categoryName}',
        );
        for (var sub in _subcategories) {
          debugPrint('  - ${sub.categoryName} (${sub.id})');
        }
      }

      // Fetch services for this category
      await _loadServices();
    } catch (e) {
      debugPrint('Error loading category data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadServices() async {
    try {
      List<ServiceModel> allServices = [];

      if (_selectedSubcategoryId != null) {
        // Fetch services for selected subcategory only
        debugPrint(
          'Fetching services for subcategory: $_selectedSubcategoryId',
        );
        final servicesResult = await _serviceService.getServices(
          categoryId: _selectedSubcategoryId,
        );
        if (servicesResult['success']) {
          allServices = (servicesResult['data']['data'] as List)
              .map((json) => ServiceModel.fromJson(json))
              .where((service) => service.isActive)
              .toList();
          debugPrint('Found ${allServices.length} services for subcategory');
        }
      } else {
        // Fetch services for all subcategories under this main category
        if (_subcategories.isEmpty) {
          // No subcategories, try fetching with main category ID
          debugPrint(
            'No subcategories, fetching with main category: ${widget.categoryId}',
          );
          final servicesResult = await _serviceService.getServices(
            categoryId: widget.categoryId,
          );
          if (servicesResult['success']) {
            allServices = (servicesResult['data']['data'] as List)
                .map((json) => ServiceModel.fromJson(json))
                .where((service) => service.isActive)
                .toList();
            debugPrint(
              'Found ${allServices.length} services for main category',
            );
          }
        } else {
          // Fetch services from all subcategories
          debugPrint(
            'Fetching services from ${_subcategories.length} subcategories',
          );
          for (var subcategory in _subcategories) {
            debugPrint(
              '  Fetching from: ${subcategory.categoryName} (${subcategory.id})',
            );
            final servicesResult = await _serviceService.getServices(
              categoryId: subcategory.id,
            );
            if (servicesResult['success']) {
              final services = (servicesResult['data']['data'] as List)
                  .map((json) => ServiceModel.fromJson(json))
                  .where((service) => service.isActive)
                  .toList();
              debugPrint('    Found ${services.length} services');
              allServices.addAll(services);
            }
          }
          debugPrint('Total services found: ${allServices.length}');
        }
      }

      setState(() {
        _services = allServices;
      });
    } catch (e) {
      debugPrint('Error loading services: $e');
    }
  }

  void _onSubcategorySelected(String? subcategoryId) {
    setState(() {
      _selectedSubcategoryId = subcategoryId;
      _isLoading = true;
    });
    _loadServices().then((_) {
      setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _buildCustomAppBar(context, isDark),
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : Column(
              children: [
                // Subcategories filter chips
                if (_subcategories.isNotEmpty)
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _subcategories.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildFilterChip(
                            'All',
                            _selectedSubcategoryId == null,
                            () => _onSubcategorySelected(null),
                            isDark,
                          );
                        }
                        final subcategory = _subcategories[index - 1];
                        return _buildFilterChip(
                          subcategory.categoryName,
                          _selectedSubcategoryId == subcategory.id,
                          () => _onSubcategorySelected(subcategory.id),
                          isDark,
                        );
                      },
                    ),
                  ),

                // Services list
                Expanded(
                  child: _services.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: AppColors.grey400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No services found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.grey400,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            return _buildServiceCard(
                              context: context,
                              service: _services[index],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.grey800 : AppColors.grey100),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.grey200 : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.grey800 : Colors.white,
                shape: BoxShape.circle,
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Title
          Text(
            widget.categoryName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),

          // Cart Button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey800 : Colors.white,
              shape: BoxShape.circle,
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required ServiceModel service,
  }) {
    final imageUrl = service.primaryImageUrl;
    final price = service.pricing?.retailPrice ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(
              serviceId: service.id,
              heroTag: 'cat_${service.id}',
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 280,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Foreground curved image slice
            Positioned.fill(
              child: ClipPath(
                clipper: _ServiceCardClipper(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'cat_${service.id}',
                      child: imageUrl != null && imageUrl.startsWith('http')
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.grey200,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 64,
                                    color: AppColors.grey400,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppColors.grey200,
                              child: const Icon(
                                Icons.home_repair_service,
                                size: 64,
                                color: AppColors.grey400,
                              ),
                            ),
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.6],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top-Left Content
            Positioned(
              top: 24,
              left: 24,
              right: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (service.categoryId?.categoryName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        service.categoryId!.categoryName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    service.serviceName.toTitleCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Bottom-Left Content (Inside cutout)
            Positioned(
              bottom: 24,
              left: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Starting at',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow button (Inside cutout)
            Positioned(
              bottom: 24,
              left: 110,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.grey200),
                  color: AppColors.grey100,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: double.infinity,
          height: 280,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Shimmer effect
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _ShimmerWidget(),
                ),
              ),
              // Skeleton content
              Positioned(
                top: 24,
                left: 24,
                right: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 150,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 24,
                left: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerWidget extends StatefulWidget {
  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.grey100,
                AppColors.grey200.withValues(alpha: 0.5),
                AppColors.grey100,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    double cw = 175;
    double ch = 90;
    double curveRadius = 24;

    path.moveTo(curveRadius, 0);
    path.lineTo(size.width - curveRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, curveRadius);
    path.lineTo(size.width, size.height - curveRadius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - curveRadius,
      size.height,
    );

    path.lineTo(cw + curveRadius, size.height);
    path.quadraticBezierTo(cw, size.height, cw, size.height - curveRadius);
    path.lineTo(cw, size.height - ch + curveRadius);
    path.quadraticBezierTo(
      cw,
      size.height - ch,
      cw - curveRadius,
      size.height - ch,
    );

    path.lineTo(curveRadius, size.height - ch);
    path.quadraticBezierTo(
      0,
      size.height - ch,
      0,
      size.height - ch - curveRadius,
    );

    path.lineTo(0, curveRadius);
    path.quadraticBezierTo(0, 0, curveRadius, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
