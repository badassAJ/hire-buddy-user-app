import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/location_provider.dart';
import '../services/storage_service.dart';
import 'onboarding_screen.dart';
import 'main_layout.dart';
import 'service_unavailable_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool skipToHome;
  const SplashScreen({super.key, this.skipToHome = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _locationFound = false;
  bool _locationFailed = false;
  String _addressTitle = '';
  String _addressFull = '';
  String? _detectedCity;
  String? _detectedState;
  Map<String, dynamic>? _configData;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    _startLocationCheck();
  }

  Future<void> _startLocationCheck() async {
    if (!mounted) return;
    setState(() {
      _locationFound = false;
      _locationFailed = false;
    });

    Position? position;
    List<Placemark> placemarks = [];

    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      // Check if location services are enabled first
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        Provider.of<LocationProvider>(context, listen: false)
            .setAddress(title: 'Set your location', full: '');
        _proceedToApp();
        return;
      }

      final permission = await _ensureLocationPermission();

      // User declined location — don't block them, proceed straight in.
      if (!permission) {
        if (!mounted) return;
        Provider.of<LocationProvider>(context, listen: false)
            .setAddress(title: 'Set your location', full: '');
        _proceedToApp();
        return;
      }

      // Fetch config + location in parallel
      // Also try getLastKnownPosition as fast fallback alongside getCurrentPosition
      final results = await Future.wait([
        dio.get(ApiConstants.publicServiceArea).then((r) => r.data).catchError((_) => null),
        Future.any([
          Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.lowest,
            timeLimit: const Duration(seconds: 10),
          ).then<Position?>((p) => p),
          Geolocator.getLastKnownPosition().then<Position?>((p) => p),
        ]).catchError((_) => null),
      ]);

      _configData = results[0] as Map<String, dynamic>?;
      position = results[1] as Position?;

      // Try geocoding up to 3 times — geocoder sometimes returns empty transiently
      if (position != null) {
        for (int attempt = 0; attempt < 3; attempt++) {
          try {
            placemarks = await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            );
            if (placemarks.isNotEmpty) break;
          } catch (_) {}
          if (attempt < 2) await Future.delayed(const Duration(milliseconds: 600));
        }
      }
    } catch (_) {}

    if (!mounted) return;

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      _detectedCity = place.locality ?? place.subAdministrativeArea ?? '';
      _detectedState = place.administrativeArea ?? '';

      final street = place.thoroughfare ?? place.subLocality ?? place.locality ?? '';
      final parts = <String>[
        if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) place.thoroughfare!,
        if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality!,
        if (place.locality != null && place.locality!.isNotEmpty) place.locality!,
        if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty)
          place.subAdministrativeArea!,
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty)
          place.administrativeArea!,
        if (place.postalCode != null && place.postalCode!.isNotEmpty) place.postalCode!,
        if (place.country != null && place.country!.isNotEmpty) place.country!,
      ];
      final seen = <String>{};
      final uniqueParts = parts.where((p) => seen.add(p)).toList();

      final title = street.isNotEmpty ? street : (_detectedCity ?? 'Your Location');
      final full = uniqueParts.join(', ');

      Provider.of<LocationProvider>(context, listen: false).setAddress(title: title, full: full);
      setState(() {
        _locationFound = true;
        _addressTitle = title;
        _addressFull = full;
      });

      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      _checkServiceAreaAndProceed();
    } else if (position != null) {
      // Have coordinates but geocoding failed entirely — proceed without service area check
      Provider.of<LocationProvider>(context, listen: false)
          .setAddress(title: 'Your Location', full: '');
      setState(() {
        _locationFound = true;
        _addressTitle = 'Your Location';
        _addressFull = '';
      });

      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      _proceedToApp();
    } else {
      // Truly no location — instead of showing retry, proceed with default location
      Provider.of<LocationProvider>(context, listen: false)
          .setAddress(title: 'Set your location', full: '');
      _proceedToApp();
    }
  }

  void _checkServiceAreaAndProceed() {
    final isActive = _configData?['data']?['isActive'] as bool? ?? false;
    final locations = _configData?['data']?['locations'] as List<dynamic>? ?? [];

    if (isActive && locations.isNotEmpty && _detectedCity != null && _detectedCity!.isNotEmpty) {
      final cityLower = _detectedCity!.trim().toLowerCase();
      final stateLower = (_detectedState ?? '').trim().toLowerCase();

      final matched = locations.any((loc) {
        final locState = (loc['state'] as String? ?? '').trim().toLowerCase();
        final locCities = (loc['cities'] as List<dynamic>? ?? [])
            .map((c) => c.toString().trim().toLowerCase())
            .toList();

        final stateMatch = locState.isEmpty ||
            stateLower.contains(locState) ||
            locState.contains(stateLower);
        final cityMatch = locCities.any(
            (c) => c.isNotEmpty && (cityLower.contains(c) || c.contains(cityLower)));

        return stateMatch && cityMatch;
      });

      if (!matched) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, a, b) => ServiceUnavailableScreen(
              userCity: _detectedCity,
              userState: _detectedState,
            ),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, animation, b, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
        return;
      }
    }

    _proceedToApp();
  }

  Future<bool> _ensureLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  void _proceedToApp() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final storageService = StorageService();
    final isLoggedIn = await storageService.isLoggedIn();

    if (widget.skipToHome && !isLoggedIn) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a, b) => const MainLayout(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, b, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
      return;
    }

    if (isLoggedIn) {
      try {
        await Future.wait([
          authProvider.loadCurrentUser(),
          homeProvider.fetchHomeData(),
        ]).timeout(const Duration(seconds: 6));
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a, b) => const MainLayout(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, b, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a, b) => const OnboardingScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, b, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AnimatedLocationPin(
                  found: _locationFound,
                  failed: _locationFailed,
                ),
                const SizedBox(height: 40),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _locationFailed
                      ? _RetryView(
                          key: const ValueKey('retry'),
                          onRetry: _startLocationCheck,
                          onSkip: () {
                            Provider.of<LocationProvider>(context, listen: false)
                                .setAddress(title: 'Set your location', full: '');
                            _proceedToApp();
                          },
                        )
                      : _locationFound
                          ? _AddressDisplay(
                              key: const ValueKey('address'),
                              title: _addressTitle,
                              fullAddress: _addressFull,
                            )
                          : Text(
                              key: const ValueKey('fetching'),
                              'Detecting your location...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLocationPin extends StatefulWidget {
  final bool found;
  final bool failed;
  const _AnimatedLocationPin({required this.found, required this.failed});

  @override
  State<_AnimatedLocationPin> createState() => _AnimatedLocationPinState();
}

class _AnimatedLocationPinState extends State<_AnimatedLocationPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnim;

  static const _pinColor = Color(0xFF5C35D5);
  static const _foundColor = Color(0xFF3CB371);
  static const _failedColor = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_AnimatedLocationPin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.found || widget.failed) {
      _controller.stop();
    } else {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.failed
        ? _failedColor
        : widget.found
            ? _foundColor
            : _pinColor;

    final icon = widget.failed
        ? Icons.location_off_rounded
        : widget.found
            ? Icons.check_rounded
            : Icons.location_on_rounded;

    return SizedBox(
      width: 80,
      height: 90,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (!widget.found && !widget.failed)
            Positioned(
              top: 0,
              child: ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _pinColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          Positioned(
            top: 46,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 2,
              height: 20,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Positioned(
            top: 66,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 12,
              height: 6,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryView extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onSkip;
  const _RetryView({super.key, required this.onRetry, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Couldn't detect your location",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Please check your location settings\nand try again.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text(
            'Skip for now',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressDisplay extends StatelessWidget {
  final String title;
  final String fullAddress;

  const _AddressDisplay({
    super.key,
    required this.title,
    required this.fullAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Delivering service at',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3CB371),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          fullAddress,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
