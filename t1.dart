// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import '../../core/theme/app_colors.dart';
// import '../../providers/auth_provider.dart';
// import '../../providers/cart_provider.dart';
// import '../../services/location_service.dart';
// import '../../services/product_service.dart';
// import '../../models/product_model.dart';
// import '../auth/login_screen.dart';
// import '../service/service_detail_screen.dart';
// import '../../core/utils/string_utils.dart';
// import '../category/category_services_screen.dart';
// import '../services/search_screen.dart';
// import '../shop/product_detail_screen.dart';
// import '../shop/cart_screen.dart';
// import '../shop/shop_screen.dart';
// import '../booking/my_bookings_screen.dart';
// import '../profile/profile_screen.dart';
// import 'all_services_sheet.dart';
// import '../../providers/home_provider.dart';
// import '../../providers/location_provider.dart';
// import '../../models/service_model.dart';
// import '../../models/offer_model.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../../services/app_review_service.dart';
// import '../../widgets/rate_app_dialog.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // Static — only show the app-rating modal once per app session
//   static bool _ratingPromptShownThisSession = false;

//   late PageController _bannerController;
//   Timer? _bannerTimer;
//   int _currentBannerIndex = 0;

//   final _productService = ProductService();
//   List<ProductModel> _featuredProducts = [];
//   bool _productsLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _bannerController = PageController();

//     // Start timing if banners already exists (pre-loaded)
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final homeProvider = Provider.of<HomeProvider>(context, listen: false);
//       if (homeProvider.banners.isNotEmpty) {
//         _startBannerTimer();
//       } else {
//         _loadData();
//       }
//       _loadFeaturedProducts();
//       _maybeShowAppReviewPrompt();
//     });

//     _updateLocation();
//   }

//   Future<void> _maybeShowAppReviewPrompt() async {
//     if (_ratingPromptShownThisSession) return;
//     final auth = Provider.of<AuthProvider>(context, listen: false);
//     if (!auth.isAuthenticated) return;

//     // Small delay so it doesn't fight with login redirect / banner load
//     await Future.delayed(const Duration(seconds: 3));
//     if (!mounted) return;

//     final status = await AppReviewService().getStatus();
//     if (!mounted || status == null || !status.shouldPrompt) return;

//     _ratingPromptShownThisSession = true;
//     await RateAppDialog.show(context);
//   }

//   @override
//   void dispose() {
//     _bannerTimer?.cancel();
//     _bannerController.dispose();
//     super.dispose();
//   }

//   void _startBannerTimer() {
//     _bannerTimer?.cancel();
//     final banners = Provider.of<HomeProvider>(context, listen: false).banners;
//     if (banners.length <= 1) return;

//     _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
//       if (_bannerController.hasClients) {
//         int nextIndex = (_currentBannerIndex + 1) % banners.length;
//         _bannerController.animateToPage(
//           nextIndex,
//           duration: const Duration(milliseconds: 800),
//           curve: Curves.easeInOutCubic,
//         );
//       }
//     });
//   }

//   Future<void> _updateLocation() async {
//     await LocationService().updateUserLocation();
//   }

//   Future<void> _loadData() async {
//     await Provider.of<HomeProvider>(context, listen: false).fetchHomeData();
//     if (mounted) _startBannerTimer();
//   }

//   Future<void> _loadFeaturedProducts() async {
//     if (_featuredProducts.isNotEmpty) return;
//     try {
//       final products = await _productService.listProducts(page: 1);
//       if (!mounted) return;
//       setState(() {
//         _featuredProducts = products.take(8).toList();
//         _productsLoading = false;
//       });
//     } catch (_) {
//       if (mounted) setState(() => _productsLoading = false);
//     }
//   }

//   String _getFormattedAddress(dynamic address) {
//     if (address == null) return 'Add your location';

//     List<String> parts = [];

//     // Add flat details if available
//     if (address.flatNumber != null && address.flatNumber!.isNotEmpty) {
//       parts.add(address.flatNumber!);
//     }

//     // Add society/building
//     if (address.street.isNotEmpty) {
//       parts.add(address.street);
//     }

//     // Add city
//     if (address.city.isNotEmpty) {
//       parts.add(address.city);
//     }

//     return parts.isEmpty ? 'Add your location' : parts.join(', ');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final homeProvider = Provider.of<HomeProvider>(context);
//     final banners = homeProvider.banners;
//     final mainCategories = homeProvider.mainCategories;
//     final popularServices = homeProvider.popularServices;
//     final isLoading = homeProvider.isLoading;

//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final user = Provider.of<AuthProvider>(context).currentUser;

//     final overlayStyle = SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
//       statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
//       systemNavigationBarColor: isDark ? AppColors.grey900 : Colors.white,
//       systemNavigationBarIconBrightness: isDark
//           ? Brightness.light
//           : Brightness.dark,
//     );

//     final cart = context.watch<CartProvider>();
//     final bottomPad = MediaQuery.of(context).padding.bottom;

//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: overlayStyle,
//       child: Scaffold(
//         body: Stack(
//           children: [
//             RefreshIndicator(
//               onRefresh: () async {
//                 await homeProvider.fetchHomeData();
//               },
//               color: AppColors.primary,
//               backgroundColor: Colors.white,
//               child: CustomScrollView(
//             slivers: [
//               // CUSTOM STICKY HERO HEADER
//               SliverPersistentHeader(
//                 pinned: true,
//                 delegate: _StickyHeaderDelegate(
//                   minHeight: MediaQuery.of(context).padding.top + 40,
//                   maxHeight: banners.isEmpty
//                       ? MediaQuery.of(context).padding.top + 100
//                       : banners
//                             .map((b) => b.height)
//                             .reduce((a, b) => a > b ? a : b),
//                   builder: (context, shrinkOffset, overlapsContent, minExtent, maxExtent) {
//                     final opacity = (maxExtent - minExtent) == 0
//                         ? 1.0
//                         : 1.0 -
//                               (shrinkOffset / (maxExtent - minExtent)).clamp(
//                                 0.0,
//                                 1.0,
//                               );

