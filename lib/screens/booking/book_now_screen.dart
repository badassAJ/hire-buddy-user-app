import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/buddy_model.dart';
import '../../models/product_model.dart' show AddressModel;
import '../../services/address_service.dart';
import '../../services/booking_service.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';
import '../../services/razorpay_service.dart';
import '../booking/finding_provider_screen.dart';
import '../booking/saved_address_picker_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIGURATION DESIGN SYSTEM COLOUR ALIASES
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const primary = Color(0xFF1A1A1A);
  static const accent = Color(0xFF5C35D5);
  static const grey900 = Color(0xFF1A1A1A);
  static const grey600 = Color(0xFF6B6B6B);
  static const grey400 = Color(0xFF9E9E9E);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey100 = Color(0xFFF7F7F7);
  static const blueBg = Color(0xFFF0EDFB);
  static const blueTag = Color(0xFF5C35D5);
  static const blueTagBg = Color(0xFFF3EFFF);
  static const blueTagBd = Color(0xFFDFD5FF);
  static const green = Color(0xFF2E7D32);
  static const greenBg = Color(0xFFE8F5E9);
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA TRANSPORT STRUTS
// ─────────────────────────────────────────────────────────────────────────────
class ComboItem {
  final CategoryModel category;
  int hours;

  ComboItem({required this.category, this.hours = 1});

  double get subtotal => (category.hourlyRate ?? 0.0) * hours;
}

String _fmt(double price) => '₹${price.toStringAsFixed(0)}';

// ═════════════════════════════════════════════════════════════════════════════
// WIDGET ENTRY POINT (SECTION 5.3.1: ON-THE-SPOT FLOW)
// ═════════════════════════════════════════════════════════════════════════════
class BookNowScreen extends StatelessWidget {
  const BookNowScreen({super.key});

  @override
  Widget build(BuildContext context) => const _CategoryStep();
}

// ═════════════════════════════════════════════════════════════════════════════
// NAVIGATIONAL STEPPERS FRAMEWORK
// ═════════════════════════════════════════════════════════════════════════════
class _StepHeader extends StatelessWidget {
  final String title;
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;

