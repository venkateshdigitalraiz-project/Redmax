import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/features/auth/presentation/bloc/auth_state.dart';
import 'package:pathway/features/carpool/presentation/pages/carpool_shell_page.dart';
import 'package:pathway/features/party_booking/presentation/pages/party_shell_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entities/dashboard_service_item.dart';
import '../../domain/entities/recent_activity_entry.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/recent_activity_section.dart';
import '../widgets/service_grid_card.dart';
import 'dashboard_home_page.dart';

class DashboardShellPage extends StatefulWidget {
  const DashboardShellPage({super.key});

  @override
  State<DashboardShellPage> createState() => _DashboardShellPageState();
}

class _DashboardShellPageState extends State<DashboardShellPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _navAnimController;

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    super.dispose();
  }

  void _onOpenCarpool() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CarpoolShellPage()),
    );
  }

  void _onOpenPartyBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PartyShellPage()),
    );
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _navAnimController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> tabs = [
      DashboardHomePage(
        onOpenCarpool: _onOpenCarpool,
        onOpenPartyBooking: _onOpenPartyBooking,
        onOpenActiveRide: _onOpenCarpool,
        onSeeAllActivity: () => _onTabTapped(2),
      ),
      _buildServicesTab(isDark),
      _buildActivityTab(isDark),
      _buildAccountTab(isDark),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  // ── Bottom Navigation Bar matching screenshot ──────────────────────────────
  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorderLight : const Color(0xFFF1F5F9),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.directions_car_outlined,
                    activeIcon: Icons.directions_car_filled_rounded,
                    label: 'Services',
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.access_time_rounded,
                    activeIcon: Icons.access_time_filled_rounded,
                    label: 'Activity',
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Account',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            // iOS Home Indicator Pill
            Center(
              child: Container(
                width: 135,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white30 : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFF0077F6);
    const inactiveColor = Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            // Active blue indicator pill underneath Home
            Container(
              width: 32,
              height: 2.5,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Services Tab ───────────────────────────────────────────────────────────
  Widget _buildServicesTab(bool isDark) {
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('All Services'),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final services = state.data?.services ?? [];
          if (services.isEmpty && state.status == DashboardStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0077F6),
                strokeWidth: 2.5,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore available services & mobility options',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.75,
                  ),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return ServiceGridCard(
                      service: service,
                      onTap: () {
                        if (service.type == DashboardServiceType.carpool) {
                          _onOpenCarpool();
                        } else if (service.type ==
                            DashboardServiceType.partyBooking) {
                          _onOpenPartyBooking();
                        } else {
                          _showComingSoonDialog(context, service.title, isDark);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Activity Tab ───────────────────────────────────────────────────────────
  Widget _buildActivityTab(bool isDark) {
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Activity History'),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final activities = state.data?.recentActivities ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: RecentActivitySection(
              activities: activities,
              onSeeAll: () {},
              onActivityTap: (activity) {
                if (activity.type == ActivityType.carpool) {
                  _onOpenCarpool();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${activity.title} (${activity.subtitle}) details',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  // ── Account Tab ────────────────────────────────────────────────────────────
  Widget _buildAccountTab(bool isDark) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final displayName = user?.fullName.isNotEmpty == true
            ? user!.fullName
            : (user?.firstName.isNotEmpty == true
                  ? user!.firstName
                  : 'Pathway User');
        final emailOrPhone = user?.phoneNumber.isNotEmpty == true
            ? user!.phoneNumber
            : (user?.email.isNotEmpty == true ? user!.email : '+91 9876543210');

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('My Account'),
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                // Profile header card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorderLight
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF0077F6),
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              emailOrPhone,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${user?.rating ?? 4.9}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${user?.ridesCompleted ?? 12} rides',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Account settings group
                _buildSettingsGroup(
                  isDark: isDark,
                  title: 'Account & Preferences',
                  items: [
                    _SettingsItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal Info',
                      subtitle: 'Edit your name, phone & details',
                      onTap: () {},
                    ),
                    _SettingsItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Trip alerts, offers and updates',
                      onTap: () {},
                    ),
                    _SettingsItem(
                      icon: Icons.security_rounded,
                      title: 'Security & Privacy',
                      subtitle: 'Manage passwords and account safety',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSettingsGroup(
                  isDark: isDark,
                  title: 'Support & More',
                  items: [
                    _SettingsItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help Center',
                      subtitle: 'FAQs, contact support & feedback',
                      onTap: () {},
                    ),
                    _SettingsItem(
                      icon: Icons.info_outline_rounded,
                      title: 'About Pathway',
                      subtitle: 'Version 1.0.0+1',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, isDark),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsGroup({
    required bool isDark,
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? AppColors.darkBorderLight : const Color(0xFFE2E8F0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF64748B),
                  letterSpacing: 0.3,
                ),
              ),
            ),
            for (int i = 0; i < items.length; i++) ...[
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0077F6).withAlpha(20)
                        : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    items[i].icon,
                    size: 20,
                    color: const Color(0xFF0077F6),
                  ),
                ),
                title: Text(
                  items[i].title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  items[i].subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
                onTap: items[i].onTap,
              ),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  indent: 56,
                  color: isDark
                      ? AppColors.darkBorderLight
                      : const Color(0xFFF1F5F9),
                ),
            ],
          ],
        ),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Text(
          'Log Out',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of Pathway?',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AuthBloc>().add(LogoutEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(
    BuildContext context,
    String serviceName,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Color(0xFF0077F6), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$serviceName Module',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '$serviceName service is being integrated and will be available soon!',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Got it',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0077F6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