//                     return Stack(
//                       clipBehavior: Clip.none,
//                       children: [
//                         // Brand Curved Background with PageView Content
//                         ClipRRect(
//                           borderRadius: BorderRadius.zero,
//                           child: SizedBox(
//                             width: double.infinity,
//                             height: double.infinity,
//                             child: Stack(
//                               children: [
//                                 banners.isEmpty
//                                     ? Container(color: Colors.white)
//                                     : PageView.builder(
//                                         controller: _bannerController,
//                                         itemCount: banners.length,
//                                         onPageChanged: (index) {
//                                           setState(() {
//                                             _currentBannerIndex = index;
//                                           });
//                                         },
//                                         itemBuilder: (context, index) {
//                                           final banner = banners[index];
//                                           return GestureDetector(
//                                             onTap: () {
//                                               if (banner.linkToCategory !=
//                                                       null &&
//                                                   banner
//                                                       .linkToCategory!
//                                                       .isNotEmpty) {
//                                                 try {
//                                                   final category =
//                                                       mainCategories.firstWhere(
//                                                         (c) =>
//                                                             c.id ==
//                                                             banner
//                                                                 .linkToCategory,
//                                                       );

//                                                   Navigator.push(
//                                                     context,
//                                                     MaterialPageRoute(
//                                                       builder: (context) =>
//                                                           CategoryServicesScreen(
//                                                             categoryName: category
//                                                                 .categoryName,
//                                                             categoryId:
//                                                                 category.id,
//                                                           ),
//                                                     ),
//                                                   );
//                                                 } catch (e) {
//                                                   debugPrint(
//                                                     'Banner category link error: $e',
//                                                   );
//                                                 }
//                                               }
//                                             },
//                                             child: AnnotatedRegion<SystemUiOverlayStyle>(
//                                               value: banner.isDark
//                                                   ? SystemUiOverlayStyle.light
//                                                   : SystemUiOverlayStyle.dark,
//                                               child: Stack(
//                                                 fit: StackFit.expand,
//                                                 children: [
//                                                   if (banner.imageUrl != null &&
//                                                       banner
//                                                           .imageUrl!
//                                                           .isNotEmpty)
//                                                     Opacity(
//                                                       opacity: banner.opacity,
//                                                       child: Image.network(
//                                                         banner.imageUrl!,
//                                                         fit: BoxFit.cover,
//                                                         alignment:
//                                                             Alignment.topCenter,
//                                                         errorBuilder:
//                                                             (
//                                                               context,
//                                                               error,
//                                                               stackTrace,
//                                                             ) =>
//                                                                 Container(), // Safety
//                                                       ),
//                                                     ),
//                                                   Opacity(
//                                                     opacity:
//                                                         banner.gradientOpacity,
//                                                     child: Container(
//                                                       decoration: BoxDecoration(
//                                                         gradient: LinearGradient(
//                                                           begin: Alignment
//                                                               .topCenter,
//                                                           end: Alignment
//                                                               .bottomCenter,
//                                                           colors: [
//                                                             _hexToColor(
//                                                               banner
//                                                                   .gradientStart,
//                                                             ),
//                                                             _hexToColor(
//                                                               banner
//                                                                   .gradientEnd,
//                                                             ),
//                                                           ],
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ),
//                                                   Padding(
//                                                     padding: EdgeInsets.only(
//                                                       top:
//                                                           MediaQuery.of(
//                                                             context,
//                                                           ).padding.top +
//                                                           16,
//                                                       left: 24,
//                                                       right: 24,
//                                                     ),
//                                                     child: Opacity(
//                                                       opacity: opacity,
//                                                       child: OverflowBox(
//                                                         maxHeight:
//                                                             double.infinity,
//                                                         alignment:
//                                                             Alignment.topCenter,
//                                                         child: Column(
//                                                           crossAxisAlignment:
//                                                               CrossAxisAlignment
//                                                                   .start,
//                                                           children: [
//                                                             const SizedBox(
//                                                               height: 120,
//                                                             ),
//                                                             if (banner.subtitle !=
//                                                                     null &&
//                                                                 banner
//                                                                     .subtitle!
//                                                                     .isNotEmpty) ...[
//                                                               Container(
//                                                                 padding:
//                                                                     const EdgeInsets.symmetric(
//                                                                       horizontal:
//                                                                           16,
//                                                                       vertical:
//                                                                           8,
//                                                                     ),
//                                                                 decoration: BoxDecoration(
//                                                                   color:
//                                                                       banner
//                                                                           .isDark
//                                                                       ? Colors.white.withValues(
//                                                                           alpha:
//                                                                               0.2,
//                                                                         )
//                                                                       : Colors.black.withValues(
//                                                                           alpha:
//                                                                               0.05,
//                                                                         ),
//                                                                   borderRadius:
//                                                                       BorderRadius.circular(
//                                                                         12,
//                                                                       ),
//                                                                   border: Border.all(
//                                                                     color:
//                                                                         banner
//                                                                             .isDark
//                                                                         ? Colors.white.withValues(
//                                                                             alpha:
//                                                                                 0.3,
//                                                                           )
//                                                                         : Colors.black.withValues(
//                                                                             alpha:
//                                                                                 0.1,
//                                                                           ),
//                                                                   ),
//                                                                 ),
//                                                                 child: Text(
//                                                                   banner
//                                                                       .subtitle!,
//                                                                   style: TextStyle(
//                                                                     color:
//                                                                         banner
//                                                                             .isDark
//                                                                         ? Colors
//                                                                               .white
//                                                                         : Colors
//                                                                               .black87,
//                                                                     fontSize:
//                                                                         12,
//                                                                     fontWeight:
//                                                                         FontWeight
//                                                                             .w600,
//                                                                     letterSpacing:
//                                                                         1.2,
//                                                                   ),
//                                                                 ),
//                                                               ),
//                                                               const SizedBox(
//                                                                 height: 12,
//                                                               ),
//                                                             ],
//                                                             if (banner.title !=
//                                                                     null &&
//                                                                 banner
//                                                                     .title!
//                                                                     .isNotEmpty)
//                                                               Text(
//                                                                 banner.title!,
//                                                                 style: TextStyle(
//                                                                   color: _hexToColor(
//                                                                     banner
//                                                                         .titleColor,
//                                                                   ),
//                                                                   fontSize: 28,
//                                                                   fontWeight:
//                                                                       FontWeight
//                                                                           .w900,
//                                                                   height: 1.1,
//                                                                   shadows:
//                                                                       banner
//                                                                           .isDark
//                                                                       ? const [
//                                                                           Shadow(
//                                                                             color:
//                                                                                 Colors.black26,
//                                                                             offset: Offset(
//                                                                               0,
//                                                                               2,
//                                                                             ),
//                                                                             blurRadius:
//                                                                                 10,
//                                                                           ),
//                                                                         ]
//                                                                       : null,
//                                                                 ),
//                                                               ),
//                                                           ],
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           );
//                                         },
//                                       ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         // Hi Name Overlay (Always stays on top of Carousel)
//                         Padding(
//                           padding: EdgeInsets.only(
//                             top: MediaQuery.of(context).padding.top + 16,
//                             left: 24,
//                             right: 24,
//                           ),
//                           child: Opacity(
//                             opacity: opacity,
//                             child: OverflowBox(
//                               maxHeight: double.infinity,
//                               alignment: Alignment.topCenter,
//                               child: Builder(
//                                 builder: (context) {
//                                   // Get current banner brilliance
//                                   final int currentIndex =
//                                       _bannerController.hasClients
//                                       ? _bannerController.page?.round() ?? 0
//                                       : 0;
//                                   final bool isDarkBanner =
//                                       banners.isNotEmpty &&
//                                           banners.length > currentIndex
//                                       ? banners[currentIndex].isDark
//                                       : false;
//                                   final Color textColor = isDarkBanner
//                                       ? Colors.white
//                                       : AppColors.grey900;
//                                   final Color subTextColor = isDarkBanner
//                                       ? Colors.white70
//                                       : AppColors.grey500;

