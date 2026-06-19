import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _otpController =
      TextEditingController();

  bool _otpSent = false;

  bool _isPhoneValid = false;

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;

  @override
  void initState() {
    super.initState();

    _phoneController.addListener(() {
      final phone = _phoneController.text.replaceAll(
        RegExp(r'\D'),
        '',
      );

      setState(() {
        _isPhoneValid = phone.length == 10;
      });
    });

    _otpController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isSendingOtp = true;
    });

    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final success = await auth.sendResetOtp(
      countryCode: '+91',
      phone: _phoneController.text.trim(),
    );

    setState(() {
      _isSendingOtp = false;
    });

    if (!mounted) return;

    if (success) {
      setState(() {
        _otpSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'OTP sent successfully',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.error ?? 'Failed to send OTP',
          ),
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    if (_otpController.text.trim().length != 6) {
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final success = await auth.verifyResetOtp(
      countryCode: '+91',
      phone: _phoneController.text.trim(),
      otp: _otpController.text.trim(),
    );

    setState(() {
      _isVerifyingOtp = false;
    });

    if (!mounted) return;

    if (success) {

      final cleanTenDigitPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            phone: cleanTenDigitPhone,
            
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.error ?? 'Invalid OTP',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.lock_reset,
                size: 80,
                color: AppColors.primary,
              ),

              const SizedBox(height: 24),

              const Text(
                'Reset Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _otpSent
                    ? 'Enter the OTP sent to your phone'
                    : 'Enter your registered phone number',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              TextField(
                controller: _phoneController,
                enabled: !_otpSent,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon:
                      const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              if (_otpSent) ...[
                const SizedBox(height: 20),

                TextField(
                  controller: _otpController,
                  keyboardType:
                      TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'OTP',
                    hintText: 'Enter 6 digit OTP',
                    prefixIcon:
                        const Icon(Icons.password),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isSendingOtp
                        ? null
                        : _sendOtp,
                    child: const Text(
                      'Resend OTP',
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _otpSent
                      ? (_otpController.text.length ==
                                  6 &&
                              !_isVerifyingOtp
                          ? _verifyOtp
                          : null)
                      : (_isPhoneValid &&
                              !_isSendingOtp
                          ? _sendOtp
                          : null),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor:
                        Colors.white,
                  ),
                  child: _otpSent
                      ? (_isVerifyingOtp
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Verify OTP',
                            ))
                      : (_isSendingOtp
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Send OTP',
                            )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}