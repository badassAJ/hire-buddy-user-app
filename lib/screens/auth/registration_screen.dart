import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'registration_otp_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() =>
      _RegistrationScreenState();
}

class _RegistrationScreenState
    extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _phoneController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final auth =
        Provider.of<AuthProvider>(
          context,
          listen: false,
        );

    final success =
        await auth.sendSignupOtp(
      countryCode: '+91',
      phone:
          _phoneController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RegistrationOtpScreen(
            fullName:
                _nameController.text.trim(),
            phone:
                _phoneController.text.trim(),
                countryCode: '+91',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            auth.error ??
                'Failed to send OTP',
          ),
          backgroundColor:
              AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () =>
              Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,

              children: [
                const SizedBox(
                  height: 20,
                ),

                Text(
                  'Create Account',
                  style:
                      Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Enter your details to continue',
                  style: TextStyle(
                    color: AppColors
                        .textSecondary,
                  ),
                ),

                const SizedBox(
                  height: 40,
                ),

                TextFormField(
                  controller:
                      _nameController,
                  textCapitalization:
                      TextCapitalization
                          .words,
                  decoration:
                      InputDecoration(
                    labelText:
                        'Full Name',
                    hintText:
                        'Enter your name',
                    prefixIcon:
                        const Icon(
                      Icons
                          .person_outline,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                                  12),
                    ),
                  ),
                  validator:
                      (value) {
                    if (value ==
                            null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Name is required';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 16,
                ),

                TextFormField(
                  controller:
                      _phoneController,
                  keyboardType:
                      TextInputType
                          .phone,
                  decoration:
                      InputDecoration(
                    labelText:
                        'Phone Number',
                    hintText:
                        '10 digit number',
                    prefixIcon:
                        const Icon(
                      Icons
                          .phone_outlined,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                                  12),
                    ),
                  ),
                  validator:
                      (value) {
                    if (value ==
                            null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Phone number required';
                    }

                    if (!RegExp(
                            r'^\d{10}$')
                        .hasMatch(
                            value)) {
                      return 'Enter valid phone number';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 32,
                ),

                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _sendOtp,

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        AppColors
                            .primary,
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 16,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                                  12),
                    ),
                  ),

                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                            valueColor:
                                AlwaysStoppedAnimation(
                              Colors
                                  .white,
                            ),
                          ),
                        )
                      : const Text(
                          'Send OTP',
                          style:
                              TextStyle(
                            fontSize:
                                16,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                ),

                const SizedBox(
                  height: 24,
                ),

                Center(
                  child: Text(
                    'By continuing you agree to our Terms & Conditions',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors
                          .textSecondary,
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