//                                   return Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           // Profile Info
//                                           Row(
//                                             children: [
//                                               Container(
//                                                 decoration: BoxDecoration(
//                                                   shape: BoxShape.circle,
//                                                   border: Border.all(
//                                                     color: textColor.withValues(
//                                                       alpha: 0.8,
//                                                     ),
//                                                     width: 2,
//                                                   ),
//                                                 ),
//                                                 child: CircleAvatar(
//                                                   radius: 20,
//                                                   backgroundColor: Colors.white,
//                                                   backgroundImage:
//                                                       user?.avatar != null
//                                                       ? NetworkImage(
//                                                           user!.avatar!,
//                                                         )
//                                                       : null,
//                                                   child: user?.avatar == null
//                                                       ? Text(
//                                                           user
//                                                                       ?.fullName
//                                                                       ?.isNotEmpty ==
//                                                                   true
//                                                               ? user!
//                                                                     .fullName![0]
//                                                                     .toUpperCase()
//                                                               : 'U',
//                                                           style:
//                                                               const TextStyle(
//                                                                 color: AppColors
//                                                                     .grey900,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .bold,
//                                                                 fontSize: 18,
//                                                               ),
//                                                         )
//                                                       : null,
//                                                 ),
//                                               ),
//                                               const SizedBox(width: 12),
//                                               Column(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 mainAxisSize: MainAxisSize.min,
//                                                 children: [
//                                                   Text(
//                                                     'Hi, ${user?.fullName ?? 'Guest'}',
//                                                     style: TextStyle(
//                                                       color: textColor,
//                                                       fontSize: 18,
//                                                       fontWeight:
//                                                           FontWeight.w700,
//                                                       letterSpacing: 0.5,
//                                                     ),
//                                                   ),
//                                                   const SizedBox(height: 2),
//                                                   Consumer<LocationProvider>(
//                                                     builder: (context, loc, _) {
//                                                       final addr = loc.addressFull.isNotEmpty
//                                                           ? loc.addressFull
//                                                           : _getFormattedAddress(user?.address);
//                                                       return Row(
//                                                         children: [
//                                                           Icon(
//                                                             Icons.location_on_rounded,
//                                                             color: subTextColor,
//                                                             size: 12,
//                                                           ),
//                                                           const SizedBox(width: 4),
//                                                           SizedBox(
//                                                             width: 180,
//                                                             child: Text(
//                                                               addr,
//                                                               style: TextStyle(
//                                                                 color: subTextColor,
//                                                                 fontSize: 12,
//                                                                 fontWeight: FontWeight.w500,
//                                                               ),
//                                                               maxLines: 1,
//                                                               overflow: TextOverflow.ellipsis,
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       );
//                                                     },
//                                                   ),
//                                                 ],
//                                               ),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   );
//                                 },
//                               ),
//                             ),
//                           ),
//                         ),
//                         // Search Bar is positioned outside this stack in main build
//                         // Floating Search Bar sticking to bottom
//                         Positioned(
//                           bottom: -28,
//                           left: 24,
//                           right: 24,
//                           child: GestureDetector(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => const SearchScreen(),
//                                 ),
//                               );
//                             },
//                             child: Container(
//                               height: 56,
//                               decoration: BoxDecoration(
//                                 color:
//                                     Theme.of(context).brightness ==
//                                         Brightness.dark
//                                     ? AppColors.grey800
//                                     : Colors.white,
//                                 borderRadius: BorderRadius.circular(10),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.black.withValues(alpha: 0.08),
//                                     blurRadius: 16,
//                                     offset: const Offset(0, 4),
//                                   ),
//                                 ],
//                               ),
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 20,
//                               ),
//                               child: const Row(
//                                 children: [
//                                   Icon(
//                                     Icons.search_rounded,
//                                     color: AppColors.grey400,
//                                     size: 24,
//                                   ),
//                                   SizedBox(width: 12),
//                                   _AnimatedSearchHint(),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),

