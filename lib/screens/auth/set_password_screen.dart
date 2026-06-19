import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../main_layout.dart';

class SetPasswordScreen extends StatefulWidget {
  final String fullName;
  final String phone;
  final String countryCode;

  const SetPasswordScreen({
    super.key,
    required this.fullName,
    required this.phone,
    required this.countryCode,
  });

  @override
  State<SetPasswordScreen> createState() =>
      _SetPasswordScreenState();
}

class _SetPasswordScreenState
    extends State<SetPasswordScreen> {
  final _passwordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> _completeRegistration() async {

    if (_isLoading) return;
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final auth =
        Provider.of<AuthProvider>(
          context,
          listen: false,
        );

    final success =
        await auth.createAccount(
          fullName: widget.fullName,
          countryCode: widget.countryCode,
          phone: widget.phone,
          password: _passwordController.text.trim(),
        );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainLayout(),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.error ??
                'Registration failed',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Create Password',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Secure your account with a strong password',
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 40),

                // Password
                TextFormField(
                  controller:
                      _passwordController,
                  obscureText:
                      _obscurePassword,
                  decoration:
                      InputDecoration(
                        labelText: 'Password',
                        hintText:
                            'Minimum 6 characters',
                        prefixIcon:
                            const Icon(
                              Icons.lock_outline,
                            ),
                        suffixIcon:
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword =
                                      !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons
                                          .visibility_outlined
                                    : Icons
                                          .visibility_off_outlined,
                              ),
                            ),
                        border:
                            OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                    14,
                                  ),
                            ),
                      ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Password is required';
                    }

                    if (value.length < 6) {
                      return 'Minimum 6 characters required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Confirm Password
                TextFormField(
                  controller:
                      _confirmPasswordController,
                  obscureText:
                      _obscureConfirmPassword,
                  decoration:
                      InputDecoration(
                        labelText:
                            'Confirm Password',
                        hintText:
                            'Re-enter password',
                        prefixIcon:
                            const Icon(
                              Icons.lock_outline,
                            ),
                        suffixIcon:
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons
                                          .visibility_outlined
                                    : Icons
                                          .visibility_off_outlined,
                              ),
                            ),
                        border:
                            OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                    14,
                                  ),
                            ),
                      ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Confirm your password';
                    }

                    if (value !=
                        _passwordController
                            .text) {
                      return 'Passwords do not match';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Container(
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.security,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Use a strong password with letters, numbers and symbols.',
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _completeRegistration,
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primary,
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
                            height: 22,
                            width: 22,
                            child:
                                CircularProgressIndicator(
                                  color:
                                      Colors.white,
                                  strokeWidth:
                                      2,
                                ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w600,
                            ),
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