  const _StepHeader({
    required this.title,
    required this.currentStep,
    required this.totalSteps,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack ?? () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _C.grey300, width: 1.5),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: _C.grey900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _C.grey900,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Row(
            children: List.generate(totalSteps, (i) {
              final active = i + 1 == currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(left: 6),
                width: active ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? _C.accent : _C.grey300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final String? priceLabel;

  const _BottomCta({
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.priceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled ? _C.primary : const Color(0xFFE8E8E8),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE8E8E8),
            disabledForegroundColor: _C.grey400,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (priceLabel != null) ...[
                Text(
                  priceLabel!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1.5, height: 16, color: Colors.white30),
                const SizedBox(width: 12),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRD STEP 15 — SELECT CATEGORY & COMBO ADD-ONS (HYBRID ENGINE)
// ═════════════════════════════════════════════════════════════════════════════
class _CategoryStep extends StatefulWidget {
  const _CategoryStep();

  @override
  State<_CategoryStep> createState() => _CategoryStepState();
}

class _CategoryStepState extends State<_CategoryStep> {
  final ApiService _api = ApiService();
  List<CategoryModel> _serverCategories = [];
  final Set<String> _selectedIds = {};
  bool _fetching = true;

  @override
  void initState() {
    super.initState();
    _fetchActiveCategories();
  }

  Future<void> _fetchActiveCategories() async {
    try {
      final res = await _api
          .get('/api/v1/user/categories/active')
          .timeout(const Duration(seconds: 3));
      if (res.data['success'] == true) {
        final list = res.data['data'] as List;
        if (mounted) {
          setState(() {
            _serverCategories = list
                .map((e) => CategoryModel.fromJson(e))
                .toList();
            _fetching = false;
          });
          return;
        }
      }
    } catch (_) {}

    // 🌟 CMS FALLBACK SEED LAYER
    if (mounted) {
      setState(() {
        _serverCategories = [
          CategoryModel(
            id: 'hospital-accompaniment',
            categoryName: 'Hospital Accompaniment',
            categorySlug: 'hospital-accompaniment',
            description: 'Patient care assistance',
            icon:
                'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=150&q=80',
            displayOrder: 1,
            isActive: true,
            parentCategoryId: null,
            hourlyRate: 149,
          ),
          CategoryModel(
            id: 'fitness-accountability',
            categoryName: 'Fitness Accountability',
            categorySlug: 'fitness-accountability',
            description: 'Workout motivation support',
            icon:
                'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=150&q=80',
            displayOrder: 2,
            isActive: true,
            parentCategoryId: null,
            hourlyRate: 249,
          ),
          CategoryModel(
            id: 'home-cleaning',
            categoryName: 'Home Cleaning Assistance',
            categorySlug: 'home-cleaning',
            description: 'Express house tidying help',
            icon:
                'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=150&q=80',
            displayOrder: 3,
            isActive: true,
            parentCategoryId: null,
            hourlyRate: 199,
          ),
        ];
        _fetching = false;
      });
    }
  }

  void _toggleSelection(String id) => setState(
    () => _selectedIds.contains(id)
        ? _selectedIds.remove(id)
        : _selectedIds.add(id),
  );

  @override
  Widget build(BuildContext context) {
    final List<ComboItem> itemsToPass = _serverCategories
        .where((c) => _selectedIds.contains(c.id))
        .map((c) => ComboItem(category: c))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _StepHeader(
            title: 'On-the-Spot Booking',
            currentStep: 1,
            totalSteps: 4,
          ),
          Expanded(
            child: _fetching
                ? const Center(
                    child: CircularProgressIndicator(color: _C.accent),
                  )
                : _serverCategories.isEmpty
                ? const Center(
                    child: Text('No active services available at this time.'),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Select Core Service',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _C.grey900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select multiple items to combine into one continuous combo session.',
                        style: TextStyle(fontSize: 12, color: _C.grey600),
                      ),
                      const SizedBox(height: 20),
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.25,
                            ),
                        itemCount: _serverCategories.length,
                        itemBuilder: (_, i) {
                          final cat = _serverCategories[i];
                          final isSelected = _selectedIds.contains(cat.id);
                          return _CategorySelectCard(
                            category: cat,
                            isSelected: isSelected,
                            onTap: () => _toggleSelection(cat.id),
                          );
                        },
                      ),
                      if (_selectedIds.length > 1) ...[
                        const SizedBox(height: 20),
                        _ComboBadge(count: _selectedIds.length),
                      ],
                    ],
                  ),
          ),
          _BottomCta(
            label: 'Set Duration',
            enabled: _selectedIds.isNotEmpty,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _DurationStep(comboItems: itemsToPass),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySelectCard extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategorySelectCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String title = category.categoryName;
    final double price = category.hourlyRate ?? 0.0;
    final String? imageUrl = category.icon;

    // 1. Check if a valid network/live image exists
    final bool hasLiveImage =
        imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith("http");

    // 2. Premium local fallback images to support offline/pre-CMS state
    final Map<String, String> dummyCategoryImages = {
      'eldercare-accompaniment':
          'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?w=300&q=80',
      'hospital-accompaniment':
          'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=300&q=80',
      'fitness-accountability':
          'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=300&q=80',
      'gym-assistance':
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=300&q=80',
      'shopping':
          'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=300&q=80',
      'micro-tutoring':
          'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=300&q=80',
      'home-cleaning':
          'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300&q=80',
    };

    final String fallbackUrl =
        dummyCategoryImages[category.categorySlug] ??
        'https://images.unsplash.com/photo-1511556532299-8f662fc26c06?w=300&q=80';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _C.accent : AppColors.grey200,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── IMAGE SECTION (50% Layout Canvas) ───────────────────
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: hasLiveImage ? imageUrl : category.id,
                    child: hasLiveImage
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.network(fallbackUrl, fit: BoxFit.cover),
                          )
                        : Image.network(fallbackUrl, fit: BoxFit.cover),
                  ),

                  // Floating Selection Check Overlay Badge
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: _C.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── INFO SECTION (40% Layout Canvas) ────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Starts at',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey500,
                              ),
                            ),
                            Text(
                              '₹${price.toStringAsFixed(0)}/hr',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
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
}

class _ComboBadge extends StatelessWidget {
  final int count;
  const _ComboBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.blueTagBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.blueTagBd),
      ),
      child: Row(
        children: [
          const Icon(Icons.layers_outlined, size: 18, color: _C.blueTag),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Combo Booking Session Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _C.grey900,
                  ),
                ),
                Text(
                  '$count services will be fulfilled continuously by a single assigned Buddy.',
                  style: const TextStyle(fontSize: 11, color: _C.grey600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRD STEP 16 — SELECT DURATION IN HOURS
// ═════════════════════════════════════════════════════════════════════════════
class _DurationStep extends StatefulWidget {
  final List<ComboItem> comboItems;
  const _DurationStep({required this.comboItems});

  @override
  State<_DurationStep> createState() => _DurationStepState();
}

class _DurationStepState extends State<_DurationStep> {
  late final List<ComboItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.comboItems;
  }

  double get _runningSum =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _StepHeader(title: 'Set Duration', currentStep: 2, totalSteps: 4),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Configure Service Allocation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _C.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set continuous hours per selected segment (Min 1 hr · Max 8 hrs).',
                  style: TextStyle(fontSize: 12, color: _C.grey600),
                ),
                const SizedBox(height: 20),
                ..._items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ManageDurationRow(
                      item: item,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _BottomCta(
            label: 'View Available Buddies',
            priceLabel: _fmt(_runningSum),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _BuddyStep(comboItems: _items)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageDurationRow extends StatelessWidget {
  final ComboItem item;
  final VoidCallback onChanged;

  const _ManageDurationRow({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final hasImg =
        item.category.icon != null &&
        item.category.icon!.isNotEmpty &&
        item.category.icon!.startsWith('http');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.grey300),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _C.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hasImg
                  ? Image.network(
                      item.category.icon!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.category, size: 16),
                    )
                  : const Icon(Icons.category, size: 16, color: _C.grey600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _C.grey900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${(item.category.hourlyRate ?? 0).toInt()}/hr',
                  style: const TextStyle(fontSize: 11, color: _C.grey600),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (item.hours > 1) {
                    item.hours--;
                    onChanged();
                  }
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _C.grey100,
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.grey300),
                  ),
                  child: const Icon(Icons.remove, size: 14, color: _C.grey900),
                ),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '${item.hours}h',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _C.grey900,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (item.hours < 8) {
                    item.hours++;
                    onChanged();
                  }
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _C.grey100,
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.grey300),
                  ),
                  child: const Icon(Icons.add, size: 14, color: _C.grey900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRD STEP 17 — VIEW AVAILABLE BUDDIES & SELECT (HYBRID MATCHMAKING)
// ═════════════════════════════════════════════════════════════════════════════
class _BuddyStep extends StatefulWidget {
  final List<ComboItem> comboItems;
  const _BuddyStep({required this.comboItems});

  @override
  State<_BuddyStep> createState() => _BuddyStepState();
}

class _BuddyStepState extends State<_BuddyStep> {
  final ApiService _api = ApiService();
  List<BuddyModel> _buddies = [];
  String? _selectedBuddyId;
  bool _fetching = true;

  @override
  void initState() {
    super.initState();
    _fetchMatchingOnlineBuddies();
  }

  Future<void> _fetchMatchingOnlineBuddies() async {
    try {
      final categoryIds = widget.comboItems.map((e) => e.category.id).toList();
      final res = await _api
          .post(
            '/api/v1/user/buddies/matching-online',
            data: {'categoryIds': categoryIds},
          )
          .timeout(const Duration(seconds: 3));

      if (res.data['success'] == true) {
        final list = res.data['data'] as List;
        if (mounted) {
          setState(() {
            _buddies = list.map((e) => BuddyModel.fromJson(e)).toList();
            _fetching = false;
          });
          return;
        }
      }
    } catch (_) {}

    // 🌟 BUDDY LIST OFFLINE FALLBACK SEED LAYER
    if (mounted) {
      setState(() {
        _buddies = [
          BuddyModel(
            id: 'buddy-dummy-1',
            fullName: 'Priya Sharma (Pro Buddy)',
            profilePhoto:
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&q=80',
            city: 'Noida',
            bio:
                'Expert companion with 200+ tasks completed across local subnets.',
            isOnline: true,
            rating: 4.9,
            totalRatings: 142,
            totalTasksCompleted: 210,
            acceptanceRate: 98.5,
            approvedCategories: [],
          ),
          BuddyModel(
            id: 'buddy-dummy-2',
            fullName: 'Vikram Raj',
            profilePhoto:
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80',
            city: 'Delhi NCR',
            bio:
                'Dedicated physical health accountability partner and micro-tutor.',
            isOnline: true,
            rating: 4.7,
            totalRatings: 88,
            totalTasksCompleted: 115,
            acceptanceRate: 94.0,
            approvedCategories: [],
          ),
        ];
        _fetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sum = widget.comboItems.fold(0.0, (s, i) => s + i.subtotal);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _StepHeader(
            title: 'Choose Your Buddy',
            currentStep: 3,
            totalSteps: 4,
          ),
          Expanded(
            child: _fetching
                ? const Center(
                    child: CircularProgressIndicator(color: _C.accent),
                  )
                : _buddies.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.person_off_rounded,
                            size: 48,
                            color: _C.grey400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No Buddies Available Right Now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _C.grey900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'All qualified partners are currently fulfilled. Tap back to adjust slots.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: _C.grey600),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _buddies.length,
                    itemBuilder: (context, idx) {
                      final b = _buddies[idx];
                      final isSelected = _selectedBuddyId == b.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _BuddyProfileCard(
                          buddy: b,
                          isSelected: isSelected,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (_) => BuddyProfileSheet(
                                buddy: b,
                                onSelect: () {
                                  setState(() => _selectedBuddyId = b.id);
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
          _BottomCta(
            label: 'Review Summary',
            priceLabel: _fmt(sum),
            enabled: _selectedBuddyId != null,
            onTap: () {
              final selectedBuddyObj = _buddies.firstWhere(
                (b) => b.id == _selectedBuddyId,
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _ReviewBookingStep(
                    comboItems: widget.comboItems,
                    buddy: selectedBuddyObj,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BuddyProfileCard extends StatelessWidget {
  final BuddyModel buddy;
  final bool isSelected;
  final VoidCallback onTap;

  const _BuddyProfileCard({
    required this.buddy,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        buddy.profilePhoto != null && buddy.profilePhoto!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _C.blueBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _C.accent : _C.grey300,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _C.grey100,
              backgroundImage: hasPhoto
                  ? NetworkImage(buddy.profilePhoto!)
                  : null,
              child: !hasPhoto
                  ? Text(
                      buddy.initials,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _C.grey900,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        buddy.fullName ?? 'HireBuddy Partner',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _C.grey900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    buddy.city ?? 'Local Area',
                    style: const TextStyle(fontSize: 11, color: _C.grey600),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        buddy.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.grey900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${buddy.totalRatings} Reviews)',
                        style: const TextStyle(fontSize: 11, color: _C.grey400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: _C.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BuddyProfileSheet extends StatelessWidget {
  final BuddyModel buddy;
  final VoidCallback onSelect;
  const BuddyProfileSheet({
    super.key,
    required this.buddy,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundImage:
                          buddy.profilePhoto != null &&
                              buddy.profilePhoto!.isNotEmpty
                          ? NetworkImage(buddy.profilePhoto!)
                          : null,
                      child:
                          buddy.profilePhoto == null ||
                              buddy.profilePhoto!.isEmpty
                          ? Text(
                              buddy.initials,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            buddy.fullName ?? 'Buddy',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      buddy.city ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(height: 4),
                              Text('${buddy.rating}'),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(Icons.rate_review),
                              const SizedBox(height: 4),
                              Text('${buddy.totalRatings}'),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(Icons.task_alt),
                              const SizedBox(height: 4),
                              Text('${buddy.totalTasksCompleted}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'About',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(buddy.bio ?? 'No bio available'),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Select Buddy',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRD STEP 18 — REVIEW SUMMARY + PAY VIA RAZORPAY
// ═════════════════════════════════════════════════════════════════════════════
class _ReviewBookingStep extends StatefulWidget {
  final List<ComboItem> comboItems;
  final BuddyModel buddy;

  const _ReviewBookingStep({required this.comboItems, required this.buddy});

  @override
  State<_ReviewBookingStep> createState() => _ReviewBookingStepState();
}

class _ReviewBookingStepState extends State<_ReviewBookingStep> {
  final AddressService _addressService = AddressService();
  final BookingService _bookingService = BookingService();
  final UserService _userService = UserService();
  final ApiService _api = ApiService();
  final RazorpayService _razorpay = RazorpayService();

  AddressModel? _selectedAddress;
  dynamic _userObj;
  bool _loading = true;
  bool _processing = false;

  double get _totalPrice =>
      widget.comboItems.fold(0.0, (s, i) => s + i.subtotal);

  @override
  void initState() {
    super.initState();
    _loadEssentialProfileData();
  }

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }

  Future<void> _loadEssentialProfileData() async {
    try {
      final datasets = await Future.wait([
        _userService.getProfile(),
        _addressService.listAddresses(),
      ]);

      final profileRes = datasets[0] as Map<String, dynamic>;
      final addressList = datasets[1] as List;

      if (mounted) {
        setState(() {
          if (profileRes['success'] == true) {
            _userObj = profileRes['data']['data'] ?? profileRes['data'];
          }

          final defaultSaved = addressList.cast<dynamic>().firstWhere(
            (a) => a.isDefault == true,
            orElse: () => addressList.isNotEmpty ? addressList.first : null,
          );

          if (defaultSaved != null) {
            _selectedAddress = AddressModel(
              id: defaultSaved.id,
              fullAddress: [
                if (defaultSaved.flatNumber?.isNotEmpty == true)
                  defaultSaved.flatNumber!,
                if (defaultSaved.society?.isNotEmpty == true)
                  defaultSaved.society!,
              ].join(', '),
              city: defaultSaved.city,
              state: defaultSaved.state ?? '',
              flatNumber: defaultSaved.flatNumber,
              society: defaultSaved.society,
              landmark: defaultSaved.landmark,
              addressType: defaultSaved.addressType,
              nickname: defaultSaved.nickname,
              isDefault: defaultSaved.isDefault ?? false,
              latitude: defaultSaved.latitude,
              longitude: defaultSaved.longitude,
            );
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _triggerAddressSheet() async {
    final chosen = await showSavedAddressPicker(context);
    if (chosen != null && mounted) {
      setState(() => _selectedAddress = chosen);
    }
  }

  Future<void> _executeBookingCheckoutPipeline() async {
    if (_selectedAddress == null) {
      _triggerSnack('Please map a delivery/service address.');
      return;
    }

    setState(() => _processing = true);
    try {
      final List<ComboItemPayload> payloads = widget.comboItems.map((e) {
        return ComboItemPayload(
          categoryId: e.category.id,
          hours: e.hours,
          subtotal: e.subtotal,
        );
      }).toList();

      final response = await _bookingService.createBooking(
        serviceId: widget.comboItems.first.category.id,
        paymentMethod: 'online',
        addressId: _selectedAddress!.id,
        comboItems: payloads,
        buddyId: widget.buddy.id,
        mode: BookingMode.instant,
      );

      if (response['success'] != true) {
        _triggerSnack(response['error'] ?? 'Engine validation rejection.');
        setState(() => _processing = false);
        return;
      }

      final wrapper = response['data'] ?? {};
      final dataMap = wrapper is Map && wrapper.containsKey('data')
          ? wrapper['data']
          : response['data'];
      final String bookingId = dataMap['_id'] ?? '';

      await _initiateRazorpayGateway(bookingId);
    } catch (_) {
      _triggerSnack('Internal dispatch exception occurred.');
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _initiateRazorpayGateway(String bookingId) async {
    late Map<String, dynamic> checkoutMeta;
    try {
      final res = await _api.post(
        '/api/v1/user/payment/create-order',
        data: {'bookingId': bookingId, 'paymentMethod': 'online'},
      );
      if (res.data['success'] != true) throw Exception();
      checkoutMeta = Map<String, dynamic>.from(
        res.data['data']['data'] ?? res.data['data'],
      );
    } catch (_) {
      try {
        await _api.post(
          '/api/v1/user/bookings/$bookingId/cancel',
          data: {'reason': 'Checkout session registration timeout'},
        );
      } catch (_) {}
      _triggerSnack('Gateway handshake drop. Try again.');
      if (mounted) setState(() => _processing = false);
      return;
    }

    final String contact = _userObj?['phone'] ?? '';
    final checkoutResult = await _razorpay.openCheckout(
      keyId: checkoutMeta['keyId'] ?? '',
      orderId: checkoutMeta['orderId'] ?? '',
      amountPaise: checkoutMeta['amount'] ?? 0,
      description: widget.comboItems
          .map((e) => e.category.categoryName)
          .join(' + '),
      contact: contact.startsWith('+') ? contact : '+91$contact',
      email: _userObj?['email'] ?? 'checkout@hirebuddy.app',
    );

    if (checkoutResult.isSuccess) {
      try {
        final verifyRes = await _api.post(
          '/api/v1/user/payment/verify',
          data: {
            'bookingId': bookingId,
            'razorpayOrderId': checkoutResult.orderId,
            'razorpayPaymentId': checkoutResult.paymentId,
            'razorpaySignature': checkoutResult.signature,
          },
        );

        if (verifyRes.data['success'] == true) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => FindingProviderScreen(
                bookingId: bookingId,
                serviceName: widget.comboItems
                    .map((e) => e.category.categoryName)
                    .join(' + '),
              ),
            ),
          );
        } else {
          _flagPaymentSyncError(bookingId);
        }
      } catch (_) {
        _flagPaymentSyncError(bookingId);
      }
    } else {
      try {
        await _api.post(
          '/api/v1/user/bookings/$bookingId/cancel',
          data: {'reason': 'Payment session closed by client'},
        );
      } catch (_) {}
      _triggerSnack('Payment lifecycle aborted.');
      if (mounted) setState(() => _processing = false);
    }
  }

  void _flagPaymentSyncError(String id) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Syncing Ledger...'),
        content: Text(
          'Funds captured successfully. Processing routing pipeline allocations. Session reference token ID: $id',
        ),
        actions: [
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Return to Dashboard'),
          ),
        ],
      ),
    );
  }

  void _triggerSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _StepHeader(title: 'Review Summary', currentStep: 4, totalSteps: 4),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _C.accent),
                  )
                : _buildFormScrollBody(),
          ),
          _buildPaymentTriggerBar(),
        ],
      ),
    );
  }

  Widget _buildFormScrollBody() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 24),
        _buildTargetBuddyCardHeader(),
        const SizedBox(height: 30),
        const Text(
          'SERVICE LOCATION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: _C.grey600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        _buildLocationTriggerCard(),
        const SizedBox(height: 30),
        const Text(
          'BOOKING CONFIGURATION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: _C.grey600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        _buildSessionComboCardRows(),
        const SizedBox(height: 30),
        const Text(
          'PRICING BREAKDOWN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: _C.grey600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _C.grey100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              ...widget.comboItems.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ledgerRow(e.category.categoryName, e.subtotal),
                ),
              ),
              const Divider(height: 20, color: _C.grey300),
              _ledgerRow('Total Payable Amount', _totalPrice, isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetBuddyCardHeader() {
    final hasImg =
        widget.buddy.profilePhoto != null &&
        widget.buddy.profilePhoto!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.grey300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _C.grey100,
            backgroundImage: hasImg
                ? NetworkImage(widget.buddy.profilePhoto!)
                : null,
            child: !hasImg
                ? Text(
                    widget.buddy.initials,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.buddy.fullName ?? 'Buddy Partner',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _C.grey900,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.buddy.rating} Rating Metric',
                    style: const TextStyle(fontSize: 12, color: _C.grey600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTriggerCard() {
    return GestureDetector(
      onTap: _triggerAddressSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.grey100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.grey300),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: _C.accent, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: _selectedAddress == null
                  ? const Text(
                      'Map Service Dispatch Address',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.grey600,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedAddress!.displayLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _C.grey900,
                          ),
                        ),
                        Text(
                          '${_selectedAddress!.fullAddress}, ${_selectedAddress!.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _C.grey600,
                          ),
                        ),
                      ],
                    ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _C.grey600),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionComboCardRows() {
    return Container(
      decoration: BoxDecoration(
        color: _C.grey100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: _C.greenBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt_rounded, color: _C.green, size: 16),
                SizedBox(width: 8),
                Text(
                  'Instant On-the-Spot Session · Dispatching Buddy ASAP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _C.green,
                  ),
                ),
              ],
            ),
          ),
          ...widget.comboItems.map(
            (item) => Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.category.categoryName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.grey900,
                    ),
                  ),
                  Text(
                    '${item.hours} hrs · ${_fmt(item.subtotal)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _C.accent,
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

  Widget _ledgerRow(String title, double amt, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? _C.grey900 : _C.grey600,
          ),
        ),
        Text(
          _fmt(amt),
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: isBold ? _C.accent : _C.grey900,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTriggerBar() {
    final ready = _selectedAddress != null;
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      color: Colors.white,
      child: GestureDetector(
        onTap: _processing
            ? null
            : (ready ? _executeBookingCheckoutPipeline : _triggerAddressSheet),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 56,
          decoration: BoxDecoration(
            color: ready ? _C.accent : _C.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: _processing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    ready
                        ? 'Pay via Razorpay · ${_fmt(_totalPrice)}'
                        : 'Select Service Address',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Fallback helper for missing layout representations ──
Widget _buildCategoryIcon(CategoryModel cat) {
  final ok =
      cat.icon != null && cat.icon!.isNotEmpty && cat.icon!.startsWith('http');
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: _C.grey100,
      borderRadius: BorderRadius.circular(8),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ok
          ? Image.network(
              cat.icon!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.category, size: 16),
            )
          : const Icon(Icons.category, size: 16, color: _C.grey600),
    ),
  );
}

class _ShimmerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(color: _C.grey100);
}