//               // Spacer to account for the overlapping search bar when scrolling content
//               const SliverToBoxAdapter(child: SizedBox(height: 40)),

//               // CATEGORIES GRID
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
//                   child: isLoading
//                       ? _buildCategoryGridSkeleton()
//                       : _buildCategoryGrid(context, mainCategories),
//                 ),
//               ),

//               // POPULAR SERVICES HEADER
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
//                   child: const Text(
//                     'Popular Services',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//                   ),
//                 ),
//               ),

//               // POPULAR SERVICES GRID (Part 1)
//               SliverPadding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 sliver: isLoading
//                     ? SliverGrid(
//                         gridDelegate:
//                             const SliverGridDelegateWithFixedCrossAxisCount(
//                               crossAxisCount: 2,
//                               mainAxisSpacing: 16,
//                               crossAxisSpacing: 16,
//                               childAspectRatio: 0.75,
//                             ),
//                         delegate: SliverChildBuilderDelegate(
//                           (context, index) => _buildServiceGridSkeleton(),
//                           childCount: 4,
//                         ),
//                       )
//                     : SliverGrid(
//                         gridDelegate:
//                             const SliverGridDelegateWithFixedCrossAxisCount(
//                               crossAxisCount: 2,
//                               mainAxisSpacing: 16,
//                               crossAxisSpacing: 16,
//                               childAspectRatio: 0.72,
//                             ),
//                         delegate: SliverChildBuilderDelegate((context, index) {
//                           final service = popularServices[index];
//                           return _buildServiceGridCard(
//                             context: context,
//                             service: service,
//                           );
//                         }, childCount: popularServices.length > 4 ? 4 : popularServices.length),
//                       ),
//               ),

//               // FEATURED PRODUCTS HEADER
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       const Text(
//                         'Featured Products',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       GestureDetector(
//                         onTap: () {},
//                         child: Text(
//                           'See All',
//                           style: TextStyle(
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                             color: AppColors.primary,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               // FEATURED PRODUCTS HORIZONTAL SCROLL
//               SliverToBoxAdapter(
//                 child: SizedBox(
//                   height: 210,
//                   child: _productsLoading
//                       ? _buildProductsShimmer()
//                       : _featuredProducts.isEmpty
//                           ? const SizedBox.shrink()
//                           : ListView.builder(
//                               scrollDirection: Axis.horizontal,
//                               physics: const BouncingScrollPhysics(),
//                               padding: const EdgeInsets.symmetric(horizontal: 20),
//                               itemCount: _featuredProducts.length,
//                               itemBuilder: (context, index) {
//                                 return _FeaturedProductCard(
//                                   product: _featuredProducts[index],
//                                 );
//                               },
//                             ),
//                 ),
//               ),

//               // OFFERS FOR YOU
//               SliverToBoxAdapter(
//                 child: _OffersForYouSection(
//                   offers: homeProvider.offers,
//                   displayType: homeProvider.offersDisplayType,
//                   isLoading: isLoading,
//                 ),
//               ),

//               // FEATURED SERVICES HEADER
//               if (!isLoading && popularServices.length > 4)
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
//                     child: const Text(
//                       'Featured Services',
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//                     ),
//                   ),
//                 ),

//               // FEATURED SERVICES HORIZONTAL SCROLL
//               if (!isLoading && popularServices.length > 4)
//                 SliverToBoxAdapter(
//                   child: SizedBox(
//                     height: 240,
//                     child: ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       physics: const BouncingScrollPhysics(),
//                       padding: const EdgeInsets.symmetric(horizontal: 20),
//                       itemCount: popularServices.length - 4,
//                       itemBuilder: (context, index) {
//                         final service = popularServices[index + 4];
//                         return Container(
//                           width: 170,
//                           margin: const EdgeInsets.only(right: 16),
//                           child: _buildServiceGridCard(
//                             context: context,
//                             service: service,
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),

