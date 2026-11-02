import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../bloc/carpool_profile_bloc.dart';

/// CarpoolSettingsPage - Matches screenshot design:
/// 1. Lavender gradient background.
/// 2. Top bar: Back arrow, "Settings" title, right tune/filter icon.
/// 3. Unified white settings card:
///    - Notification Settings (toggle switch)
///    - Language (English)
///    - Theme (Light / Dark)
///    - Privacy & Security
///    - Help & Support
///    - About RideMax
/// 4. Cosmic "Upgrade to Premium" banner with 3D gold crown & "Go Premium →" button.
class CarpoolSettingsPage extends StatelessWidget {
  final CarpoolProfileBloc? bloc;

  const CarpoolSettingsPage({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: const _SettingsView(),
      );
    }
    try {
      context.read<CarpoolProfileBloc>();
      return const _SettingsView();
    } catch (_) {
      final repo = CarpoolRepositoryImpl(CarpoolMockDataSource());
      return BlocProvider(
        create: (_) => CarpoolProfileBloc(
          getUser: CarpoolGetUserUseCase(repo),
        )..add(const CarpoolProfileStarted()),
        child: const _SettingsView(),
      );
    }
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  void _snack(BuildContext c, String name) {
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text('$name is coming soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEDE8FF),
              Color(0xFFF7F5FE),
              Colors.white,
            ],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<CarpoolProfileBloc, CarpoolProfileState>(
            builder: (context, s) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // 1. Top Bar: Back arrow, "Settings", right tune icon
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF140D43),
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF140D43),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _snack(context, 'Settings filters'),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF140D43),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 2. Unified White Settings Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFEDE8FF),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B3BF5).withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        children: [
                          // 1. Notification Settings
                          _SettingsRow(
                            icon: Icons.notifications_rounded,
                            title: 'Notification Settings',
                            subtitle: 'Manage notifications',
                            trailing: _CustomPurpleSwitch(
                              value: s.notificationsEnabled,
                              onChanged: (v) => context
                                  .read<CarpoolProfileBloc>()
                                  .add(CarpoolProfileNotificationsToggled(v)),
                            ),
                          ),
                          const _SettingsDivider(),

                          // 2. Language
                          _SettingsRow(
                            icon: Icons.translate_rounded,
                            title: 'Language',
                            subtitle: 'English',
                            onTap: () => _snack(context, 'Language'),
                          ),
                          const _SettingsDivider(),

                          // 3. Theme
                          _SettingsRow(
                            icon: Icons.nightlight_round,
                            title: 'Theme',
                            subtitle: 'Light / Dark',
                            onTap: () => _snack(context, 'Dark theme'),
                          ),
                          const _SettingsDivider(),

                          // 4. Privacy & Security
                          _SettingsRow(
                            icon: Icons.shield_rounded,
                            title: 'Privacy & Security',
                            onTap: () => _snack(context, 'Privacy & Security'),
                          ),
                          const _SettingsDivider(),

                          // 5. Help & Support
                          _SettingsRow(
                            icon: Icons.help_rounded,
                            title: 'Help & Support',
                            onTap: () => _snack(context, 'Help & Support'),
                          ),
                          const _SettingsDivider(),

                          // 6. About RideMax
                          _SettingsRow(
                            icon: Icons.info_rounded,
                            title: 'About RideMax',
                            onTap: () => _snack(context, 'About RideMax'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Cosmic "Upgrade to Premium" Banner
                  Container(
                    height: 125,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4C1CDD),
                          Color(0xFF24076C),
                          Color(0xFF10033B),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4C1CDD).withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // Warm sunset glow aura behind the crown on the left
                          Positioned(
                            left: -20,
                            top: -15,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFF9500).withOpacity(0.25),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                // 3D Golden Crown Illustration
                                const _CrownIllustration(),

                                const SizedBox(width: 14),

                                // Title, Subtitle & Go Premium Button
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Upgrade to Premium',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Get more benefits',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () =>
                                            _snack(context, 'Premium upgrade'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFFFD568),
                                                Color(0xFFFFB824),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFFB824)
                                                    .withOpacity(0.35),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Go Premium',
                                                style: TextStyle(
                                                  color: Color(0xFF140D43),
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Color(0xFF140D43),
                                                size: 15,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            // Soft periwinkle circular icon badge
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFEBE6FC),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF3815D8), size: 22),
            ),
            const SizedBox(width: 14),

            // Title & optional Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF140D43),
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Color(0xFF6B658C),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Trailing widget or default chevron arrow
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF6B658C),
                  size: 22,
                ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF3F0FD),
    );
  }
}

/// Custom purple pill switch matching screenshot
class _CustomPurpleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CustomPurpleSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value ? const Color(0xFF2E12C8) : const Color(0xFFD1D5DB),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 3D Golden Crown Graphic matching screenshot
class _CrownIllustration extends StatelessWidget {
  const _CrownIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 54,
      child: CustomPaint(
        painter: _CrownPainter(),
      ),
    );
  }
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Golden gradient for the crown body
    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD568), Color(0xFFFF9500), Color(0xFFE67E00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    // Crown body path (5 tips)
    final path = Path()
      ..moveTo(w * 0.10, h * 0.35)
      ..lineTo(w * 0.25, h * 0.55)
      ..lineTo(w * 0.50, h * 0.18) // Center tall tip
      ..lineTo(w * 0.75, h * 0.55)
      ..lineTo(w * 0.90, h * 0.35)
      ..lineTo(w * 0.82, h * 0.85) // Bottom right
      ..lineTo(w * 0.18, h * 0.85) // Bottom left
      ..close();

    // Drop shadow
    canvas.drawShadow(path, const Color(0xFFFFB800), 8, false);
    canvas.drawPath(path, crownPaint);

    // Bottom band
    final bandPaint = Paint()
      ..color = const Color(0xFFFFC043)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.82, w * 0.68, h * 0.12),
        const Radius.circular(3),
      ),
      bandPaint,
    );

    // Golden Jewels / Spheres on top of tips
    final jewelPaint = Paint()
      ..color = const Color(0xFFFFEAA7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.10, h * 0.35), 4, jewelPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.18), 5.5, jewelPaint);
    canvas.drawCircle(Offset(w * 0.90, h * 0.35), 4, jewelPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
