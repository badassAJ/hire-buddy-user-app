import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hirebuddy/core/theme/app_colors.dart';
import 'package:hirebuddy/providers/booking_provider.dart';
import 'package:hirebuddy/screens/booking/selecting_provider_screen.dart';
import 'package:hirebuddy/screens/booking/booking_summary_screen.dart';

class FindingProviderScreen extends StatefulWidget {
  final String bookingId;
  final String serviceName;

  const FindingProviderScreen({
    super.key,
    required this.bookingId,
    required this.serviceName,
  });

  @override
  State<FindingProviderScreen> createState() => _FindingProviderScreenState();
}

class _FindingProviderScreenState extends State<FindingProviderScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _contentController;
  late Animation<double> _contentFade;

  Timer? _pollingTimer;
  Timer? _countdownTimer;
  bool _initialized = false;
  bool _timerExpired = false;
  bool _transitioned = false;

  @override
  void initState() {
    super.initState();
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _contentController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().initBooking(
        bookingId: widget.bookingId,
        serviceName: widget.serviceName,
        timeRemaining: 60,
      );
    });

    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    _waveController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _transitioned) {
        timer.cancel();
        return;
      }

      final result = await context.read<BookingProvider>().getBookingStatus();

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        final status = data['status'];
        final provider = data['provider'];
        final timeRem = data['timeRemaining'] ?? 0;
        final interested = data['interestedProviders'] ?? 0;

        if (mounted) {
          context.read<BookingProvider>().updateInterestedProviders(interested);
        }

        if (!_initialized && timeRem > 0) {
          _initialized = true;
          if (mounted) {
            context.read<BookingProvider>().updateTimeRemaining(timeRem);
            setState(() {});
          }
          _startCountdown();
        }

        if (status == 'provider_assigned' && provider != null) {
          if (_transitioned) return;
          _transitioned = true;
          timer.cancel();
          _countdownTimer?.cancel();
          if (mounted) {
            context.read<BookingProvider>().setProviderAssigned(provider);
            _navigateToSummary();
          }
          return;
        }

        if (status == 'failed' || status == 'cancelled_by_user') {
          if (_transitioned) return;
          _transitioned = true;
          timer.cancel();
          _countdownTimer?.cancel();
          if (mounted) {
            context.read<BookingProvider>().setFailed('No providers available');
            Navigator.of(context).pop();
          }
          return;
        }

        if (timeRem <= 0 && !_timerExpired && _initialized) {
          _timerExpired = true;
          _countdownTimer?.cancel();
          if (mounted) {
            context.read<BookingProvider>().updateTimeRemaining(0);
            setState(() {});
            _handleTimeExpired();
          }
        }
      }
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _transitioned) {
        timer.cancel();
        return;
      }

      final provider = context.read<BookingProvider>();
      if (provider.timeRemaining > 0) {
        provider.updateTimeRemaining(provider.timeRemaining - 1);
        setState(() {});
      }

      if (provider.timeRemaining <= 0) {
        timer.cancel();
        if (!_timerExpired && !_transitioned) {
          _timerExpired = true;
          _handleTimeExpired();
        }
      }
    });
  }

  void _handleTimeExpired() {
    if (_transitioned) return;
    _navigateToSelectingScreen();
  }

  void _navigateToSelectingScreen() {
    if (!mounted || _transitioned) return;

    _transitioned = true;
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();

    context.read<BookingProvider>().setSelectingProvider();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SelectingProviderScreen()),
    );
  }

  void _navigateToSummary() async {
    final bookingProvider = context.read<BookingProvider>();
    final result = await bookingProvider.getBookingDetails();

    if (result['success'] && mounted) {
      final data = result['data'];

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
            bookingId: widget.bookingId,
            serviceName: widget.serviceName,
            provider: data['providerId'] ?? data['provider'],
            address: fullAddress.isNotEmpty ? fullAddress : null,
            scheduledTime: scheduledTimeDisplay,
            onContinue: () {
              bookingProvider.reset();
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

  void _handleCancel() async {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    await context.read<BookingProvider>().cancelSearch();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatTime() {
    final provider = context.read<BookingProvider>();
    final mins = provider.timeRemaining ~/ 60;
    final secs = provider.timeRemaining % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Animation (Ripple Waves)
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                double progress = (_waveController.value + (index * 0.33)) % 1.0;
                return Container(
                  width: 200 + (progress * 400),
                  height: 200 + (progress * 400),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: (1.0 - progress) * 0.4),
                      width: 2.5,
                    ),
                  ),
                );
              },
            );
          }),

          // Timer In Center of Rings
          FadeTransition(
            opacity: _contentFade,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const Text(
                      'WAIT TIME',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top Content Overlay
          SafeArea(
            child: FadeTransition(
              opacity: _contentFade,
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'Searching for Best Provider',
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
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.serviceName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  
                  // Interest Status at Bottom
                  _buildInterestIndicator(bookingProvider),
                  
                  const SizedBox(height: 32),
                  
                  // Cancel Button
                  TextButton(
                    onPressed: _handleCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[500],
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                    ),
                    child: const Text(
                      'Cancel Booking',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildInterestIndicator(BookingProvider provider) {
    bool hasInterest = provider.interestedProviders > 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Row(
          key: ValueKey(hasInterest),
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: hasInterest ? Colors.green : Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              hasInterest 
                ? '${provider.interestedProviders} Professional(s) interested!' 
                : 'Finding nearby professionals...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: hasInterest ? Colors.green : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
