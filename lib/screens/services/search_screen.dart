// import 'dart:async';
// import 'package:flutter/material.dart';
// import '../../core/theme/app_colors.dart';
// import '../../models/service_model.dart';
// import '../../models/product_model.dart';
// import '../../services/service_service.dart';
// import '../../services/product_service.dart';
// import '../service/service_detail_screen.dart';
// import '../shop/product_detail_screen.dart';

// class SearchScreen extends StatefulWidget {
//   const SearchScreen({super.key});

//   @override
//   State<SearchScreen> createState() => _SearchScreenState();
// }

// class _SearchScreenState extends State<SearchScreen> {
//   final ServiceService _serviceService = ServiceService();
//   final ProductService _productService = ProductService();
//   final TextEditingController _searchController = TextEditingController();
//   final FocusNode _focusNode = FocusNode();

//   List<ServiceModel> _services = [];
//   List<ProductModel> _products = [];
//   List<ServiceModel> _popularServices = [];
//   bool _isSearching = false;
//   bool _hasSearched = false;
//   Timer? _debounce;

//   @override
//   void initState() {
//     super.initState();
//     _loadPopular();
//     _focusNode.requestFocus();
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _searchController.dispose();
//     _focusNode.dispose();
//     super.dispose();
//   }

//   Future<void> _loadPopular() async {
//     final result = await _serviceService.getServices();
//     if (result['success'] == true && mounted) {
//       final data = result['data']['data'] as List? ?? [];
//       setState(() {
//         _popularServices = data
//             .take(6)
//             .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
//             .toList();
//       });
//     }
//   }

//   void _onSearchChanged(String query) {
//     _debounce?.cancel();
//     if (query.trim().isEmpty) {
//       setState(() {
//         _services = [];
//         _products = [];
//         _hasSearched = false;
//         _isSearching = false;
//       });
//       return;
//     }
//     setState(() => _isSearching = true);
//     _debounce = Timer(
//       const Duration(milliseconds: 400),
//       () => _search(query.trim()),
//     );
//   }

//   Future<void> _search(String query) async {
//     List<ServiceModel> services = [];
//     List<ProductModel> products = [];

//     await Future.wait([
//       _serviceService.getServices(search: query).then((result) {
//         if (result['success'] == true) {
//           services = (result['data']['data'] as List? ?? [])
//               .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
//               .toList();
//         }
//       }),
//       _productService.listProducts(search: query).then((list) {
//         products = list;
//       }),
//     ]);

//     if (!mounted) return;
//     setState(() {
//       _services = services;
//       _products = products;
//       _isSearching = false;
//       _hasSearched = true;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildHeader(),
//             Expanded(child: _buildBody()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
//       color: Colors.white,
//       child: Row(
//         children: [
//           IconButton(
//             onPressed: () => Navigator.pop(context),
//             icon: const Icon(
//               Icons.arrow_back_ios_new_rounded,
//               color: Colors.black,
//               size: 22,
//             ),
//           ),
//           const SizedBox(width: 4),
//           Expanded(
//             child: Container(
//               height: 54,
//               decoration: BoxDecoration(color: Colors.grey[100]),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _searchController,
//                       focusNode: _focusNode,
//                       onChanged: _onSearchChanged,
//                       decoration: const InputDecoration(
//                         hintText: 'Search services & products...',
//                         border: InputBorder.none,
//                         enabledBorder: InputBorder.none,
//                         focusedBorder: InputBorder.none,
//                         hintStyle: TextStyle(
//                           color: Colors.grey,
//                           fontSize: 15,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       style: const TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w800,
//                         color: AppColors.textPrimary,
//                       ),
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: _searchController.text.isNotEmpty
//                         ? () {
//                             _searchController.clear();
//                             _onSearchChanged('');
//                           }
//                         : null,
//                     child: Icon(
//                       _searchController.text.isEmpty
//                           ? Icons.search_rounded
//                           : Icons.close_rounded,
//                       color: Colors.grey,
//                       size: _searchController.text.isEmpty ? 20 : 22,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBody() {
//     if (_isSearching) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (!_hasSearched) {
//       return _buildSuggestions();
//     }

