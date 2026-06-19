// import 'package:flutter/material.dart';
// import 'package:hirebuddy/core/theme/app_colors.dart';
// import 'package:hirebuddy/services/booking_service.dart';
// import 'package:hirebuddy/models/booking_model.dart';
// import 'package:intl/intl.dart';
// import 'booking_details_screen.dart';
// import '../shop/my_orders_screen.dart';

// class MyBookingsScreen extends StatefulWidget {
//   const MyBookingsScreen({super.key});

//   @override
//   State<MyBookingsScreen> createState() => _MyBookingsScreenState();
// }

// class _MyBookingsScreenState extends State<MyBookingsScreen>
//     with SingleTickerProviderStateMixin {
//   final BookingService _bookingService = BookingService();
//   late TabController _tabController;

//   List<BookingModel> _allBookings = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _loadBookings();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadBookings() async {
//     setState(() => _isLoading = true);
//     try {
//       final result = await _bookingService.getMyBookings();
//       if (result['success'] && mounted) {
//         setState(() {
//           _allBookings = (result['data']['data'] as List)
//               .map((json) => BookingModel.fromJson(json))
//               .toList();
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading bookings: $e');
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   List<BookingModel> get _activeBookings {
//     return _allBookings.where((b) {
//       return ![
//         'work_completed',
//         'cancelled_by_user',
//         'cancelled_by_provider',
//         'failed',
//       ].contains(b.bookingStatus);
//     }).toList();
//   }

//   List<BookingModel> get _completedBookings {
//     return _allBookings
//         .where((b) => b.bookingStatus == 'work_completed')
//         .toList();
//   }

//   List<BookingModel> get _cancelledBookings {
//     return _allBookings.where((b) {
//       return [
//         'cancelled_by_user',
//         'cancelled_by_provider',
//         'failed',
//       ].contains(b.bookingStatus);
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text(
//           'My Bookings',
//           style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: false,
//       ),
//       body: Column(
//         children: [
//           // Floating Chips Toggle Style
//           Container(
//             color: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             child: Row(
//               children: [
//                 _buildFloatingChip(0, 'Active'),
//                 const SizedBox(width: 12),
//                 _buildFloatingChip(1, 'History'),
//                 const SizedBox(width: 12),
//                 _buildFloatingChip(2, 'Cancelled'),
//               ],
//             ),
//           ),
//           // My Orders banner
//           GestureDetector(
//             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
//             child: Container(
//               margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF10B981).withValues(alpha: 0.07),
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
//               ),
//               child: const Row(
//                 children: [
//                   Icon(Icons.shopping_bag_outlined, color: Color(0xFF10B981), size: 20),
//                   SizedBox(width: 10),
//                   Expanded(
//                     child: Text(
//                       'My Purchases',
//                       style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
//                     ),
//                   ),
//                   Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF10B981)),
//                 ],
//               ),
//             ),
//           ),
//           // Content
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : TabBarView(
//                     controller: _tabController,
//                     children: [
//                       _buildBookingsList(_activeBookings),
//                       _buildBookingsList(_completedBookings),
//                       _buildBookingsList(_cancelledBookings),
//                     ],
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBookingsList(List<BookingModel> bookings) {
//     if (bookings.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[200]),
//             const SizedBox(height: 16),
//             const Text(
//               'No active bookings yet',
//               style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey),
//             ),
//           ],
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: _loadBookings,
//       child: ListView.builder(
//         padding: const EdgeInsets.all(20),
//         itemCount: bookings.length,
//         itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
//       ),
//     );
//   }

//   Widget _buildBookingCard(BookingModel booking) {
//     final imageUrl = booking.serviceId?.primaryImageUrl;

//     return GestureDetector(
//       onTap: () {
//         Navigator.of(context).push(
//           MaterialPageRoute(builder: (context) => BookingDetailsScreen(bookingId: booking.id)),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 24),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(28),
//           border: Border.all(color: AppColors.grey200, width: 1),
//         ),
//         child: Column(
//           children: [
//             // Image Section with Top-Rounded Corners
//             Stack(
//               children: [
//                 ClipRRect(
//                   borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
//                   child: Container(
//                     height: 130,
//                     width: double.infinity,
//                     color: Colors.grey[100],
//                     child: imageUrl != null && imageUrl.startsWith('http')
//                         ? Image.network(imageUrl, fit: BoxFit.cover)
//                         : const Icon(Icons.home_repair_service, size: 40, color: Colors.grey),
//                   ),
//                 ),
//                 Positioned(
//                   top: 16,
//                   right: 16,
//                   child: _buildModernStatusBadge(booking.bookingStatus),
//                 ),
//               ],
//             ),

//             // Content Section
//             Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           booking.serviceId?.serviceName ?? 'Service',
//                           style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: AppColors.grey100,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           'ID: ${booking.bookingNumber.toUpperCase()}',
//                           style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // Meta Info Grid
//                   Row(
//                     children: [
//                       _buildMetaInfo(Icons.calendar_today_rounded, 
//                         DateFormat('EEEE, dd MMM').format(booking.scheduledDateTime)),
//                       _borderDivider(),
//                       _buildMetaInfo(Icons.access_time_rounded, 
//                         booking.scheduledTimeSlot?.split(' - ').first ?? 'N/A'),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMetaInfo(IconData icon, String text) {
//     return Expanded(
//       child: Row(
//         children: [
//           Icon(icon, size: 14, color: AppColors.primary),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _borderDivider() {
//     return Container(
//       height: 14,
//       width: 1,
//       margin: const EdgeInsets.symmetric(horizontal: 12),
//       color: Colors.grey[200],
//     );
//   }

//   Widget _buildModernStatusBadge(String status) {
//     Color color;
//     switch (status) {
//       case 'work_completed': color = Colors.green; break;
//       case 'cancelled_by_user': 
//       case 'cancelled_by_provider': 
//       case 'failed': color = Colors.red; break;
//       case 'provider_assigned':
//       case 'provider_on_the_way': color = Colors.blue; break;
//       default: color = Colors.orange;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),      ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
//           const SizedBox(width: 8),
//           Text(
//             _getStatusLabel(status).toUpperCase(),
//             style: TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getStatusLabel(String status) {
//     switch (status) {
//       case 'pending': return 'Pending';
//       case 'searching_provider': return 'Searching';
//       case 'provider_assigned': return 'Assigned';
//       case 'provider_on_the_way': return 'On The Way';
//       case 'work_started': return 'Working';
//       case 'work_completed': return 'Completed';
//       case 'cancelled_by_user': 
//       case 'cancelled_by_provider': return 'Cancelled';
//       case 'failed': return 'Failed';
//       default: return status;
//     }
//   }

//   Widget _buildFloatingChip(int index, String label) {
//     return AnimatedBuilder(
//       animation: _tabController.animation!,
//       builder: (context, _) {
//         final animValue = _tabController.animation!.value;
        
//         // Calculate selection opacity based on animation distance
//         double selection = 0.0;
//         if ((animValue - index).abs() < 1.0) {
//           selection = 1.0 - (animValue - index).abs();
//         }

//         return Expanded(
//           child: GestureDetector(
//             onTap: () => _tabController.animateTo(index),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               decoration: BoxDecoration(
//                 color: Color.lerp(Colors.grey[50], AppColors.primary, selection),
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: selection > 0.8 ? [
//                   BoxShadow(
//                     color: AppColors.primary.withValues(alpha: 0.2),
//                     blurRadius: 12,
//                     offset: const Offset(0, 4),
//                   )
//                 ] : [],
//               ),
//               child: Center(
//                 child: Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: selection > 0.5 ? FontWeight.w800 : FontWeight.w600,
//                     color: Color.lerp(Colors.grey[600], Colors.white, selection),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
