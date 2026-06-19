import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hirebuddy/screens/booking/book_now_screen.dart';
import 'package:hirebuddy/utils/address_selector_helper.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/location_service.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';
import '../auth/login_screen.dart';
import '../service/service_detail_screen.dart';
import '../../core/utils/string_utils.dart';
import '../category/category_services_screen.dart';
import '../services/search_screen.dart';
import '../shop/product_detail_screen.dart';
import '../shop/cart_screen.dart';
import '../shop/shop_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../profile/profile_screen.dart';
import 'all_services_sheet.dart';
import '../../providers/home_provider.dart';
import '../../providers/location_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/app_review_service.dart';
import '../../widgets/rate_app_dialog.dart';
import '../../models/category_model.dart';
import '../../models/booking_model.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _ratingPromptShownThisSession = false;

  // Lazily initialised so dispose() is always safe even if initState threw
  late final PageController _bannerController = PageController();

  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  // ── Dummy / placeholder data (replace with real providers) ───────────────
  final List<CategoryModel> dummyCategories = [
    CategoryModel(
      id: "1",
      categoryName: "Eldercare Accompaniment",
      categorySlug: "eldercare-accompaniment",
      description: "",
      icon: "",
      displayOrder: 1,
      isActive: true,
      parentCategoryId: null,
      hourlyRate: 149,
    ),

    CategoryModel(
      id: "2",
      categoryName: "Fitness Accountability",
      categorySlug: "fitness-accountability",
      description: "",
      icon: "",
      displayOrder: 2,
      isActive: true,
      parentCategoryId: null,
      hourlyRate: 199,
    ),

    CategoryModel(
      id: "3",
      categoryName: "Shopping",
      categorySlug: "shopping",
      description: "",
      icon: "",
      displayOrder: 3,
      isActive: false,
      parentCategoryId: null,
      hourlyRate: 129,
    ),

    CategoryModel(
      id: "4",
      categoryName: "Micro Tutoring",
      categorySlug: "micro-tutoring",
      description: "",
      icon: "",
      displayOrder: 4,
      isActive: true,
      parentCategoryId: null,
      hourlyRate: 249,
    ),
  ];

  final List<BookingModel> dummyUpcomingBookings = [
    BookingModel(
      id: "1",
      bookingNumber: "HB001",
      userId: "user1",
      bookingStatus: "pending",
      scheduledDateTime: DateTime.now().add(const Duration(days: 2)),
      createdAt: DateTime.now(),
      categoryId: CategoryInfo(
        id: "cat1",
        categoryName: "Hospital Accompaniment",
      ),
      providerId: ProviderInfo(fullName: "Priya S.", averageRating: 4.9),
    ),
    BookingModel(
      id: "2",
      bookingNumber: "HB002",
      userId: "user1",
      bookingStatus: "pending",
      scheduledDateTime: DateTime.now().add(const Duration(days: 5)),
      createdAt: DateTime.now(),
      categoryId: CategoryInfo(id: "cat2", categoryName: "Gym Assistance"),
      providerId: ProviderInfo(fullName: "Vikram R.", averageRating: 4.8),
    ),
  ];

  bool hasActiveBooking = true;
  String activeBookingStatus = "Buddy is on the way";
  String activeCategoryName = "Home Cleaning";
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      if (homeProvider.banners.isNotEmpty) {
        _startBannerTimer();
      } else {
        _loadData();
      }
      _maybeShowAppReviewPrompt();
    });
    _updateLocation();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    // Track length accurately whether live data is populated or not
    final int totalBanners = homeProvider.banners.isEmpty
        ? 2
        : homeProvider.banners.length;

    if (totalBanners <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients) {
        final next = (_currentBannerIndex + 1) % totalBanners;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _loadData() async {
    await Provider.of<HomeProvider>(context, listen: false).fetchHomeData();
    if (mounted) _startBannerTimer();
  }

  Future<void> _updateLocation() async {
    await LocationService().updateUserLocation();
  }

  Future<void> _maybeShowAppReviewPrompt() async {
    if (_ratingPromptShownThisSession) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) return;
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final status = await AppReviewService().getStatus();
    if (!mounted || status == null || !status.shouldPrompt) return;
    _ratingPromptShownThisSession = true;
    await RateAppDialog.show(context);
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  String _getFormattedAddress(dynamic address) {
    if (address == null) return 'Add your location';
    final parts = <String>[];
    if (address.flatNumber != null && address.flatNumber!.isNotEmpty) {
      parts.add(address.flatNumber!);
    }
    if (address.street.isNotEmpty) parts.add(address.street);
    if (address.city.isNotEmpty) parts.add(address.city);
    return parts.isEmpty ? 'Add your location' : parts.join(', ');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    final banners = homeProvider.banners;
    final mainCategories = homeProvider.mainCategories;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Provider.of<AuthProvider>(context).currentUser;

    // Height of the tallest banner (or a sensible default when banners are absent)
    final double bannerMaxHeight = banners.isEmpty
        ? MediaQuery.of(context).padding.top + 220
        : banners.map((b) => b.height).reduce((a, b) => a > b ? a : b);

    // Collapsed height: just enough for status bar + profile row + search pill overlap
    final double bannerMinHeight = MediaQuery.of(context).padding.top + 72;

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark ? AppColors.grey900 : Colors.white,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        body: Stack(
          children: [
            // ── Main scroll view ────────────────────────────────────────────
            RefreshIndicator(
              onRefresh: () async => homeProvider.fetchHomeData(),
              color: AppColors.primary,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                slivers: [
                  // ══════════════════════════════════════════════════════════
                  // CAROUSEL BANNER HEADER  (replaces the old fixed AppBar)
                  // ══════════════════════════════════════════════════════════
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      minHeight: bannerMinHeight,
                      maxHeight: bannerMaxHeight,
                      builder: (context, shrinkOffset, overlapsContent, minExtent, maxExtent) {
                        // 0.0 = fully collapsed → 1.0 = fully expanded
                        final expandRatio = (maxExtent - minExtent) == 0
                            ? 1.0
                            : 1.0 -
                                  (shrinkOffset / (maxExtent - minExtent))
                                      .clamp(0.0, 1.0);

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // ── Carousel / plain white background ──────────
                            SizedBox(
                              width: double.infinity,
                              height: double.infinity,
                              child: Stack(
                                children: [
                                  banners.isEmpty
                                      ? Container(color: Colors.white)
                                      : PageView.builder(
                                          controller: _bannerController,
                                          itemCount: banners.isEmpty
                                              ? 2
                                              : banners.length,
                                          onPageChanged: (index) {
                                            setState(
                                              () => _currentBannerIndex = index,
                                            );
                                          },
                                          // ── Inside your PageView.builder inside HomeScreen.dart ──
                                          itemBuilder: (context, index) {
                                            // 1. Determine if we are using live backend data or falling back to dummy data
                                            final isLive = banners.isNotEmpty;

                                            // 2. Fallback Dummy Banners Data Array
                                            final List<Map<String, dynamic>>
                                            dummyBanners = [
                                              {
                                                'title':
                                                    'Eldercare Accompaniment',
                                                'subtitle': 'TRUSTED BUDDIES',
                                                'isDark': true,
                                                'color': 0xFF0F2747,
                                                'image':
                                                    'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?w=500&q=80', // Replace with asset path if using Assets
                                              },
                                              {
                                                'title':
                                                    'Fitness Accountability',
                                                'subtitle':
                                                    'MOTIVATION PARTNERS',
                                                'isDark': false,
                                                'color': 0xFFEEF2F8,
                                                'image':
                                                    'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=500&q=80',
                                              },
                                            ];

                                            // 3. Extract the properties safely depending on the active state
                                            final String bannerTitle = isLive
                                                ? banners[index].title!
                                                : dummyBanners[index %
                                                      dummyBanners
                                                          .length]['title'];
                                            final String bannerSubtitle = isLive
                                                ? banners[index].subtitle!
                                                : dummyBanners[index %
                                                      dummyBanners
                                                          .length]['subtitle'];
                                            final bool isDarkBanner = isLive
                                                ? banners[index].isDark
                                                : dummyBanners[index %
                                                      dummyBanners
                                                          .length]['isDark'];
                                            final String? networkUrl = isLive
                                                ? banners[index].imageUrl
                                                : null;

                                            // Custom backup layout background colors if images lag while downloading
                                            final Color fallbackBgColor = isLive
                                                ? _hexToColor(
                                                    banners[index]
                                                        .gradientStart,
                                                  )
                                                : Color(
                                                    dummyBanners[index %
                                                        dummyBanners
                                                            .length]['color'],
                                                  );

                                            return GestureDetector(
                                              onTap: () {
                                                if (isLive &&
                                                    banners[index]
                                                            .linkToCategory !=
                                                        null) {
                                                  // Your existing navigation click handler logic...
                                                }
                                              },
                                              child: AnnotatedRegion<SystemUiOverlayStyle>(
                                                value: isDarkBanner
                                                    ? SystemUiOverlayStyle.light
                                                    : SystemUiOverlayStyle.dark,
                                                child: Container(
                                                  color:
                                                      fallbackBgColor, // Safe color canvas layer
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      // ── IMAGE LAYER ──────────────────────────────────
                                                      if (isLive &&
                                                          networkUrl != null &&
                                                          networkUrl.isNotEmpty)
                                                        Image.network(
                                                          networkUrl,
                                                          fit: BoxFit.cover,
                                                          alignment: Alignment
                                                              .topCenter,
                                                          // Premium loading indicator shimmer fallback
                                                          loadingBuilder:
                                                              (
                                                                context,
                                                                child,
                                                                loadingProgress,
                                                              ) {
                                                                if (loadingProgress ==
                                                                    null)
                                                                  return child;
                                                                return _ShimmerWidget(); // Uses your pre-existing shimmer widget!
                                                              },
                                                          errorBuilder:
                                                              (_, __, ___) =>
                                                                  _buildDummyImageFallback(
                                                                    index,
                                                                    dummyBanners,
                                                                  ),
                                                        )
                                                      else
                                                        _buildDummyImageFallback(
                                                          index,
                                                          dummyBanners,
                                                        ),

                                                      // ── GRADIENT OVERLAY ─────────────────────────────
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            begin: Alignment
                                                                .topCenter,
                                                            end: Alignment
                                                                .bottomCenter,
                                                            colors: [
                                                              Colors.black
                                                                  .withValues(
                                                                    alpha: 0.1,
                                                                  ),
                                                              Colors.black
                                                                  .withValues(
                                                                    alpha: 0.75,
                                                                  ), // Darkens bottom for crisp text contrast
                                                            ],
                                                          ),
                                                        ),
                                                      ),

                                                      // ── TEXT CONTENT LAYER ───────────────────────────
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              top:
                                                                  MediaQuery.of(
                                                                        context,
                                                                      )
                                                                      .padding
                                                                      .top +
                                                                  24,
                                                              left: 24,
                                                              right: 24,
                                                            ),
                                                        child: Opacity(
                                                          opacity: expandRatio,
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              const SizedBox(
                                                                height: 100,
                                                              ),
                                                              if (bannerSubtitle
                                                                  .isNotEmpty) ...[
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            10,
                                                                        vertical:
                                                                            4,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        isDarkBanner
                                                                        ? Colors
                                                                              .white24
                                                                        : Colors
                                                                              .black12,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                  ),
                                                                  child: Text(
                                                                    bannerSubtitle
                                                                        .toUpperCase(),
                                                                    style: TextStyle(
                                                                      color:
                                                                          isDarkBanner
                                                                          ? Colors.white
                                                                          : Colors.black87,
                                                                      fontSize:
                                                                          10,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      letterSpacing:
                                                                          1.1,
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 8,
                                                                ),
                                                              ],
                                                              Text(
                                                                bannerTitle,
                                                                style: TextStyle(
                                                                  color:
                                                                      isDarkBanner
                                                                      ? Colors
                                                                            .white
                                                                      : Color(
                                                                          0xFF1A1A1A,
                                                                        ),
                                                                  fontSize: 26,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                  height: 1.1,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ],
                              ),
                            ),

                            // ── Profile row overlay (fades on collapse) ────
                            Padding(
                              padding: EdgeInsets.only(
                                top: MediaQuery.of(context).padding.top + 16,
                                left: 24,
                                right: 24,
                              ),
                              child: Opacity(
                                // Fade out in the LAST 40% of collapse so it
                                // disappears gracefully before fully collapsed
                                opacity: (expandRatio / 0.6).clamp(0.0, 1.0),
                                child: IgnorePointer(
                                  // When nearly collapsed, disable taps so
                                  // the invisible overlay doesn't intercept
                                  ignoring: expandRatio < 0.1,
                                  child: Builder(
                                    builder: (context) {
                                      final int currentIndex =
                                          _bannerController.hasClients
                                          ? _bannerController.page?.round() ?? 0
                                          : 0;
                                      final bool isDarkBanner =
                                          banners.isNotEmpty &&
                                              banners.length > currentIndex
                                          ? banners[currentIndex].isDark
                                          : false;
                                      final Color textColor = isDarkBanner
                                          ? Colors.white
                                          : AppColors.grey900;
                                      final Color subTextColor = isDarkBanner
                                          ? Colors.white70
                                          : AppColors.grey500;

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Avatar + name + address
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const ProfileScreen(),
                                                  ),
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: textColor
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: CircleAvatar(
                                                    radius: 20,
                                                    backgroundColor: Colors
                                                        .white
                                                        .withValues(alpha: 0.5),
                                                    // 🌟 FIXED: Verify the photo is not null AND not empty
                                                    backgroundImage:
                                                        user?.profilePhoto !=
                                                                null &&
                                                            user!
                                                                .profilePhoto!
                                                                .isNotEmpty
                                                        ? NetworkImage(
                                                            user!.profilePhoto!,
                                                          )
                                                        : null,
                                                    // 🌟 FIXED: Match the text fallback condition identically
                                                    child:
                                                        user?.profilePhoto ==
                                                                null ||
                                                            user!
                                                                .profilePhoto!
                                                                .isEmpty
                                                        ? Text(
                                                            user?.fullName.isNotEmpty ==
                                                                    true
                                                                ? user!
                                                                      .fullName[0]
                                                                      .toUpperCase()
                                                                : 'U',
                                                            style:
                                                                const TextStyle(
                                                                  color: AppColors
                                                                      .grey900,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 18,
                                                                ),
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Hi, ${user?.name ?? 'Guest'}',
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Consumer<LocationProvider>(
                                                    builder: (context, loc, _) {
                                                      // Determine fallback content parameters if provider state is empty
                                                      final bool hasTitle = loc
                                                          .addressTitle
                                                          .isNotEmpty;
                                                      final String
                                                      displayTitle = hasTitle
                                                          ? loc.addressTitle
                                                          : 'Location';

                                                      final String displayFull =
                                                          loc
                                                              .addressFull
                                                              .isNotEmpty
                                                          ? loc.addressFull
                                                          : _getFormattedAddress(
                                                              user?.address,
                                                            );

                                                      return GestureDetector(
                                                        // 🌟 Triggers the complete connected picker sheet workflow on click!
                                                        onTap: () =>
                                                            AddressSelectorHelper.selectOrAddAddress(
                                                              context,
                                                            ),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .location_on_rounded,
                                                              color:
                                                                  subTextColor,
                                                              size: 14,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  200, // Safe bounding constraints
                                                              child: Text.rich(
                                                                TextSpan(
                                                                  // Renders the Address Nickname bolded (e.g., "Home: ")
                                                                  text:
                                                                      '$displayTitle: ',
                                                                  style: TextStyle(
                                                                    color:
                                                                        textColor,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                  children: [
                                                                    // Appends the description text right next to it smoothly
                                                                    TextSpan(
                                                                      text:
                                                                          displayFull,
                                                                      style: TextStyle(
                                                                        color:
                                                                            subTextColor,
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                            // ── Floating search pill (bottom of header) ────
                            Positioned(
                              bottom: -28,
                              left: 24,
                              right: 24,
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HomeScreen(),
                                  ),
                                ),
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.grey800
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.search_rounded,
                                        color: AppColors.grey400,
                                        size: 24,
                                      ),
                                      SizedBox(width: 12),
                                      _AnimatedSearchHint(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Spacer so content doesn't hide behind the floating search pill
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),

                  // ══════════════════════════════════════════════════════════
                  // HERO SECTION
                  // ══════════════════════════════════════════════════════════
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2747),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "On-demand help, anywhere",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              "Get a trusted Buddy\nfor any task, instantly",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Verified students. Real skills.\nStarting ₹99/hr.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _heroButton(
                                  context,
                                  icon: Icons.flash_on_rounded,
                                  label: "Book Now",
                                  onTap: () {
                                    // Example navigation:
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookNowScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _heroButton(
                                  context,
                                  icon: Icons.calendar_month_rounded,
                                  label: "Schedule",
                                  onTap: () {
                                    // Example navigation:
                                    // Navigator.push(context, MaterialPageRoute(builder: (context) => NextScreen()));
                                  },
                                ),
                                _heroButton(
                                  context,
                                  icon: Icons.autorenew_rounded,
                                  label: "Monthly Package",
                                  onTap: () {
                                    // Example navigation:
                                    // Navigator.push(context, MaterialPageRoute(builder: (context) => NextScreen()));
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ══════════════════════════════════════════════════════════
                  // TOP CATEGORIES
                  // ══════════════════════════════════════════════════════════
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Top Categories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {}, // TODO: all categories page
                            child: Text(
                              'See All',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 240,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: dummyCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) => _buildCategoryCard(
                          context: context,
                          category: dummyCategories[index],
                        ),
                      ),
                    ),
                  ),

                  // ══════════════════════════════════════════════════════════
                  // HOW IT WORKS
                  // ══════════════════════════════════════════════════════════
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F3FF),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "How It Works",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Book a trusted Buddy in 3 simple steps",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.grey600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _HowItWorksStep(
                                  icon: Icons.design_services_rounded,
                                  title: "Choose\nService",
                                  step: "1",
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              Expanded(
                                child: _HowItWorksStep(
                                  icon: Icons.person_search_rounded,
                                  title: "Book\nBuddy",
                                  step: "2",
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              Expanded(
                                child: _HowItWorksStep(
                                  icon: Icons.task_alt_rounded,
                                  title: "Task\nDone",
                                  step: "3",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ══════════════════════════════════════════════════════════
                  // UPCOMING BOOKINGS
                  // ══════════════════════════════════════════════════════════
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
                          child: Text(
                            "Upcoming Bookings",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 105,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: dummyUpcomingBookings.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) =>
                                _buildUpcomingBookingCard(
                                  dummyUpcomingBookings[index],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ══════════════════════════════════════════════════════════
                  // BRAND FOOTER
                  // ══════════════════════════════════════════════════════════
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'hirebuddy',
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2.5,
                              height: 1,
                              color: AppColors.primary.withValues(alpha: 0.08),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Trusted help, right at your doorstep.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),

            // ── Active booking strip (floating) ─────────────────────────────
            if (hasActiveBooking)
              Positioned(
                right: 16,
                bottom: 20,
                child: GestureDetector(
                  onTap: () {
                    /* navigate to tracking screen */
                  },
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 180,
                      maxWidth: 250,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2747),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                activeBookingStatus,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeCategoryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required CategoryModel category,
  }) {
    final String title = category.categoryName;
    final bool isActive = category.isActive;
    final double price = category.hourlyRate;

    final String? imageUrl = category.icon;

    final bool hasImage =
        imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith("http");

    return GestureDetector(
      onTap: () {
        if (!isActive) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryServicesScreen(
              categoryId: category.id,
              categoryName: category.categoryName,
            ),
          ),
        );
      },
      child: Opacity(
        opacity: isActive ? 1 : 0.65,
        child: Container(
          width: 170,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppColors.grey200 : AppColors.grey300,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TOP ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: hasImage
                          ? Image.network(
                              imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.category,
                                size: 22,
                                color: AppColors.grey700,
                              ),
                            )
                          : const Icon(
                              Icons.category,
                              size: 22,
                              color: AppColors.grey700,
                            ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.redAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isActive ? "Active" : "Inactive",
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              /// CATEGORY NAME
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.textPrimary : AppColors.grey500,
                ),
              ),

              const SizedBox(height: 8),

              /// STARTING PRICE
              Row(
                children: [
                  const Icon(
                    Icons.currency_rupee,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  Text(
                    "${price.toInt()}/hr",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                "Starting price",
                style: TextStyle(fontSize: 10, color: AppColors.grey600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Color _hexToColor(String hexString) {
  //   var hex = hexString.replaceAll('#', '');
  //   if (hex.length == 6) hex = 'FF$hex';
  //   return Color(int.parse(hex, radix: 16));
  // }
}

// ─────────────────────────── FEATURED PRODUCT CARD ───────────────────────────

// ─────────────────────────────────────────────────────────────────────────────

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

//upcoming booking

Widget _buildUpcomingBookingCard(BookingModel booking) {
  final date = booking.scheduledDateTime.day.toString();
  final month = DateFormat(
    'MMM',
  ).format(booking.scheduledDateTime).toUpperCase();

  final time = DateFormat('h:mm a').format(booking.scheduledDateTime);

  return Container(
    width: 320,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF2E2E2E),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4F46E5),
                ),
              ),
              Text(
                month,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.displayCategoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 13,
                    color: Colors.white70,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    time,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),

                  const SizedBox(width: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6FFF1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      booking.bookingType,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFD9F99D),
                    child: Text(
                      booking.buddyInitials,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      booking.buddyName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Text(
                    booking.rating.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// -------------------------------------------------------------
// STICKY HEADER DELEGATE FOR CUSTOM CURVED HERO & SEARCH BAR
// -------------------------------------------------------------
typedef _HeaderBuilder =
    Widget Function(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      double minExtent,
      double maxExtent,
    );

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.builder,
  });

  final double minHeight;
  final double maxHeight;
  final _HeaderBuilder builder;

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
    return builder(
      context,
      shrinkOffset,
      overlapsContent,
      minExtent,
      maxExtent,
    );
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate old) =>
      old.minHeight != minHeight ||
      old.maxHeight != maxHeight ||
      old.builder != builder;
}

class _AnimatedSearchHint extends StatefulWidget {
  const _AnimatedSearchHint();

  @override
  State<_AnimatedSearchHint> createState() => _AnimatedSearchHintState();
}

class _AnimatedSearchHintState extends State<_AnimatedSearchHint>
    with SingleTickerProviderStateMixin {
  final List<String> _hints = [
    'Search "Elder care"',
    'Search "Gym buddy"',
    'Search "Hospital help"',
    'Search "Micro tutoring"',
    'Search "Shopping assist"',
  ];

  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward(); // show first hint

    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _controller.reverse(); // fade out
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _hints.length;
      });
      _controller.forward(); // fade in next
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Text(
        _hints[_currentIndex],
        style: const TextStyle(
          color: AppColors.grey400,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

Widget _heroButton(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback
  onTap, // Changed from Function to VoidCallback for better type safety
}) {
  return GestureDetector(
    onTap: onTap, // Directly passing the required onTap function here
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            "$label   ",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Icon(Icons.arrow_forward_sharp, color: Colors.white, size: 18),
        ],
      ),
    ),
  );
}

// OFFERS FOR YOU SECTION
// ----------------------

class _HowItWorksStep extends StatelessWidget {
  final String title;
  final String step;
  final IconData icon;

  const _HowItWorksStep({
    required this.title,
    required this.step,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        // Show bottom sheet / navigate to explainer page
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  step,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Icon(icon, color: AppColors.primary, size: 28),

            const SizedBox(height: 8),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildDummyImageFallback(
  int index,
  List<Map<String, dynamic>> dummyBanners,
) {
  final path = dummyBanners[index % dummyBanners.length]['image'] as String;

  if (path.startsWith('http')) {
    return Image.network(
      path,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    );
  } else {
    return Image.asset(path, fit: BoxFit.cover, alignment: Alignment.topCenter);
  }
}