//               // CUSTOMER REVIEWS
//               if (homeProvider.topReviews.isNotEmpty) ...[
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
//                     child: const Text(
//                       'What Customers Say',
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//                     ),
//                   ),
//                 ),
//                 SliverToBoxAdapter(
//                   child: SizedBox(
//                     height: 145,
//                     child: ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       physics: const BouncingScrollPhysics(),
//                       padding: const EdgeInsets.symmetric(horizontal: 20),
//                       itemCount: homeProvider.topReviews.length,
//                       itemBuilder: (context, index) {
//                         final r = homeProvider.topReviews[index];
//                         final user = r['userId'] as Map<String, dynamic>?;
//                         final profile = user?['profile'] as Map<String, dynamic>?;
//                         final name = profile?['fullName'] as String? ?? 'User';
//                         final rating = (r['ratings']?['overall'] ?? 0).toInt();
//                         final text = r['reviewText'] as String? ?? '';
//                         final service = r['serviceSnapshot']?['serviceName'] as String? ?? '';
//                         return Container(
//                           width: 300,
//                           margin: const EdgeInsets.only(right: 16),
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: AppColors.grey50,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: AppColors.grey200),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   CircleAvatar(
//                                     radius: 16,
//                                     backgroundColor: AppColors.primaryLight.withValues(alpha: 0.4),
//                                     child: Text(
//                                       name.isNotEmpty ? name[0].toUpperCase() : 'U',
//                                       style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
//                                         if (service.isNotEmpty)
//                                           Text(service, style: const TextStyle(fontSize: 11, color: AppColors.grey500), maxLines: 1, overflow: TextOverflow.ellipsis),
//                                       ],
//                                     ),
//                                   ),
//                                   Row(
//                                     children: List.generate(5, (i) => Icon(
//                                       i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
//                                       color: Colors.amber, size: 12,
//                                     )),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 10),
//                               Text(
//                                 '"$text"',
//                                 style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic, height: 1.4),
//                                 maxLines: 3,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ],

//               // BRAND FOOTER (Swiggy / Zomato style)
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'hirebuddy',
//                         textAlign: TextAlign.left,
//                         style: TextStyle(
//                           fontSize: 64,
//                           fontWeight: FontWeight.w900,
//                           letterSpacing: -2.5,
//                           height: 1,
//                           color: AppColors.primary.withValues(alpha: 0.08),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Trusted help, right at your doorstep.',
//                         textAlign: TextAlign.left,
//                         style: TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w500,
//                           letterSpacing: 0.3,
//                           color: AppColors.primary.withValues(alpha: 0.25),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SliverToBoxAdapter(child: SizedBox(height: 24)),
//             ],
//           ),
//         ),

//             // ── FLOATING CART PILL ──────────────────────────────────
//             Positioned(
//               bottom: bottomPad + 10,
//               left: 0,
//               right: 0,
//               child: Center(
//                 child: AnimatedSlide(
//                   duration: const Duration(milliseconds: 350),
//                   curve: Curves.easeOutBack,
//                   offset: cart.totalItems > 0
//                       ? Offset.zero
//                       : const Offset(0, 2.5),
//                   child: AnimatedOpacity(
//                     duration: const Duration(milliseconds: 200),
//                     opacity: cart.totalItems > 0 ? 1.0 : 0.0,
//                     child: GestureDetector(
//                       onTap: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const CartScreen()),
//                       ),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 20, vertical: 14),
//                         decoration: BoxDecoration(
//                           color: AppColors.textPrimary,
//                           borderRadius: BorderRadius.circular(50),                        ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               width: 22,
//                               height: 22,
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withValues(alpha: 0.18),
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   '${cart.totalItems}',
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 11,
//                                     fontWeight: FontWeight.w800,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             const Text(
//                               'View Cart',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                             const SizedBox(width: 10),
//                             Container(
//                               width: 1,
//                               height: 14,
//                               color: Colors.white.withValues(alpha: 0.25),
//                             ),
//                             const SizedBox(width: 10),
//                             Text(
//                               '₹${cart.totalAmount.toStringAsFixed(0)}',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w900,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   IconData _getCategoryIcon(String categoryName) {
//     final name = categoryName.toLowerCase();
//     if (name.contains('clean')) return Icons.cleaning_services_rounded;
//     if (name.contains('plumb')) return Icons.plumbing_rounded;
//     if (name.contains('electric')) return Icons.electrical_services_rounded;
//     if (name.contains('ac') || name.contains('air')) {
//       return Icons.ac_unit_rounded;
//     }
//     if (name.contains('paint')) return Icons.format_paint_rounded;
//     if (name.contains('pest')) return Icons.bug_report_rounded;
//     if (name.contains('carpen')) return Icons.handyman_rounded;
//     if (name.contains('appliance')) return Icons.kitchen_rounded;
//     if (name.contains('beauty')) return Icons.face_rounded;
//     return Icons.home_repair_service_rounded;
//   }

//   Widget _buildCategoryGrid(BuildContext context, List<dynamic> categories) {
//     final display = categories.take(7).toList();
//     final screenWidth = MediaQuery.of(context).size.width;
//     final itemWidth = (screenWidth - 40 - 3 * 14) / 4;

//     return Wrap(
//       spacing: 14,
//       runSpacing: 14,
//       children: [
//         ...display.map((cat) => _buildCategoryGridItem(context, cat, itemWidth)),
//         _buildAllServicesItem(context, itemWidth),
//       ],
//     );
//   }

//   Widget _buildCategoryGridItem(BuildContext context, dynamic category, double w) {
//     final name = category.categoryName as String;
//     final iconUrl = category.icon as String?;
//     final categoryId = category.id as String;
//     final cardH = w * 0.82;

//     return GestureDetector(
//       onTap: () => Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => CategoryServicesScreen(
//             categoryName: name,
//             categoryId: categoryId,
//           ),
//         ),
//       ),
//       child: SizedBox(
//         width: w,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Container(
//               width: w,
//               height: cardH,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF0F0F0),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               clipBehavior: Clip.antiAlias,
//               child: iconUrl != null && iconUrl.startsWith('http')
//                   ? Image.network(
//                       iconUrl,
//                       fit: BoxFit.contain,
//                       errorBuilder: (_, e, s) => Center(
//                         child: Icon(_getCategoryIcon(name), color: const Color(0xFF444444), size: w * 0.42),
//                       ),
//                     )
//                   : Center(
//                       child: Icon(_getCategoryIcon(name), color: const Color(0xFF444444), size: w * 0.42),
//                     ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               name.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' '),
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontSize: 12.5,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF1A1A1A),
//                 height: 1.4,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAllServicesItem(BuildContext context, double w) {
//     final cardH = w * 0.82;
//     return GestureDetector(
//       onTap: () {
//         final allCats = Provider.of<HomeProvider>(context, listen: false).allCategories;
//         showModalBottomSheet(
//           context: context,
//           isScrollControlled: true,
//           useSafeArea: true,
//           backgroundColor: Colors.transparent,
//           builder: (_) => AllServicesSheet(allCategories: allCats),
//         );
//       },
//       child: SizedBox(
//         width: w,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Container(
//               width: w,
//               height: cardH,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF0F0F0),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: List.generate(3, (row) => Padding(
//                     padding: EdgeInsets.only(bottom: row < 2 ? 6 : 0),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: List.generate(3, (col) => Container(
//                         width: 6,
//                         height: 6,
//                         margin: const EdgeInsets.symmetric(horizontal: 3),
//                         decoration: const BoxDecoration(
//                           color: Color(0xFF333333),
//                           shape: BoxShape.circle,
//                         ),
//                       )),
//                     ),
//                   )),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'All services',
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               style: TextStyle(
//                 fontSize: 12.5,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF1A1A1A),
//                 height: 1.4,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildServiceGridCard({
//     required BuildContext context,
//     required ServiceModel service,
//   }) {
//     final imageUrl = service.primaryImageUrl;
//     final price = service.pricing?.retailPrice ?? 0;

//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ServiceDetailScreen(
//               serviceId: service.id,
//               heroTag: imageUrl ?? service.id,
//             ),
//           ),
//         );
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: AppColors.grey200, width: 1),
//         ),
//         clipBehavior: Clip.antiAlias,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Image Section
//             Expanded(
//               flex: 5,
//               child: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   Hero(
//                     tag: imageUrl ?? service.id,
//                     child: imageUrl != null && imageUrl.startsWith('http')
//                         ? Image.network(
//                             imageUrl,
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stackTrace) =>
//                                 Container(
//                                   color: AppColors.grey100,
//                                   child: const Icon(
//                                     Icons.image_not_supported,
//                                     color: AppColors.grey400,
//                                   ),
//                                 ),
//                           )
//                         : Container(
//                             color: AppColors.grey100,
//                             child: const Icon(
//                               Icons.home_repair_service,
//                               color: AppColors.grey400,
//                             ),
//                           ),
//                   ),

