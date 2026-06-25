import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hirebuddy/screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_layout.dart';
import 'screens/booking/booking_details_screen.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/home_provider.dart';
import 'providers/location_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await StorageService().init();
  ApiService().init();

  final notificationService = NotificationService();
  notificationService.onNotificationTap = (payload) {
    debugPrint('[MAIN] Notification tapped: $payload');
    _handleNotificationNavigation(payload);
  };
  try {
    await notificationService.initialize();
  } catch (e) {
    debugPrint('[MAIN] Notification init failed: $e');
  }

  final isLoggedIn = await StorageService().isLoggedIn();

  // When the interceptor detects a session expiry it calls this —
  // clears provider state and sends user back to onboarding.
  ApiService.onForceLogout = () {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Provider.of<AuthProvider>(ctx, listen: false).clearUser();
    }
    navigatorKey.currentState?.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, a, b) => const OnboardingScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, b, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => false,
    );
  };

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

void _handleNotificationNavigation(Map<String, dynamic> payload) {
  final type = payload['type'] as String? ?? '';
  final nav = navigatorKey.currentState;
  if (nav == null) return;

  if (type == 'open_booking') {
    final bookingId = payload['bookingId'] as String?;
    if (bookingId != null) {
      nav.push(MaterialPageRoute(
        // builder: (_) => BookingDetailsScreen(bookingId: bookingId),
        builder: (_) => HomeScreen()                                         //need to make changes for bookingdetails screen
      ));
    }
  }
  else {
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainLayout()),
      (route) => false,
    );
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'Hirebuddy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        navigatorKey: navigatorKey,
        home: isLoggedIn ? const SplashScreen() : const OnboardingScreen(),
        // home: MainLayout(),
      ),
    );
  }
}
