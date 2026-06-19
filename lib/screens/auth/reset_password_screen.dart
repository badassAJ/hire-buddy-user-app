import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String phone;

  const ResetPasswordScreen({
    super.key,
    required this.phone,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _passwordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isValid = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

    _passwordController.addListener(_validate);
    _confirmPasswordController.addListener(_validate);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeIn = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );

    _animController.forward();
  }

  void _validate() {
    final password =
        _passwordController.text.trim();

    final confirmPassword =
        _confirmPasswordController.text.trim();

    setState(() {
      _isValid =
          password.length >= 6 &&
          password == confirmPassword;
    });
  }

  Future<void> _resetPassword() async {
    if (!_isValid) return;

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final success = await auth.resetPassword(
      phone: widget.phone,
      newPassword:
          _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset successfully',
          ),
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 1200),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.error ??
                'Password reset failed',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return AnnotatedRegion<
        SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark
                ? Brightness.light
                : Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          child: SlideTransition(
            position: _slideUp,
            child: FadeTransition(
              opacity: _fadeIn,
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.grey800
                              : AppColors.grey100,
                          borderRadius:
                              BorderRadius.circular(
                                12,
                              ),
                        ),
                        child: const Icon(
                          Icons
                              .arrow_back_ios_new_rounded,
                          size: 18,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 40,
                    ),

                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape:
                              BoxShape.circle,
                          color: AppColors
                              .primary
                              .withValues(
                                alpha: 0.12,
                              ),
                        ),
                        child: const Icon(
                          Icons.lock_reset,
                          size: 42,
                          color:
                              AppColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    const Text(
                      'Set New Password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      'Create a strong password for your account.',
                      style: TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    TextField(
                      controller:
                          _passwordController,
                      obscureText:
                          _obscurePassword,
                      decoration:
                          InputDecoration(
                            hintText:
                                'New Password',
                            prefixIcon:
                                const Icon(
                                  Icons.lock,
                                ),
                            suffixIcon:
                                IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons
                                            .visibility
                                        : Icons
                                            .visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword =
                                          !_obscurePassword;
                                    });
                                  },
                                ),
                          ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextField(
                      controller:
                          _confirmPasswordController,
                      obscureText:
                          _obscureConfirmPassword,
                      decoration:
                          InputDecoration(
                            hintText:
                                'Confirm Password',
                            prefixIcon:
                                const Icon(
                                  Icons.lock_outline,
                                ),
                            suffixIcon:
                                IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons
                                            .visibility
                                        : Icons
                                            .visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                          ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    if (_confirmPasswordController
                            .text
                            .isNotEmpty &&
                        _passwordController.text !=
                            _confirmPasswordController
                                .text)
                      const Text(
                        'Passwords do not match',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            _isValid &&
                                    !_isLoading
                                ? _resetPassword
                                : null,
                        style:
                            ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors
                                      .primary,
                              foregroundColor:
                                  Colors.white,
                              shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                          14,
                                        ),
                                  ),
                            ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color:
                                          Colors
                                              .white,
                                    ),
                              )
                            : const Text(
                                'Reset Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}