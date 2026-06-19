// import 'package:flutter/material.dart';
// import '../../models/category_model.dart';
// import '../category/category_services_screen.dart';

// class AllServicesSheet extends StatelessWidget {
//   final List<CategoryModel> allCategories;

//   const AllServicesSheet({super.key, required this.allCategories});

//   String _titleCase(String s) => s
//       .split(' ')
//       .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
//       .join(' ');

//   @override
//   Widget build(BuildContext context) {
//     final parents = allCategories
//         .where((c) => c.parentCategoryId == null)
//         .toList()
//       ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

//     return DraggableScrollableSheet(
//       initialChildSize: 0.82,
//       minChildSize: 0.5,
//       maxChildSize: 0.88,
//       expand: false,
//       builder: (context, scrollController) {
//         final navBarHeight = MediaQuery.of(context).viewPadding.bottom;
//         return Stack(
//           clipBehavior: Clip.none,
//           children: [
//             // Close button — floats above the sheet
//             Positioned(
//               top: -48,
//               right: 16,
//               child: GestureDetector(
//                 onTap: () => Navigator.pop(context),
//                 child: Container(
//                   width: 36,
//                   height: 36,
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(Icons.close_rounded, size: 20, color: Colors.black87),
//                 ),
//               ),
//             ),

//             Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//               ),
//               child: Column(
//                 children: [
//                   const SizedBox(height: 16),

//               // Scrollable content
//               Expanded(
//                 child: ListView.separated(
//                   controller: scrollController,
//                   padding: EdgeInsets.fromLTRB(20, 8, 20, 32 + navBarHeight),
//                   itemCount: parents.length,
//                   separatorBuilder: (_, i) => const Divider(height: 32, color: Color(0xFFF0F0F0), thickness: 1),
//                   itemBuilder: (context, i) {
//                     final parent = parents[i];
//                     final subs = allCategories
//                         .where((c) => c.parentCategoryId == parent.id)
//                         .toList()
//                       ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

//                     return _CategorySection(
//                       parent: parent,
//                       subCategories: subs,
//                       titleCase: _titleCase,
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//           ],
//         );
//       },
//     );
//   }
// }

// class _CategorySection extends StatelessWidget {
//   final CategoryModel parent;
//   final List<CategoryModel> subCategories;
//   final String Function(String) titleCase;

//   const _CategorySection({
//     required this.parent,
//     required this.subCategories,
//     required this.titleCase,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final itemWidth = (MediaQuery.of(context).size.width - 40 - 3 * 14) / 4;
//     final cardH = itemWidth * 0.82;

//     // If no sub-categories, show parent itself as a single item
//     final items = subCategories.isEmpty ? [parent] : subCategories;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           titleCase(parent.categoryName),
//           style: const TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w800,
//             color: Color(0xFF1A1A1A),
//             height: 1.2,
//           ),
//         ),
//         const SizedBox(height: 16),
//         Wrap(
//           spacing: 14,
//           runSpacing: 16,
//           children: items.map((cat) {
//             final iconUrl = cat.icon;
//             return GestureDetector(
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => CategoryServicesScreen(
//                       categoryName: cat.categoryName,
//                       categoryId: cat.id,
//                     ),
//                   ),
//                 );
//               },
//               child: SizedBox(
//                 width: itemWidth,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Container(
//                       width: itemWidth,
//                       height: cardH,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFF0F0F0),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       clipBehavior: Clip.antiAlias,
//                       child: iconUrl != null && iconUrl.startsWith('http')
//                           ? Image.network(
//                               iconUrl,
//                               fit: BoxFit.contain,
//                               errorBuilder: (_, e, s) => const _FallbackIcon(),
//                             )
//                           : const _FallbackIcon(),
//                     ),
//                     const SizedBox(height: 7),
//                     Text(
//                       titleCase(cat.categoryName),
//                       textAlign: TextAlign.center,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                         color: Color(0xFF1A1A1A),
//                         height: 1.35,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }
// }

// class _FallbackIcon extends StatelessWidget {
//   const _FallbackIcon();

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Icon(Icons.home_repair_service_rounded, color: Color(0xFF888888), size: 28),
//     );
//   }
// }
