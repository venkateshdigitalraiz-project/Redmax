import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/four_digit_otp_input.dart';

class AuthWelcomePage extends StatefulWidget {
  const AuthWelcomePage({super.key});

  @override
  State<AuthWelcomePage> createState() => _AuthWelcomePageState();
}

class _AuthWelcomePageState extends State<AuthWelcomePage> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  String _otpCode = '';

  bool get _isPhoneValid => _phoneController.text.trim().length == 10;
  bool get _isOtpValid => _otpCode.trim().length == 4;

  @override
  void initState() {
    super.initState();
    final blocPhone = context.read<AuthBloc>().state.phoneNumber;
    if (blocPhone.isNotEmpty) {
      _phoneController.text = blocPhone;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _onSubmitOtp() {
    if (!_isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
          SendPhoneOtpEvent(_phoneController.text.trim()),
        );
  }

  void _onVerifyOtp() {
    if (!_isOtpValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 4-digit OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final phone = _phoneController.text.trim().isNotEmpty
        ? _phoneController.text.trim()
        : context.read<AuthBloc>().state.phoneNumber;

    context.read<AuthBloc>().add(
          VerifyPhoneOtpEvent(
            phoneNumber: phone.isNotEmpty ? phone : '9876543210',
            otp: _otpCode.trim(),
          ),
        );
  }

  void _onEditPhoneNumber() {
    setState(() {
      _otpCode = '';
    });
    context.read<AuthBloc>().add(EditPhoneNumberEvent());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_phoneFocusNode.canRequestFocus) {
        _phoneFocusNode.requestFocus();
        _phoneController.selection = TextSelection.fromPosition(
          TextPosition(offset: _phoneController.text.length),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
              ),
            );
          }
          if (state.status == AuthStatus.authenticated) {
            context.go(AppRoutes.main);
          }
        },
        builder: (context, state) {
          final bool isOtpSent = state.isOtpSent;
          final bool isSubmittingOtp = state.status == AuthStatus.loading && !isOtpSent;
          final bool isVerifyingOtp = state.status == AuthStatus.loading && isOtpSent;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // App Brand Logo & Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.chipBackground,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.directions_car_filled,
                              size: 44,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Pathway',
                          style: AppTypography.displayLarge.copyWith(
                            color: AppColors.primaryNavy,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Smart mobility & rides at your fingertips',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // STEP 1: If OTP is NOT yet sent -> Show 10-digit mobile input
                  if (!isOtpSent) ...[
                    Text(
                      'Mobile number',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.primaryNavy,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isPhoneValid ? AppColors.primary : AppColors.border,
                          width: _isPhoneValid ? 1.5 : 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Country Code Prefix
                          Row(
                            children: [
                              const Text(
                                '🇮🇳 +91',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 1.5,
                                height: 24,
                                color: AppColors.border,
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                          // 10-digit textfield (strictly 10 digits, never accepts more)
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              style: AppTypography.bodyLarge.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: 1.5,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: InputDecoration(
                                hintText: 'Enter 10-digit number',
                                hintStyle: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0,
                                ),
                                counterText: '',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          if (_phoneController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _phoneController.clear();
                                setState(() {});
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.cancel,
                                  size: 18,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                          if (_isPhoneValid)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Accepts exactly 10 digits',
                      style: AppTypography.bodySmall.copyWith(
                        color: _phoneController.text.isNotEmpty && !_isPhoneValid
                            ? AppColors.error
                            : AppColors.textTertiary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Button: "Submit OTP"
                    CustomButton(
                      text: 'Submit OTP',
                      isLoading: isSubmittingOtp,
                      icon: Icons.send_rounded,
                      backgroundColor: _isPhoneValid ? AppColors.primary : AppColors.textDisabled,
                      onPressed: _isPhoneValid && !isSubmittingOtp ? _onSubmitOtp : null,
                    ),
                  ]

                  // STEP 2: When OTP is sent -> Display verified phone with Edit option, OTP text, 4-digit box, and "Verification OTP" button
                  else ...[
                    // Mobile number display with "Edit" option
                    InkWell(
                      onTap: isVerifyingOtp ? null : _onEditPhoneNumber,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F5F8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.phone_android,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mobile number',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '+91 ${_phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : state.phoneNumber}',
                                    style: AppTypography.titleMedium.copyWith(
                                      color: AppColors.primaryNavy,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Edit Badge Button
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.edit_outlined,
                                    size: 15,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Edit',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Next line: OTP text and 4-digit box
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enter 4-digit OTP',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.primaryNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        InkWell(
                          onTap: isSubmittingOtp ? null : _onSubmitOtp,
                          child: Text(
                            isSubmittingOtp ? 'Sending...' : 'Resend OTP',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FourDigitOtpInput(
                      onChanged: (val) {
                        setState(() {
                          _otpCode = val;
                        });
                      },
                      onCompleted: (val) {
                        setState(() {
                          _otpCode = val;
                        });
                        _onVerifyOtp();
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enter 4-digit code (e.g. 1 2 3 4)',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        InkWell(
                          onTap: isVerifyingOtp ? null : _onEditPhoneNumber,
                          child: Text(
                            'Change mobile number',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Button: "Verification OTP"
                    CustomButton(
                      text: 'Verification OTP',
                      isLoading: isVerifyingOtp,
                      icon: Icons.verified_user_outlined,
                      backgroundColor: _isOtpValid ? AppColors.primary : AppColors.textDisabled,
                      onPressed: _isOtpValid && !isVerifyingOtp ? _onVerifyOtp : null,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Continue as Guest Option
                  Center(
                    child: TextButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(ContinueAsGuestEvent());
                      },
                      child: Text(
                        'Skip for now · Continue as Guest',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'By continuing, you accept our Terms of Service & Privacy Policy.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
