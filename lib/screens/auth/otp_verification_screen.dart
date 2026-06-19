// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:pinput/pinput.dart';
// import 'package:provider/provider.dart';

// import '../../core/theme/app_colors.dart';
// import '../../providers/auth_provider.dart';
// import '../main_layout.dart';
// import '../onboarding/name_screen.dart';

// class OtpVerificationScreen extends StatefulWidget {
//   final String phoneNumber;
//   final bool isNewUser;
//   final bool isForgotPassword; // ✅ NEW

//   const OtpVerificationScreen({
//     super.key,
//     required this.phoneNumber,
//     this.isNewUser = false,
//     this.isForgotPassword = false,
//   });

//   @override
//   State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
// }

// class _OtpVerificationScreenState extends State<OtpVerificationScreen>
//     with SingleTickerProviderStateMixin {
//   final TextEditingController _otpController = TextEditingController();
//   final FocusNode _otpFocusNode = FocusNode();

//   late final AnimationController _animController;
//   late final Animation<double> _fadeIn;
//   late final Animation<Offset> _slideUp;

//   Timer? _timer;
//   int _remainingSeconds = 60;
//   bool _canResend = false;
//   bool _isVerifying = false;

//   @override
//   void initState() {
//     super.initState();

//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );

//     _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animController, curve: Curves.easeOut),
//     );

//     _slideUp = Tween<Offset>(
//       begin: const Offset(0, 0.15),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

//     _animController.forward();
//     _startTimer();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _otpFocusNode.requestFocus();
//     });
//   }

//   void _startTimer() {
//     _remainingSeconds = 60;
//     _canResend = false;

//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_remainingSeconds == 0) {
//         timer.cancel();
//         setState(() => _canResend = true);
//       } else {
//         setState(() => _remainingSeconds--);
//       }
//     });
//   }

//   Future<void> _verifyOtp(String otp) async {
//     setState(() => _isVerifying = true);

//     final auth = Provider.of<AuthProvider>(context, listen: false);
//     bool success = false;


//     if (widget.isForgotPassword) {
//       // OTP verified for password reset → go to reset password screen
//       success = await auth.verifyResetOtp(
//         countryCode: '+91',
//         mobileNumber: widget.phoneNumber,
//         otp: otp,
//       );

//       if (success && mounted) {
//         Navigator.pushReplacementNamed(
//           context,
//           '/reset-password',
//           arguments: widget.phoneNumber,
//         );
//       }
//     }

//     else if (widget.isNewUser) {
//       // Signup OTP verify
//       success = await auth.verifySignupOtp(
//         countryCode: '+91',
//         mobileNumber: widget.phoneNumber,
//         otp: otp,
        
//       );

//       if (success && mounted) {
//         Navigator.of(context).pushAndRemoveUntil(
//           MaterialPageRoute(builder: (_) => const NameScreen()),
//           (route) => false,
//         );
//       }
//     }

//     else {
//       // Login OTP verify
//       success = await auth.verifyLoginOtp(
//         '+91',
//         widget.phoneNumber,
//         otp,
//       );

//       if (success && mounted) {
//         Navigator.of(context).pushAndRemoveUntil(
//           MaterialPageRoute(builder: (_) => const MainLayout()),
//           (route) => false,
//         );
//       }
//     }

//     setState(() => _isVerifying = false);

//     if (!success && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(auth.error ?? 'Invalid OTP'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       _otpController.clear();
//       _otpFocusNode.requestFocus();
//     }
//   }

//   void _resendOtp() {
//     if (!_canResend) return;

//     _startTimer();
//     _otpController.clear();
//     _otpFocusNode.requestFocus();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('OTP resent successfully'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _animController.dispose();
//     _otpController.dispose();
//     _otpFocusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final bottomPadding = MediaQuery.of(context).padding.bottom;

//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: SystemUiOverlayStyle(
//         statusBarColor: Colors.transparent,
//         statusBarIconBrightness:
//             isDark ? Brightness.light : Brightness.dark,
//       ),
//       child: Scaffold(
//         body: SafeArea(
//           child: SlideTransition(
//             position: _slideUp,
//             child: FadeTransition(
//               opacity: _fadeIn,
//               child: Padding(
//                 padding: EdgeInsets.fromLTRB(
//                   24,
//                   0,
//                   24,
//                   bottomPadding + 16,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [

//                     const SizedBox(height: 40),

//                     const Text(
//                       "Verify OTP",
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),

//                     const SizedBox(height: 8),

//                     Text(
//                       "Sent to ${widget.phoneNumber}",
//                       style: const TextStyle(color: Colors.grey),
//                     ),

//                     const SizedBox(height: 40),

//                     Center(child: _buildPinput(isDark)),

//                     const SizedBox(height: 24),

//                     Center(
//                       child: _canResend
//                           ? TextButton(
//                               onPressed: _resendOtp,
//                               child: const Text("Resend OTP"),
//                             )
//                           : Text(
//                               "Resend in 00:${_remainingSeconds.toString().padLeft(2, '0')}",
//                             ),
//                     ),

//                     const SizedBox(height: 40),

//                     SizedBox(
//                       width: double.infinity,
//                       height: 55,
//                       child: ElevatedButton(
//                         onPressed: _isVerifying
//                             ? null
//                             : () {
//                                 final otp = _otpController.text;
//                                 if (otp.length == 6) _verifyOtp(otp);
//                               },
//                         child: _isVerifying
//                             ? const CircularProgressIndicator()
//                             : const Text("Verify"),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPinput(bool isDark) {
//     return Pinput(
//       length: 6,
//       controller: _otpController,
//       focusNode: _otpFocusNode,
//       keyboardType: TextInputType.number,
//       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//       onCompleted: _verifyOtp,
//     );
//   }
// }