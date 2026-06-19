// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:printing/printing.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../../core/theme/app_colors.dart';
// import '../../models/booking_model.dart';
// import '../../services/booking_service.dart';
// import '../../utils/invoice_generator.dart';
// import '../support/raise_dispute_sheet.dart';
// import 'cancel_reason_sheet.dart';
// import 'checkout_screen.dart';
// import 'reschedule_sheet.dart';

// class BookingDetailsScreen extends StatefulWidget {
//   final String bookingId;

//   const BookingDetailsScreen({super.key, required this.bookingId});

//   @override
//   State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
// }

// class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
//   final BookingService _bookingService = BookingService();
//   BookingModel? _booking;
//   bool _isLoading = true;
//   Timer? _refreshTimer;
//   final ScrollController _scrollController = ScrollController();
//   bool _showCollapsedTitle = false;
//   Map<String, dynamic>? _existingReview;
//   bool _reviewLoading = false;
//   bool _hasShownRatingPrompt = false;
//   bool _isCancelling = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadBookingDetails();
//     _scrollController.addListener(_scrollListener);
//     _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
//       _loadBookingDetails(silent: true);
//     });
//   }

//   void _scrollListener() {
//     if (_scrollController.hasClients) {
//       bool collapsed = _scrollController.offset > 200;
//       if (collapsed != _showCollapsedTitle) {
//         setState(() => _showCollapsedTitle = collapsed);
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _refreshTimer?.cancel();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadBookingDetails({bool silent = false}) async {
//     if (!silent) setState(() => _isLoading = true);
//     try {
//       final result = await _bookingService.getBookingDetails(widget.bookingId);
//       if (result['success'] && mounted) {
//         final booking = BookingModel.fromJson(result['data']);
//         setState(() {
//           _booking = booking;
//           _isLoading = false;
//         });
//         if (booking.bookingStatus == 'completed') {
//           _loadReview();
//         }
//       }
//     } catch (e) {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _loadReview() async {
//     setState(() => _reviewLoading = true);
//     final result = await _bookingService.getBookingReview(widget.bookingId);
//     if (mounted) {
//       setState(() {
//         _existingReview = result['data'] as Map<String, dynamic>?;
//         _reviewLoading = false;
//       });
//       if (_existingReview == null && !_hasShownRatingPrompt) {
//         _showRatingSheet();
//       }
//     }
//   }

//   Future<void> _launchPhone(String? phone) async {
//     if (phone == null || phone.isEmpty) return;
//     final uri = Uri.parse('tel:$phone');
//     if (await canLaunchUrl(uri)) await launchUrl(uri);
//   }

//   void _showRatingSheet() {
//     if (!mounted) return;
//     _hasShownRatingPrompt = true;
//     Future.delayed(const Duration(milliseconds: 600), () {
//       if (!mounted) return;
//       showModalBottomSheet<bool>(
//         context: context,
//         isScrollControlled: true,
//         useSafeArea: true,
//         backgroundColor: Colors.transparent,
//         builder: (_) => _RatingBottomSheet(
//           serviceName: _booking!.serviceId?.serviceName ?? 'Service',
//           bookingId: widget.bookingId,
//           bookingService: _bookingService,
//         ),
//       ).then((submitted) {
//         if (submitted == true && mounted) _loadReview();
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//         backgroundColor: Colors.white,
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_booking == null) {
//       return Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
//         body: const Center(child: Text('Booking not found')),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: CustomScrollView(
//         controller: _scrollController,
//         slivers: [
//           _buildModernAppBar(),
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (!_showCollapsedTitle) _buildStatusHeader(),
//                   const SizedBox(height: 32),
//                   _buildProviderSection(),
//                   const SizedBox(height: 32),
//                   _buildStatusTimeline(),
//                   if (_booking!.bookingStatus == 'work_started' && _booking!.completionOtp != null) ...[
//                     const SizedBox(height: 32),
//                     _buildOtpCard(),
//                   ],
//                   const SizedBox(height: 32),
//                   _buildServiceDetails(),
//                   const SizedBox(height: 32),
//                   _buildPricingSection(),
//                   if (_booking!.bookingStatus == 'completed') ...[
//                     const SizedBox(height: 32),
//                     _buildRatingSection(),
//                     const SizedBox(height: 16),
//                     _buildDownloadInvoiceButton(),
//                   ],
//                   const SizedBox(height: 120),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//       bottomSheet: _buildBottomActions(),
//     );
//   }

//   Widget _buildModernAppBar() {
//     final imageUrl = _booking!.serviceId?.primaryImageUrl;
//     return SliverAppBar(
//       expandedHeight: 280,
//       pinned: true,
//       elevation: 0,
//       backgroundColor: Colors.white,
//       leading: IconButton(
//         icon: Icon(
//           Icons.arrow_back_ios_new_rounded, 
//           color: _showCollapsedTitle ? Colors.black : Colors.white,
//           size: 22,
//         ),
//         onPressed: () => Navigator.pop(context),
//       ),
//       centerTitle: false,
//       titleSpacing: 0,
//       title: _showCollapsedTitle 
//         ? Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 _booking!.serviceId?.serviceName ?? '',
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w900,
//                 ),
//               ),
//               Text(
//                 'ID: ${_booking!.bookingNumber.toUpperCase()}',
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: 10,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 0.5,
//                 ),
//               ),
//             ],
//           )
//         : null,
//       flexibleSpace: FlexibleSpaceBar(
//         background: Stack(
//           fit: StackFit.expand,
//           children: [
//             if (imageUrl != null && imageUrl.startsWith('http'))
//               Image.network(imageUrl, fit: BoxFit.cover)
//             else
//               Container(color: AppColors.grey100),
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     Colors.black.withValues(alpha: _showCollapsedTitle ? 0.0 : 0.3),
//                     Colors.transparent,
//                     Colors.black.withValues(alpha: _showCollapsedTitle ? 0.0 : 0.6),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusHeader() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     _booking!.serviceId?.serviceName ?? 'Service',
//                     style: const TextStyle(
//                       fontSize: 26,
//                       fontWeight: FontWeight.w900,
//                       letterSpacing: -0.8,
//                       color: AppColors.textPrimary,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     'Booking ID: ${_booking!.bookingNumber.toUpperCase()}',
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.grey[500],
//                       letterSpacing: 0.5,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             _buildDetailedStatusBadge(_booking!.bookingStatus),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildStatusTimeline() {
//     List<Map<String, dynamic>> steps = [
//       {'title': 'Booking Received', 'status': 'pending', 'icon': Icons.receipt_long},
//       {'title': 'Professional Assigned', 'status': 'provider_assigned', 'icon': Icons.person_outline_rounded},
//       {'title': 'On The Way', 'status': 'provider_on_the_way', 'icon': Icons.directions_bike},
//       {'title': 'Service Started', 'status': 'work_started', 'icon': Icons.play_circle_outline},
//       {'title': 'Service Completed', 'status': 'completed', 'icon': Icons.verified_outlined},
//     ];

//     int currentIdx = steps.indexWhere((s) => s['status'] == _booking!.bookingStatus);
//     if (currentIdx == -1) {
//        // if searching, color assigned step as pulse or similar
//        if (_booking!.bookingStatus == 'searching_provider') currentIdx = 0;
//        else if (_booking!.bookingStatus == 'failed' || _booking!.bookingStatus.contains('cancelled')) currentIdx = -1;
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Service Progress',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
//         ),
//         const SizedBox(height: 24),
//         ...List.generate(steps.length, (index) {
//           bool isCompleted = index <= currentIdx;
//           bool isLast = index == steps.length - 1;
//           bool isActive = index == currentIdx;

//           return IntrinsicHeight(
//             child: Row(
//               children: [
//                 Column(
//                   children: [
//                     Container(
//                       width: 24,
//                       height: 24,
//                       decoration: BoxDecoration(
//                         color: isCompleted ? AppColors.primary : Colors.grey[200],
//                         shape: BoxShape.circle,
//                         border: isActive ? Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 6) : null,
//                       ),
//                       child: Icon(
//                         steps[index]['icon'], 
//                         size: 14, 
//                         color: isCompleted ? Colors.white : Colors.grey[400]
//                       ),
//                     ),
//                     if (!isLast)
//                       Expanded(
//                         child: Container(
//                           width: 2,
//                           color: isCompleted ? AppColors.primary : Colors.grey[200],
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.only(bottom: 24),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           steps[index]['title'],
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
//                             color: isCompleted ? AppColors.textPrimary : Colors.grey[400],
//                             letterSpacing: -0.2,
//                           ),
//                         ),
//                         if (isActive)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 4),
//                             child: Text(
//                               'Live Status',
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w800,
//                                 color: AppColors.primary.withValues(alpha: 0.7),
//                                 letterSpacing: 0.5,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }),
//       ],
//     );
//   }

//   Widget _buildDetailedStatusBadge(String status) {
//     Color color;
//     switch (status) {
//       case 'completed': color = Colors.green; break;
//       case 'cancelled_by_user': 
//       case 'cancelled_by_provider': 
//       case 'failed': color = Colors.red; break;
//       case 'provider_assigned':
//       case 'provider_on_the_way': color = Colors.blue; break;
//       default: color = Colors.orange;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.1),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         status.replaceAll('_', ' ').toUpperCase(),
//         style: TextStyle(
//           color: color,
//           fontSize: 11,
//           fontWeight: FontWeight.w900,
//           letterSpacing: 0.5,
//         ),
//       ),
//     );
//   }

//   Widget _buildProviderSection() {
//     if (_booking!.providerId == null) {
//       return Container(
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: Colors.grey[50],
//           borderRadius: BorderRadius.circular(28),
//           border: Border.all(color: Colors.grey[100]!),
//         ),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,              ),
//               child: Icon(Icons.person_search_rounded, color: Colors.grey[400], size: 24),
//             ),
//             const SizedBox(width: 16),
//             const Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Assigning Professional',
//                     style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
//                   ),
//                   SizedBox(height: 2),
//                   Text(
//                     'Finding the best match...',
//                     style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     final p = _booking!.providerId!;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Service Professional',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
//         ),
//         const SizedBox(height: 16),
//         Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(28),
//             border: Border.all(color: Colors.grey[100]!),          ),
//           child: Row(
//             children: [
//               CircleAvatar(
//                 radius: 30,
//                 backgroundColor: AppColors.primary.withValues(alpha: 0.1),
//                 child: const Icon(Icons.person, color: AppColors.primary, size: 32),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       p.fullName ?? 'Professional',
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
//                         const SizedBox(width: 4),
//                         Text(
//                           (p.averageRating != null && p.averageRating! > 0)
//                               ? p.averageRating!.toStringAsFixed(1)
//                               : 'New',
//                           style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
//                         ),
//                         const SizedBox(width: 12),
//                         Container(
//                           width: 4, height: 4, 
//                           decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)
//                         ),
//                         const SizedBox(width: 12),
//                         Text(
//                           '${p.totalRatings ?? 0} Ratings',
//                           style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withValues(alpha: 0.08),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: IconButton(
//                   onPressed: () => _launchPhone(p.mobileNumber),
//                   icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary, size: 22),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildServiceDetails() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Booking Details',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
//         ),
//         const SizedBox(height: 20),
//         _buildDetailRow(Icons.calendar_today_rounded, 'DATE', 
//           DateFormat('EEEE, dd MMMM yyyy').format(_booking!.scheduledDateTime), Colors.blue),
//         _buildDetailRow(Icons.access_time_rounded, 'TIME SLOT', _booking!.scheduledTimeSlot ?? 'N/A', Colors.orange),
//         _buildDetailRow(Icons.location_on_rounded, 'LOCATION',
//           _booking!.addressSnapshot?.fullAddress ?? 'Address not available', Colors.green),
//       ],
//     );
//   }

//   Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 24),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: color.withValues(alpha: 0.1),
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Icon(icon, size: 20, color: color),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w800, letterSpacing: 0.8),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.4),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOtpCard() {
//     final otp = _booking!.completionOtp!;
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(28),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withValues(alpha: 0.15),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
//               ),
//               const SizedBox(width: 12),
//               const Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Completion OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
//                     Text('Share this code with your service provider', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: otp.split('').map((digit) => Container(
//               margin: const EdgeInsets.symmetric(horizontal: 8),
//               width: 52,
//               height: 64,
//               decoration: BoxDecoration(
//                 color: Colors.white.withValues(alpha: 0.1),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
//               ),
//               child: Center(
//                 child: Text(digit, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
//               ),
//             )).toList(),
//           ),
//           const SizedBox(height: 16),
//           Text('Valid for 10 minutes', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
//         ],
//       ),
//     );
//   }

//   Widget _buildPricingSection() {
//     final pricing = _booking!.pricing;
//     return Container(
//       padding: const EdgeInsets.all(28),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(32),
//         border: Border.all(color: Colors.grey[100]!),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
//           Text(
//             '₹${(pricing?.totalAmount ?? 0).toStringAsFixed(0)}',
//             style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 24),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPriceLine(String label, double amount) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.grey)),
//         Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
//       ],
//     );
//   }

//   void _showDisputeSheet() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       useSafeArea: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => RaiseDisputeSheet(
//         bookingId: widget.bookingId,
//         serviceName: _booking?.serviceId?.serviceName,
//       ),
//     );
//   }

//   Future<void> _handleCancelBooking() async {
//     final reason = await showCancelReasonSheet(context, isOrder: false);
//     if (reason == null || !mounted) return;

//     setState(() => _isCancelling = true);
//     final result = await _bookingService.cancelBooking(
//       bookingId: widget.bookingId,
//       reason: reason,
//     );
//     if (!mounted) return;
//     setState(() => _isCancelling = false);

//     if (result['success'] == true) {
//       _loadBookingDetails(silent: true);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Booking cancelled'),
//           backgroundColor: Colors.black87,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(result['error'] ?? 'Failed to cancel booking'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }

//   Widget _buildBottomActions() {
//     bool canCancel = ['pending', 'searching_provider'].contains(_booking!.bookingStatus);
//     bool isTracking = ['provider_on_the_way', 'work_started'].contains(_booking!.bookingStatus);
//     bool canDispute = _booking!.bookingStatus == 'completed' || _booking!.bookingStatus.contains('cancelled');
//     bool canRebook = _booking!.bookingStatus == 'completed' && _booking!.serviceId != null;

//     return Container(
//       padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewPadding.bottom + 16),
//       decoration: BoxDecoration(
//         color: Colors.white,      ),
//       child: Row(
//         children: [
//           if (canDispute)
//             Expanded(
//               child: OutlinedButton.icon(
//                 onPressed: _showDisputeSheet,
//                 icon: const Icon(Icons.report_outlined, size: 16),
//                 label: const Text('Get Help', style: TextStyle(fontWeight: FontWeight.w800)),
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: Colors.red,
//                   side: const BorderSide(color: Colors.red),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                 ),
//               ),
//             ),
//           if (canRebook) ...[
//             const SizedBox(width: 12),
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => CheckoutScreen(
//                       serviceId: _booking!.serviceId!.id,
//                       serviceName: _booking!.serviceId!.serviceName,
//                       price: _booking!.pricing?.totalAmount ?? 0,
//                     ),
//                   ),
//                 ),
//                 icon: const Icon(Icons.replay_rounded, size: 16),
//                 label: const Text('Book Again', style: TextStyle(fontWeight: FontWeight.w900)),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                 ),
//               ),
//             ),
//           ],
//           if (canCancel) ...[
//             Expanded(
//               child: OutlinedButton.icon(
//                 onPressed: () => showModalBottomSheet(
//                   context: context,
//                   isScrollControlled: true,
//                   useSafeArea: true,
//                   backgroundColor: Colors.transparent,
//                   builder: (_) => RescheduleSheet(
//                     bookingId: widget.bookingId,
//                     currentDate: _booking!.scheduledDateTime,
//                     currentTimeSlot: _booking!.scheduledTimeSlot,
//                     onRescheduled: () => _loadBookingDetails(silent: true),
//                   ),
//                 ),
//                 icon: const Icon(Icons.schedule_rounded, size: 16),
//                 label: const Text('Reschedule', style: TextStyle(fontWeight: FontWeight.w800)),
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: AppColors.textPrimary,
//                   side: const BorderSide(color: Colors.black26),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             TextButton(
//               onPressed: _isCancelling ? null : _handleCancelBooking,
//               child: _isCancelling
//                   ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
//                   : const Text('Cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
//             ),
//           ],
//           if (canCancel && isTracking) const SizedBox(width: 16),
//           if (isTracking)
//             Expanded(
//               flex: 2,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.black,
//                   borderRadius: BorderRadius.circular(20),                ),
//                 child: ElevatedButton(
//                   onPressed: () {}, 
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.transparent,
//                     foregroundColor: Colors.white,
//                     shadowColor: Colors.transparent,
//                     padding: const EdgeInsets.symmetric(vertical: 18),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                   ),
//                   child: const Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.location_on_rounded, size: 18),
//                       SizedBox(width: 12),
//                       Text('Track Professional', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDownloadInvoiceButton() {
//     return OutlinedButton.icon(
//       onPressed: () async {
//         try {
//           final bytes = await InvoiceGenerator.generateBookingInvoice(_booking!);
//           await Printing.sharePdf(
//             bytes: bytes,
//             filename: 'invoice-${_booking!.bookingNumber}.pdf',
//           );
//         } catch (_) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Could not generate invoice')),
//             );
//           }
//         }
//       },
//       icon: const Icon(Icons.download_outlined, size: 18),
//       label: const Text('Download Invoice', style: TextStyle(fontWeight: FontWeight.w700)),
//       style: OutlinedButton.styleFrom(
//         foregroundColor: AppColors.textPrimary,
//         side: BorderSide(color: Colors.grey.shade300),
//         minimumSize: const Size(double.infinity, 52),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//       ),
//     );
//   }

//   Widget _buildRatingSection() {
//     if (_reviewLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (_existingReview != null) {
//       final rating = (_existingReview!['ratings']?['overall'] ?? 0).toInt();
//       final text = _existingReview!['reviewText'] as String? ?? '';
//       return Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.amber.withValues(alpha: 0.06),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
//                 const SizedBox(width: 8),
//                 const Text('Your Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: List.generate(5, (i) => Icon(
//                 i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
//                 color: Colors.amber, size: 24,
//               )),
//             ),
//             if (text.isNotEmpty) ...[
//               const SizedBox(height: 10),
//               Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
//             ],
//           ],
//         ),
//       );
//     }

//     return GestureDetector(
//       onTap: _showRatingSheet,
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: AppColors.grey200),
//         ),
//         child: Column(
//           children: [
//             const Icon(Icons.star_rounded, color: Colors.amber, size: 36),
//             const SizedBox(height: 10),
//             const Text('Rate this Service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
//             const SizedBox(height: 6),
//             Text('How was your experience?', style: TextStyle(fontSize: 13, color: AppColors.grey500)),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.black,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Text('Write a Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _RatingBottomSheet extends StatefulWidget {
//   final String serviceName;
//   final String bookingId;
//   final BookingService bookingService;

//   const _RatingBottomSheet({
//     required this.serviceName,
//     required this.bookingId,
//     required this.bookingService,
//   });

//   @override
//   State<_RatingBottomSheet> createState() => _RatingBottomSheetState();
// }

// class _RatingBottomSheetState extends State<_RatingBottomSheet> {
//   int _serviceRating = 0;
//   int _providerRating = 0;
//   final _reviewController = TextEditingController();
//   bool _submitting = false;

//   static const _labels = ['', 'Terrible', 'Bad', 'Okay', 'Good', 'Excellent'];

//   Color _labelColor(int r) =>
//       r >= 4 ? Colors.green : r == 3 ? Colors.orange : r > 0 ? Colors.red : Colors.transparent;

//   @override
//   void dispose() {
//     _reviewController.dispose();
//     super.dispose();
//   }

//   Future<void> _submit() async {
//     if (_serviceRating == 0 || _providerRating == 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please rate both the service and provider')),
//       );
//       return;
//     }
//     setState(() => _submitting = true);
//     final result = await widget.bookingService.submitRating(
//       bookingId: widget.bookingId,
//       rating: _providerRating,
//       serviceRating: _serviceRating,
//       reviewText: _reviewController.text.trim(),
//     );
//     if (!mounted) return;
//     setState(() => _submitting = false);
//     if (result['success'] == true) {
//       Navigator.of(context).pop(true);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Review submitted. Thank you!')),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(result['error'] ?? 'Failed to submit')),
//       );
//     }
//   }

//   Widget _buildStarRow(int current, ValueChanged<int> onTap) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: List.generate(5, (i) {
//         final filled = i < current;
//         return GestureDetector(
//           onTap: () => onTap(i + 1),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 5),
//             child: Icon(
//               filled ? Icons.star_rounded : Icons.star_outline_rounded,
//               color: filled ? Colors.amber : AppColors.grey300,
//               size: 40,
//             ),
//           ),
//         );
//       }),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bottom = MediaQuery.of(context).viewInsets.bottom;
//     return Container(
//       margin: EdgeInsets.only(bottom: bottom),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//       ),
//       padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
//       child: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
//             const SizedBox(height: 24),
//             const Text('Rate your experience', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
//             const SizedBox(height: 6),
//             Text(widget.serviceName, style: TextStyle(fontSize: 14, color: AppColors.grey500)),
//             const SizedBox(height: 28),

//             // Service Rating
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: AppColors.grey50,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 children: [
//                   const Text('Rate the Service', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
//                   const SizedBox(height: 14),
//                   _buildStarRow(_serviceRating, (v) => setState(() => _serviceRating = v)),
//                   const SizedBox(height: 8),
//                   AnimatedSwitcher(
//                     duration: const Duration(milliseconds: 200),
//                     child: Text(
//                       _serviceRating > 0 ? _labels[_serviceRating] : ' ',
//                       key: ValueKey(_serviceRating),
//                       style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _labelColor(_serviceRating)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 12),

//             // Provider Rating
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: AppColors.grey50,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 children: [
//                   const Text('Rate the Provider', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
//                   const SizedBox(height: 14),
//                   _buildStarRow(_providerRating, (v) => setState(() => _providerRating = v)),
//                   const SizedBox(height: 8),
//                   AnimatedSwitcher(
//                     duration: const Duration(milliseconds: 200),
//                     child: Text(
//                       _providerRating > 0 ? _labels[_providerRating] : ' ',
//                       key: ValueKey('p$_providerRating'),
//                       style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _labelColor(_providerRating)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Review text
//             TextField(
//               controller: _reviewController,
//               maxLines: 3,
//               maxLength: 300,
//               decoration: InputDecoration(
//                 hintText: 'Share your experience (optional)',
//                 hintStyle: TextStyle(color: AppColors.grey400),
//                 filled: true,
//                 fillColor: AppColors.grey50,
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
//                 counterStyle: TextStyle(color: AppColors.grey400, fontSize: 11),
//               ),
//             ),
//             const SizedBox(height: 16),

//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _submitting ? null : _submit,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.black,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                 ),
//                 child: _submitting
//                     ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                     : const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
