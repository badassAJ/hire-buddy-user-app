// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:pinput/pinput.dart';
// import 'package:provider/provider.dart';
// import '../../core/theme/app_colors.dart';
// import '../../providers/auth_provider.dart';
// import '../main_layout.dart';

// class EmailVerifyScreen extends StatefulWidget {
//   final String email;

//   const EmailVerifyScreen({super.key, required this.email});

//   @override
//   State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
// }

// class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
//   final TextEditingController _otpController = TextEditingController();
//   final FocusNode _otpFocusNode = FocusNode();

//   Timer? _timer;
//   int _remainingSeconds = 60;
//   bool _canResend = false;
//   bool _isVerifying = false;

//   @override
//   void initState() {
//     super.initState();
//     _startTimer();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _otpFocusNode.requestFocus();
//     });
//   }

//   void _startTimer() {
//     _remainingSeconds = 60;
//     _canResend = false;
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (_remainingSeconds == 0) {
//         t.cancel();
//         setState(() => _canResend = true);
//       } else {
//         setState(() => _remainingSeconds--);
//       }
//     });
//   }

//   Future<void> _verify(String otp) async {
//     setState(() => _isVerifying = true);
//     final auth = Provider.of<AuthProvider>(context, listen: false);
//     final ok = await auth.verifyEmailOtp(email: widget.email, otp: otp);
//     if (!mounted) return;
//     setState(() => _isVerifying = false);

//     if (ok) {
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (_) => const MainLayout()),
//         (r) => false,
//       );
//     } else {
//       _otpController.clear();
//       _otpFocusNode.requestFocus();
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text(auth.error ?? 'Invalid OTP'),
//         backgroundColor: AppColors.error,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(16),
//       ));
//     }
//   }

//   Future<void> _resend() async {
//     if (!_canResend) return;
//     _otpController.clear();
//     _otpFocusNode.requestFocus();
//     _startTimer();
//     final auth = Provider.of<AuthProvider>(context, listen: false);
//     final ok = await auth.resendEmailVerification(email: widget.email);
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(ok ? 'OTP sent to ${widget.email}' : auth.error ?? 'Failed'),
//       backgroundColor: ok ? AppColors.success : AppColors.error,
//       behavior: SnackBarBehavior.floating,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       margin: const EdgeInsets.all(16),
//     ));
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _otpController.dispose();
//     _otpFocusNode.dispose();
//     super.dispose();
//   }

//   Widget _buildPinput(bool isDark) {
//     final defaultPinTheme = PinTheme(
//       width: 52,
//       height: 60,
//       textStyle: TextStyle(
//         fontSize: 22,
//         fontWeight: FontWeight.w700,
//         color: isDark ? Colors.white : AppColors.textPrimary,
//       ),
//       decoration: BoxDecoration(
//         color: isDark ? AppColors.grey800 : AppColors.grey50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isDark ? AppColors.grey700 : AppColors.grey200,
//           width: 1,
//         ),
//       ),
//     );

//     return Pinput(
//       length: 6,
//       controller: _otpController,
//       focusNode: _otpFocusNode,
//       defaultPinTheme: defaultPinTheme,
//       focusedPinTheme: defaultPinTheme.copyWith(
//         decoration: defaultPinTheme.decoration!.copyWith(
//           border: Border.all(color: AppColors.primary, width: 2),
//         ),
//       ),
//       submittedPinTheme: defaultPinTheme.copyWith(
//         decoration: defaultPinTheme.decoration!.copyWith(
//           border: Border.all(
//             color: isDark ? AppColors.grey600 : AppColors.grey300,
//             width: 1,
//           ),
//         ),
//       ),
//       separatorBuilder: (_) => const SizedBox(width: 8),
//       pinputAutovalidateMode: PinputAutovalidateMode.disabled,
//       keyboardType: TextInputType.number,
//       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//       autofillHints: const [AutofillHints.oneTimeCode],
//       hapticFeedbackType: HapticFeedbackType.lightImpact,
//       closeKeyboardWhenCompleted: true,
//       onCompleted: _verify,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final bottomPadding = MediaQuery.of(context).padding.bottom;

