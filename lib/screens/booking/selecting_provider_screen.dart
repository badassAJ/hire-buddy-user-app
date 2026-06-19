import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hirebuddy/core/theme/app_colors.dart';
import 'package:hirebuddy/providers/booking_provider.dart';
import 'package:hirebuddy/screens/booking/booking_summary_screen.dart';

class SelectingProviderScreen extends StatefulWidget {
  const SelectingProviderScreen({super.key});

  @override
  State<SelectingProviderScreen> createState() =>
      _SelectingProviderScreenState();
}

class _SelectingProviderScreenState extends State<SelectingProviderScreen>
    with TickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<double> _contentFade;
  late AnimationController _stackController;
  
  Timer? _pollingTimer;
  bool _transitioned = false;

  @override
  void initState() {
    super.initState();
    
    // Main content entry animation
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _contentController.forward();

    // Loop for card stack "selection" feel
    _stackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _contentController.dispose();
    _stackController.dispose();
    super.dispose();
  }

  void _startPolling() {
    int pollCount = 0;
    const maxPolls = 30;

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted || _transitioned) {
        timer.cancel();
        return;
      }

      pollCount++;
      final bookingProvider = context.read<BookingProvider>();
      final result = await bookingProvider.getBookingStatus();

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        final status = data['status'];
        final provider = data['provider'];

        if (status == 'provider_assigned' && provider != null) {
          if (_transitioned) return;
          _transitioned = true;
          timer.cancel();
          bookingProvider.setProviderAssigned(provider);
          if (mounted) {
            _navigateToSummary();
          }
          return;
        }

        if (status == 'failed' || status == 'cancelled_by_user') {
          if (_transitioned) return;
          _transitioned = true;
          timer.cancel();
          bookingProvider.setFailed('No providers available');
          if (mounted) {
            Navigator.of(context).pop();
          }
          return;
        }
      }

      if (pollCount >= maxPolls) {
        if (_transitioned) return;
        _transitioned = true;
        timer.cancel();
        if (mounted) {
          context.read<BookingProvider>().setFailed('Request timed out');
          Navigator.of(context).pop();
        }
      }
    });
  }

  void _navigateToSummary() async {
    final bookingProvider = context.read<BookingProvider>();
    final bookingId = bookingProvider.bookingId;
    final serviceName = bookingProvider.serviceName;

    if (bookingId == null || serviceName == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final result = await bookingProvider.getBookingDetails();

    if (result['success'] && mounted) {
      final data = result['data'];
      bookingProvider.reset();

      // Build full address from addressSnapshot
      final addressSnap = data['addressSnapshot'];
      String fullAddress = '';
      if (addressSnap != null) {
        final parts = <String>[];
        if (addressSnap['society'] != null &&
            addressSnap['society'].toString().isNotEmpty) {
          parts.add(addressSnap['society'].toString());
        }
        if (addressSnap['block'] != null &&
            addressSnap['block'].toString().isNotEmpty) {
          parts.add('Block ${addressSnap['block']}');
        }
        if (addressSnap['tower'] != null &&
            addressSnap['tower'].toString().isNotEmpty) {
          parts.add('Tower ${addressSnap['tower']}');
        }
        if (addressSnap['flatNumber'] != null &&
            addressSnap['flatNumber'].toString().isNotEmpty) {
          parts.add('Flat ${addressSnap['flatNumber']}');
        }
        if (addressSnap['landmark'] != null &&
            addressSnap['landmark'].toString().isNotEmpty) {
          parts.add(addressSnap['landmark'].toString());
        }
        if (addressSnap['city'] != null &&
            addressSnap['city'].toString().isNotEmpty) {
          parts.add(addressSnap['city'].toString());
        }
        fullAddress = parts.join(', ');
      }

      // Build scheduled time
      String scheduledTimeDisplay = 'Immediate';
      if (data['scheduledDateTime'] != null) {
        try {
          final dateTime = DateTime.parse(data['scheduledDateTime']);
          scheduledTimeDisplay = _formatScheduledDateTime(dateTime);
        } catch (e) {
          if (data['scheduledTimeSlot'] != null) {
            scheduledTimeDisplay = data['scheduledTimeSlot'];
          }
        }
      } else if (data['scheduledTimeSlot'] != null) {
        scheduledTimeDisplay = data['scheduledTimeSlot'];
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => BookingSummaryScreen(
            bookingId: bookingId,
            serviceName: serviceName,
            provider: data['providerId'] ?? data['provider'],
            address: fullAddress.isNotEmpty ? fullAddress : null,
            scheduledTime: scheduledTimeDisplay,
            onContinue: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
        (route) => route.isFirst,
      );
    }
  }

  String _formatScheduledDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dayPart = '';
    if (dateToCheck == today) {
      dayPart = 'Today';
    } else if (dateToCheck == tomorrow) {
      dayPart = 'Tomorrow';
    } else {
      dayPart = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$dayPart, $hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background - clean white
          
          SafeArea(
            child: FadeTransition(
              opacity: _contentFade,
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // Header text at Top
                  const Text(
                    'Selecting Best Provider',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bookingProvider.serviceName ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Middle: Overlapping Card Stack
                  Center(
                    child: SizedBox(
                      height: 300,
                      width: MediaQuery.of(context).size.width,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Third Card (Bottom)
                          _buildOverlappingCard(index: 2, offset: 40, scale: 0.85, opacity: 0.3),
                          // Second Card (Middle)
                          _buildOverlappingCard(index: 1, offset: 20, scale: 0.93, opacity: 0.6),
                          // First Card (Top - Active)
                          _buildOverlappingCard(index: 0, offset: 0, scale: 1.0, opacity: 1.0, isActive: true),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Bottom Status
                  const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(Colors.green),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Text(
                      'Analyzing professionals and finding your perfect match...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlappingCard({
    required int index,
    required double offset,
    required double scale,
    required double opacity,
    bool isActive = false,
  }) {
    return AnimatedBuilder(
      animation: _stackController,
      builder: (context, child) {
        // Adding a split-second jitter/slide for the active card to look "live"
        double yShift = isActive ? (index * offset) : (index * offset);
        
        return Transform.translate(
          offset: Offset(0, yShift),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 280,
                height: 180,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),                  border: Border.all(
                    color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.grey[200]!,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isActive ? Icons.verified_user : Icons.person_outline_rounded,
                        color: isActive ? Colors.green : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 140,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withValues(alpha: 0.05) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withValues(alpha: 0.05) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