//                 ],
//               ),
//             ),
//             // Info Section
//             Expanded(
//               flex: 4,
//               child: Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       service.serviceName.toTitleCase(),
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.textPrimary,
//                         height: 1.2,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Starts at',
//                               style: TextStyle(
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.w600,
//                                 color: AppColors.grey500,
//                               ),
//                             ),
//                             Text(
//                               '₹${price.toStringAsFixed(0)}',
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w900,
//                                 color: AppColors.textPrimary,
//                               ),
//                             ),
//                           ],
//                         ),
//                         Container(
//                           padding: const EdgeInsets.all(6),
//                           decoration: const BoxDecoration(
//                             color: Colors.black,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(
//                             Icons.arrow_forward_rounded,
//                             color: Colors.white,
//                             size: 14,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCategoryGridSkeleton() {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final w = (constraints.maxWidth - 3 * 14) / 4;
//         return Wrap(
//           spacing: 14,
//           runSpacing: 20,
//           children: List.generate(8, (_) => SizedBox(
//             width: w,
//             child: Column(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(20),
//                   child: SizedBox(width: w, height: w * 0.82, child: _ShimmerWidget()),
//                 ),
//                 const SizedBox(height: 8),
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(4),
//                   child: Container(height: 10, width: w * 0.7, color: AppColors.grey100),
//                 ),
//               ],
//             ),
//           )),
//         );
//       },
//     );
//   }

//   Widget _buildServiceGridSkeleton() {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.grey50,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: AppColors.grey100),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             flex: 5,
//             child: ClipRRect(
//               borderRadius: const BorderRadius.vertical(
//                 top: Radius.circular(20),
//               ),
//               child: _ShimmerWidget(),
//             ),
//           ),
//           Expanded(
//             flex: 4,
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Container(
//                     width: double.infinity,
//                     height: 12,
//                     decoration: BoxDecoration(
//                       color: AppColors.grey100,
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                   ),
//                   Container(
//                     width: 60,
//                     height: 12,
//                     decoration: BoxDecoration(
//                       color: AppColors.grey100,
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Container(
//                         width: 50,
//                         height: 20,
//                         decoration: BoxDecoration(
//                           color: AppColors.grey100,
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                       ),
//                       Container(
//                         width: 24,
//                         height: 24,
//                         decoration: const BoxDecoration(
//                           color: AppColors.grey100,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProductsShimmer() {
//     return ListView.builder(
//       scrollDirection: Axis.horizontal,
//       physics: const NeverScrollableScrollPhysics(),
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       itemCount: 4,
//       itemBuilder: (_, i) => Container(
//         width: 140,
//         margin: const EdgeInsets.only(right: 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: AppColors.grey100),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(16),
//           child: _ShimmerWidget(),
//         ),
//       ),
//     );
//   }

//   Color _hexToColor(String hexString) {
//     var hex = hexString.replaceAll('#', '');
//     if (hex.length == 6) hex = 'FF$hex';
//     return Color(int.parse(hex, radix: 16));
//   }
// }

// // ─────────────────────────── FEATURED PRODUCT CARD ───────────────────────────

// class _FeaturedProductCard extends StatelessWidget {
//   final ProductModel product;
//   const _FeaturedProductCard({required this.product});

//   @override
//   Widget build(BuildContext context) {
//     final cart = context.watch<CartProvider>();
//     final isAuth = context.read<AuthProvider>().isAuthenticated;
//     final qty = cart.quantityOf(product.id);
//     final isOutOfStock = product.stock == 0;

