import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class NameInputPage extends StatefulWidget {
  final String email;
  final bool optOutMarketing;
  final String phoneNumber;

  const NameInputPage({
    super.key,
    this.email = '',
    this.optOutMarketing = false,
    this.phoneNumber = '',
  });

  @override
  State<NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();

  bool get _isValid => _firstNameCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  void _onNext() {
    if (!_isValid) return;

    if (widget.email.isNotEmpty) {
      context.read<AuthBloc>().add(
            RegisterWithEmailEvent(
              email: widget.email,
              firstName: _firstNameCtrl.text.trim(),
              lastName: _lastNameCtrl.text.trim(),
              optOutMarketing: widget.optOutMarketing,
            ),
          );
    } else {
      context.read<AuthBloc>().add(
            SaveProfileNameEvent(
              firstName: _firstNameCtrl.text.trim(),
              lastName: _lastNameCtrl.text.trim(),
            ),
          );
    }

    context.go(AppRoutes.main);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy, size: 24),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Big bold title matching BlaBlaCar Screenshot 2
              Text(
                "What's your name?",
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 24),
              // First name input
              _buildSoftInputField(
                controller: _firstNameCtrl,
                hintText: 'First name',
                autofocus: true,
              ),
              const SizedBox(height: 12),
              // Last name input
              _buildSoftInputField(
                controller: _lastNameCtrl,
                hintText: 'Last name',
              ),
              const Spacer(),
              // Floating bottom right circle forward button
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: InkWell(
                    onTap: _isValid ? _onNext : null,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _isValid ? AppColors.primary : AppColors.textDisabled.withAlpha(80),
                        shape: BoxShape.circle,
                        boxShadow: _isValid
                            ? const [
                                BoxShadow(
                                  color: Color(0x3300AFF5),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoftInputField({
    required TextEditingController controller,
    required String hintText,
    bool autofocus = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: (_) => setState(() {}),
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }
}
