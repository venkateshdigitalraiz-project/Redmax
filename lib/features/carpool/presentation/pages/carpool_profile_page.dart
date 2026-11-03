import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/carpool_nav_cubit.dart';
import '../bloc/carpool_profile_bloc.dart';
import 'carpool_settings_page.dart';
import 'carpool_splash_page.dart';
import 'carpool_wallet_page.dart';

/// CarpoolProfilePage - Matches exact design specifications:
/// Lavender gradient, top bar with back & settings gear, centered avatar with
/// white ring & shadow, user name, indigo email, golden amber "👑 Premium Member" pill,
/// and a unified white card containing 7 menu options with vibrant blue/purple icons.
class CarpoolProfilePage extends StatelessWidget {
  const CarpoolProfilePage({super.key});

  void _soon(BuildContext c, String name) {
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text('$name is coming soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log out?',
          style: TextStyle(
            color: Color(0xFF140D43),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'You will need to sign in again to access your account.',
          style: TextStyle(color: Color(0xFF6B658C)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Stay',
              style: TextStyle(
                color: Color(0xFF6B658C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<CarpoolNavCubit>().select(0);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CarpoolSplashPage()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <_ProfileMenuItem>[
      _ProfileMenuItem(
        icon: Icons.person_rounded,
        label: 'Edit Profile',
        onTap: () => _soon(context, 'Edit Profile'),
      ),
      _ProfileMenuItem(
        icon: Icons.location_on_rounded,
        label: 'Saved Locations',
        onTap: () => _soon(context, 'Saved Locations'),
      ),
      _ProfileMenuItem(
        icon: Icons.directions_car_rounded,
        label: 'My Rides',
        onTap: () => context.read<CarpoolNavCubit>().select(1),
      ),
      _ProfileMenuItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Wallet & Payments',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CarpoolWalletPage())),
      ),
      _ProfileMenuItem(
        icon: Icons.support_agent_rounded,
        label: 'Support',
        onTap: () => _soon(context, 'Support'),
      ),
      _ProfileMenuItem(
        icon: Icons.info_rounded,
        label: 'About RideMax',
        onTap: () => _soon(context, 'About RideMax'),
      ),
      _ProfileMenuItem(
        icon: Icons.logout_rounded,
        label: 'Logout',
        onTap: () => _logout(context),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEDE8FF), Color(0xFFF7F5FE), Colors.white],
            stops: [0.0, 0.40, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<CarpoolProfileBloc, CarpoolProfileState>(
            builder: (context, s) {
              final user = s.user;
              final displayName = (user != null && user.name.isNotEmpty)
                  ? user.name
                  : 'Venkatesh';
              final displayEmail = (user != null && user.email.isNotEmpty)
                  ? user.email
                  : 'venkatesh@gmail.com';
              final isPremium = user?.isPremium ?? true;

              return ListView(
                padding: const EdgeInsets.only(bottom: 28),
                children: [
                  // 1. Sleek Top Bar (Back arrow, "My Profile", Settings gear)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                    child: Row(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              context.read<CarpoolNavCubit>().select(0);
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
                          'My Profile',
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
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CarpoolSettingsPage(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.settings_outlined,
                              color: Color(0xFF140D43),
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 2. Profile Avatar with White Border & Soft Elevation
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5B3BF5).withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=300&h=300',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: const Color(0xFFEBE6FC),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 54,
                                  color: Color(0xFF3815D8),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. User Name
                  Center(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF140D43),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 4. User Email in Indigo Accent
                  Center(
                    child: Text(
                      displayEmail,
                      style: const TextStyle(
                        color: Color(0xFF3815D8),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 5. "👑 Premium Member" Golden Amber Pill Badge
                  if (isPremium)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6.5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD568), Color(0xFFFFB824)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFB824).withOpacity(0.38),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('👑', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 5),
                            Text(
                              'Premium Member',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Color(0xFF140D43),
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 22),

                  // 6. Unified White Menu Card with 7 Options & Dividers
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
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
                            for (int i = 0; i < items.length; i++) ...[
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: items[i].onTap,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      // Blue/purple icon
                                      Icon(
                                        items[i].icon,
                                        color: const Color(0xFF240DA2),
                                        size: 25,
                                      ),
                                      const SizedBox(width: 14),
                                      // Title text
                                      Expanded(
                                        child: Text(
                                          items[i].label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5,
                                            color: Color(0xFF140D43),
                                          ),
                                        ),
                                      ),
                                      // Chevron arrow
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Color(0xFF6B658C),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (i != items.length - 1)
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFF3F0FD),
                                ),
                            ],
                          ],
                        ),
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

class _ProfileMenuItem {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