//     void guardedAddToCart() {
//       if (!isAuth) {
//         Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
//         return;
//       }
//       final success = cart.addItem(product);
//       if (!success) {
//         showDialog(
//           context: context,
//           builder: (ctx) => AlertDialog(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             title: const Text('Replace cart?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
//             content: const Text('Your cart has items from another vendor. Start a new cart?'),
//             actions: [
//               TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
//                 onPressed: () { cart.clearCart(); cart.addItem(product); Navigator.pop(ctx); },
//                 child: const Text('Replace', style: TextStyle(color: Colors.white)),
//               ),
//             ],
//           ),
//         );
//       }
//     }

//     return GestureDetector(
//       onTap: () => Navigator.push(
//         context,
//         PageRouteBuilder(
//           pageBuilder: (_, anim, a) => ProductDetailScreen(product: product),
//           transitionsBuilder: (_, anim, a, child) =>
//               FadeTransition(opacity: anim, child: child),
//           transitionDuration: const Duration(milliseconds: 350),
//         ),
//       ),
//       child: Container(
//         width: 140,
//         margin: const EdgeInsets.only(right: 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: AppColors.grey100),        ),
//         clipBehavior: Clip.antiAlias,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Image
//             Hero(
//               tag: 'product-img-${product.id}',
//               child: Container(
//                 height: 120,
//                 color: AppColors.grey50,
//                 child: Stack(
//                   children: [
//                     SizedBox(
//                       width: double.infinity,
//                       height: double.infinity,
//                       child: product.primaryImage.isNotEmpty
//                           ? Image.network(
//                               product.primaryImage,
//                               fit: BoxFit.contain,
//                               errorBuilder: (_, e, s) => const Center(
//                                 child: Icon(Icons.inventory_2_outlined,
//                                     color: AppColors.grey300, size: 32),
//                               ),
//                             )
//                           : const Center(
//                               child: Icon(Icons.inventory_2_outlined,
//                                   color: AppColors.grey300, size: 32),
//                             ),
//                     ),
//                     if (isOutOfStock)
//                       Positioned.fill(
//                         child: Container(
//                           color: Colors.black.withValues(alpha: 0.4),
//                           child: const Center(
//                             child: Text(
//                               'Out of\nStock',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w800,
//                                 height: 1.2,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),

//             // Info
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       product.productName.toTitleCase(),
//                       style: const TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.textPrimary,
//                         height: 1.2,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Text(
//                           '₹${product.pricing.finalPrice.toStringAsFixed(0)}',
//                           style: const TextStyle(
//                             fontSize: 13,
//                             fontWeight: FontWeight.w900,
//                             color: AppColors.textPrimary,
//                           ),
//                         ),
//                         if (!isOutOfStock)
//                           qty == 0
//                               ? _FeaturedAddBtn(onTap: guardedAddToCart)
//                               : _FeaturedQtyControl(
//                                   qty: qty,
//                                   onDec: () => cart.decreaseQuantity(product.id),
//                                   onInc: guardedAddToCart,
//                                 ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _FeaturedAddBtn extends StatelessWidget {
//   final VoidCallback onTap;
//   const _FeaturedAddBtn({required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 26,
//         height: 26,
//         decoration: BoxDecoration(
//           color: AppColors.primary,
//           borderRadius: BorderRadius.circular(7),
//         ),
//         child: const Icon(Icons.add_rounded, color: Colors.white, size: 15),
//       ),
//     );
//   }
// }

// class _FeaturedQtyControl extends StatelessWidget {
//   final int qty;
//   final VoidCallback onDec;
//   final VoidCallback onInc;
//   const _FeaturedQtyControl(
//       {required this.qty, required this.onDec, required this.onInc});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 26,
//       decoration: BoxDecoration(
//         color: AppColors.primary,
//         borderRadius: BorderRadius.circular(7),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           GestureDetector(
//             onTap: onDec,
//             child: const SizedBox(
//               width: 22,
//               height: 26,
//               child: Icon(Icons.remove_rounded, color: Colors.white, size: 12),
//             ),
//           ),
//           Text(
//             '$qty',
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w800,
//               fontSize: 11,
//             ),
//           ),
//           GestureDetector(
//             onTap: onInc,
//             child: const SizedBox(
//               width: 22,
//               height: 26,
//               child: Icon(Icons.add_rounded, color: Colors.white, size: 12),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────

// class _ShimmerWidget extends StatefulWidget {
//   @override
//   State<_ShimmerWidget> createState() => _ShimmerWidgetState();
// }

// class _ShimmerWidgetState extends State<_ShimmerWidget>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     )..repeat();
//     _animation = Tween<double>(
//       begin: -1.0,
//       end: 2.0,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _animation,
//       builder: (context, child) {
//         return Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 AppColors.grey100,
//                 AppColors.grey200.withValues(alpha: 0.5),
//                 AppColors.grey100,
//               ],
//               stops: [
//                 _animation.value - 0.3,
//                 _animation.value,
//                 _animation.value + 0.3,
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// // -------------------------------------------------------------
// // STICKY HEADER DELEGATE FOR CUSTOM CURVED HERO & SEARCH BAR
// // -------------------------------------------------------------
// class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
//   final double minHeight;
//   final double maxHeight;
//   final Widget Function(
//     BuildContext context,
//     double shrinkOffset,
//     bool overlapsContent,
//     double minExtent,
//     double maxExtent,
//   )
//   builder;

//   _StickyHeaderDelegate({
//     required this.minHeight,
//     required this.maxHeight,
//     required this.builder,
//   });

//   @override
//   double get minExtent => minHeight;

//   @override
//   double get maxExtent => maxHeight;

//   @override
//   Widget build(
//     BuildContext context,
//     double shrinkOffset,
//     bool overlapsContent,
//   ) {
//     return SizedBox.expand(
//       child: builder(
//         context,
//         shrinkOffset,
//         overlapsContent,
//         minExtent,
//         maxExtent,
//       ),
//     );
//   }