//     return Scaffold(
//       body: SafeArea(
//         bottom: false,
//         child: CustomScrollView(
//           slivers: [
//             SliverFillRemaining(
//               hasScrollBody: false,
//               child: Padding(
//                 padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 8),
//                     GestureDetector(
//                       onTap: () => Navigator.of(context).pop(),
//                       child: Container(
//                         width: 44,
//                         height: 44,
//                         decoration: BoxDecoration(
//                           color: isDark ? AppColors.grey800 : AppColors.grey100,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Icon(Icons.arrow_back_ios_new_rounded,
//                             size: 18,
//                             color: isDark
//                                 ? AppColors.grey300
//                                 : AppColors.textPrimary),
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//                     Center(
//                       child: Container(
//                         width: 100,
//                         height: 100,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: AppColors.primary.withValues(alpha: 0.12),
//                         ),
//                         child: const Icon(Icons.mark_email_read_rounded,
//                             size: 44, color: AppColors.primary),
//                       ),
//                     ),
//                     const SizedBox(height: 28),
//                     const Text(
//                       'Verify Email',
//                       style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.w800,
//                           letterSpacing: -0.5),
//                     ),
//                     const SizedBox(height: 8),
//                     Text.rich(TextSpan(
//                       text: 'We sent a 6-digit code to\n',
//                       style: TextStyle(
//                           fontSize: 15,
//                           color: AppColors.textSecondary,
//                           height: 1.5),
//                       children: [
//                         TextSpan(
//                           text: widget.email,
//                           style: TextStyle(
//                               color:
//                                   isDark ? Colors.white : AppColors.textPrimary,
//                               fontWeight: FontWeight.w600),
//                         ),
//                       ],
//                     )),
//                     const SizedBox(height: 40),
//                     Center(child: _buildPinput(isDark)),
//                     const SizedBox(height: 32),
//                     Center(
//                       child: _canResend
//                           ? GestureDetector(
//                               onTap: _resend,
//                               child: Text.rich(TextSpan(
//                                 text: "Didn't receive it? ",
//                                 style: TextStyle(
//                                     fontSize: 14,
//                                     color: AppColors.textSecondary),
//                                 children: [
//                                   TextSpan(
//                                     text: 'Resend',
//                                     style: TextStyle(
//                                         color: AppColors.primary,
//                                         fontWeight: FontWeight.w700),
//                                   ),
//                                 ],
//                               )),
//                             )
//                           : Text(
//                               'Resend in 00:${_remainingSeconds.toString().padLeft(2, '0')}',
//                               style: TextStyle(
//                                   fontSize: 14,
//                                   color: AppColors.textSecondary),
//                             ),
//                     ),
//                     const SizedBox(height: 36),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 56,
//                       child: ElevatedButton(
//                         onPressed: _isVerifying
//                             ? null
//                             : () {
//                                 final otp = _otpController.text;
//                                 if (otp.length == 6) _verify(otp);
//                               },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.primary,
//                           foregroundColor: Colors.white,
//                           disabledBackgroundColor: isDark
//                               ? AppColors.grey700
//                               : AppColors.grey200,
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(14)),
//                         ),
//                         child: _isVerifying
//                             ? const SizedBox(
//                                 width: 24,
//                                 height: 24,
//                                 child: CircularProgressIndicator(
//                                     strokeWidth: 2.5,
//                                     valueColor: AlwaysStoppedAnimation<Color>(
//                                         Colors.white)),
//                               )
//                             : const Text('Verify & Continue',
//                                 style: TextStyle(
//                                     fontSize: 17,
//                                     fontWeight: FontWeight.w600,
//                                     letterSpacing: 0.5)),
//                       ),
//                     ),
//                     const Spacer(),
//                     Center(
//                       child: TextButton(
//                         onPressed: () => Navigator.of(context)
//                             .pushAndRemoveUntil(
//                                 MaterialPageRoute(
//                                     builder: (_) => const MainLayout()),
//                                 (r) => false),
//                         child: Text('Skip for now',
//                             style: TextStyle(
//                                 color: AppColors.textSecondary,
//                                 fontSize: 14)),
//                       ),
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