//     final hasResults = _services.isNotEmpty || _products.isNotEmpty;
//     if (!hasResults) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.manage_search_rounded, size: 60, color: Colors.grey[200]),
//             const SizedBox(height: 16),
//             const Text(
//               'No results found',
//               style: TextStyle(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               'Try a different keyword',
//               style: TextStyle(fontSize: 13, color: Colors.grey[400]),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//       children: [
//         if (_services.isNotEmpty) ...[
//           _buildSectionHeader('Services', _services.length),
//           ..._services.map(_buildServiceCard),
//         ],
//         if (_products.isNotEmpty) ...[
//           _buildSectionHeader('Products', _products.length),
//           ..._products.map(_buildProductCard),
//         ],
//         const SizedBox(height: 24),
//       ],
//     );
//   }

//   Widget _buildSuggestions() {
//     if (_popularServices.isEmpty) {
//       return const SizedBox.shrink();
//     }
//     return Padding(
//       padding: const EdgeInsets.all(28.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'TRENDING SEARCHES',
//             style: TextStyle(
//               fontSize: 11,
//               fontWeight: FontWeight.w900,
//               color: Colors.grey,
//               letterSpacing: 1.0,
//             ),
//           ),
//           const SizedBox(height: 20),
//           Wrap(
//             spacing: 12,
//             runSpacing: 14,
//             children: _popularServices
//                 .map((s) => _buildSuggestionChip(s.serviceName))
//                 .toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSuggestionChip(String label) {
//     return GestureDetector(
//       onTap: () {
//         _searchController.text = label;
//         _onSearchChanged(label);
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.grey[50],
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Text(
//           label,
//           style: const TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w800,
//             color: AppColors.textPrimary,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title, int count) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 16, bottom: 12),
//       child: Row(
//         children: [
//           Text(
//             title.toUpperCase(),
//             style: const TextStyle(
//               fontSize: 11,
//               fontWeight: FontWeight.w900,
//               color: Colors.grey,
//               letterSpacing: 1.0,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Text(
//               '$count',
//               style: const TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w800,
//                 color: Colors.grey,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildServiceCard(ServiceModel service) {
//     final imageUrl = service.primaryImageUrl;
//     return GestureDetector(
//       onTap: () => Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (_) => ServiceDetailScreen(
//             serviceId: service.id,
//             heroTag: 'search_${service.id}',
//           ),
//         ),
//       ),
//       child: _buildResultCard(
//         imageWidget: imageUrl != null
//             ? Image.network(imageUrl, fit: BoxFit.cover)
//             : const Icon(Icons.home_repair_service, color: Colors.grey),
//         title: service.serviceName,
//         subtitle: '₹${(service.pricing?.basePrice ?? 0).toStringAsFixed(0)} onwards',
//         badgeLabel: 'Service',
//         badgeColor: AppColors.primary,
//       ),
//     );
//   }

//   Widget _buildProductCard(ProductModel product) {
//     final imageUrl = product.primaryImage.isNotEmpty ? product.primaryImage : null;
//     final price = product.pricing.finalPrice > 0
//         ? product.pricing.finalPrice
//         : product.pricing.basePrice;
//     return GestureDetector(
//       onTap: () => Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (_) => ProductDetailScreen(product: product),
//         ),
//       ),
//       child: _buildResultCard(
//         imageWidget: imageUrl != null
//             ? Image.network(imageUrl, fit: BoxFit.cover)
//             : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
//         title: product.productName,
//         subtitle: '₹${price.toStringAsFixed(0)}',
//         badgeLabel: 'Product',
//         badgeColor: Colors.orange,
//       ),
//     );
//   }

//   Widget _buildResultCard({
//     required Widget imageWidget,
//     required String title,
//     required String subtitle,
//     required String badgeLabel,
//     required Color badgeColor,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: Colors.grey.shade100),
//       ),
//       child: Row(
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(16),
//             child: Container(
//               width: 72,
//               height: 72,
//               color: Colors.grey[50],
//               child: imageWidget,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 7, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: badgeColor.withValues(alpha: 0.1),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Text(
//                         badgeLabel,
//                         style: TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.w800,
//                           color: badgeColor,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w900,
//                     color: AppColors.textPrimary,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w800,
//                     color: badgeColor,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.grey[50],
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.arrow_forward_ios_rounded,
//               size: 12,
//               color: Colors.grey,
//             ),
//           ),
//           const SizedBox(width: 4),
//         ],
//       ),
//     );
//   }
// }