//   @override
//   bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
//     return maxHeight != oldDelegate.maxHeight ||
//         minHeight != oldDelegate.minHeight ||
//         builder != oldDelegate.builder;
//   }
// }
// // OFFERS FOR YOU SECTION
// // ----------------------
// class _OffersForYouSection extends StatelessWidget {
//   final List<OfferModel> offers;
//   final String displayType;
//   final bool isLoading;

//   const _OffersForYouSection({
//     required this.offers,
//     required this.displayType,
//     required this.isLoading,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (!isLoading && offers.isEmpty) return const SizedBox.shrink();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Padding(
//           padding: EdgeInsets.fromLTRB(20, 24, 20, 14),
//           child: Text(
//             'Offers for You',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//           ),
//         ),
//         if (isLoading)
//           _buildSkeleton()
//         else if (displayType == 'carousel')
//           _buildCarousel()
//         else
//           _buildGrid(),
//       ],
//     );
//   }

//   Widget _buildSkeleton() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Container(
//         height: 180,
//         decoration: BoxDecoration(
//           color: Colors.grey.shade200,
//           borderRadius: BorderRadius.circular(16),
//         ),
//       ),
//     );
//   }

//   // Carousel: flatten all offer images into one horizontal PageView
//   Widget _buildCarousel() {
//     final allImages = <OfferImage>[];
//     for (final offer in offers) {
//       allImages.addAll(offer.images);
//     }
//     if (allImages.isEmpty) return const SizedBox.shrink();

//     return SizedBox(
//       height: 180,
//       child: PageView.builder(
//         physics: const BouncingScrollPhysics(),
//         padEnds: false,
//         controller: PageController(viewportFraction: 0.92),
//         itemCount: allImages.length,
//         itemBuilder: (context, index) {
//           return Padding(
//             padding: EdgeInsets.only(
//               left: index == 0 ? 20 : 8,
//               right: index == allImages.length - 1 ? 20 : 0,
//             ),
//             child: _OfferImageCard(image: allImages[index]),
//           );
//         },
//       ),
//     );
//   }

//   // Grid: 1 large left + 2 small right
//   Widget _buildGrid() {
//     final images = offers.isNotEmpty ? offers.first.images : <OfferImage>[];
//     final img0 = images.isNotEmpty ? images[0] : null;
//     final img1 = images.length > 1 ? images[1] : null;
//     final img2 = images.length > 2 ? images[2] : null;

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: SizedBox(
//         height: 240,
//         child: Row(
//           children: [
//             Expanded(
//               child: _OfferImageCard(
//                 image: img0,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 children: [
//                   Expanded(
//                     child: _OfferImageCard(
//                       image: img1,
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Expanded(
//                     child: _OfferImageCard(
//                       image: img2,
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _OfferImageCard extends StatelessWidget {
//   final OfferImage? image;
//   final BorderRadius borderRadius;

//   const _OfferImageCard({
//     this.image,
//     this.borderRadius = const BorderRadius.all(Radius.circular(16)),
//   });

//   void _handleTap(BuildContext context) {
//     if (image == null) return;
//     final type = image!.actionType;
//     final value = image!.actionValue;
//     if (type == 'none' || value.isEmpty) return;

//     if (type == 'external') {
//       try {
//         launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication);
//       } catch (_) {}
//     } else if (type == 'internal') {
//       if (value == '/home') return;
//       Widget? screen;
//       if (value == '/shop') {
//         screen = const ShopScreen();
//       } else if (value == '/bookings') {
//         screen = const MyBookingsScreen();
//       } else if (value == '/profile') {
//         screen = const ProfileScreen();
//       }
//       if (screen != null) {
//         Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen!));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final hasAction = image != null &&
//         image!.actionType != 'none' &&
//         image!.actionValue.isNotEmpty;

//     Widget child;
//     if (image == null || image!.url.isEmpty) {
//       child = ClipRRect(
//         borderRadius: borderRadius,
//         child: Container(color: Colors.grey.shade200),
//       );
//     } else {
//       child = ClipRRect(
//         borderRadius: borderRadius,
//         child: Image.network(
//           image!.url,
//           fit: BoxFit.cover,
//           width: double.infinity,
//           height: double.infinity,
//           errorBuilder: (_, e, s) => Container(color: Colors.grey.shade200),
//         ),
//       );
//     }

//     if (!hasAction) return child;

//     return GestureDetector(
//       onTap: () => _handleTap(context),
//       child: child,
//     );
//   }
// }

// class _AnimatedSearchHint extends StatefulWidget {
//   const _AnimatedSearchHint();

//   @override
//   State<_AnimatedSearchHint> createState() => _AnimatedSearchHintState();
// }

// class _AnimatedSearchHintState extends State<_AnimatedSearchHint> {
//   static const _hints = [
//     'AC Servicing',
//     'Home Cleaning',
//     'Plumber',
//     'Electrician',
//     'Pest Control',
//     'Painting',
//     'Chimney Cleaning',
//     'Fan Installation',
//   ];

//   int _index = 0;
//   Timer? _timer;

//   @override
//   void initState() {
//     super.initState();
//     _timer = Timer.periodic(const Duration(seconds: 2), (_) {
//       if (mounted) setState(() => _index = (_index + 1) % _hints.length);
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         const Text(
//           'Search for ',
//           style: TextStyle(
//             color: AppColors.grey400,
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         AnimatedSwitcher(
//           duration: const Duration(milliseconds: 350),
//           transitionBuilder: (child, animation) {
//             final slide = Tween<Offset>(
//               begin: const Offset(0, 0.5),
//               end: Offset.zero,
//             ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
//             return FadeTransition(
//               opacity: animation,
//               child: SlideTransition(position: slide, child: child),
//             );
//           },
//           child: Text(
//             '"${_hints[_index]}"',
//             key: ValueKey(_index),
//             style: const TextStyle(
//               color: AppColors.grey400,
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
