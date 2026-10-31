import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;
  final String locationCity;
  final int unreadNotifications;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onLocationTap;

  const DashboardHeader({
    super.key,
    required this.userName,
    required this.locationCity,
    required this.unreadNotifications,
    this.onNotificationTap,
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Royal Purple Gradient Container with Charminar blend
        Container(
          width: double.infinity,
          height: topPadding + 195,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5B3BF5), Color(0xFF482AD9), Color(0xFF381CB4)],
            ),
          ),
          child: Stack(
            children: [
              // Luminous curved radial glow matching screenshot
              Positioned(
                top: -30,
                left: 60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF8B75FF).withAlpha(110),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(18),
                  ),
                ),
              ),

              // Full-color Charminar photo extending all the way to top: 0 to remove top-right gap
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: 175,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0.0, 0.40, 1.0],
                      colors: [Colors.transparent, Colors.white, Colors.white],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/images/charminar.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    opacity: const AlwaysStoppedAnimation(0.92),
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom curved wave transition into page background
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
        ),

        // Foreground content (Location, Notification, Greeting)
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar Row: Location Pill + Notification Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Location Pill
                    GestureDetector(
                      onTap: onLocationTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Color(0xFF1E293B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              locationCity,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Color(0xFF1E293B),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Notification Button with Badge
                    GestureDetector(
                      onTap: onNotificationTap,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(20),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              size: 20,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          if (unreadNotifications > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$unreadNotifications',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Greeting & Subtitle
                Text(
                  'Hi, $userName 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your all-in-one travel & services hub',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(235),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
