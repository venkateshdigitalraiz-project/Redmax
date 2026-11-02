import 'package:flutter/material.dart';
import 'package:pathway/core/theme/app_colors.dart';
import 'package:pathway/core/widgets/carpool_painters.dart';

class CarpoolGradientBackground extends StatelessWidget {
  const CarpoolGradientBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: AppColors.pageGradient),
    child: child,
  );
}

class CarpoolCard extends StatelessWidget {
  const CarpoolCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
    return onTap == null ? box : GestureDetector(onTap: onTap, child: box);
  }
}

class CarpoolPrimaryButton extends StatelessWidget {
  const CarpoolPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.isLoading = false,
    this.height = 52,
    this.gradient = AppColors.primaryGradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool isLoading;
  final double height;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 6),
                    Icon(trailingIcon, color: Colors.white, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}

class CarpoolSoftButton extends StatelessWidget {
  const CarpoolSoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primary,
    this.background = AppColors.lilac,
    this.borderColor,
    this.icon,
    this.height = 42,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color background;
  final Color? borderColor;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(height / 2),
          border: borderColor == null
              ? null
              : Border.all(color: borderColor!, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CarpoolSegmentedTabs extends StatelessWidget {
  const CarpoolSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 38,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < labels.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 10),
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: i == selectedIndex
                        ? AppColors.primaryGradient
                        : null,
                    color: i == selectedIndex
                        ? null
                        : Colors.white.withOpacity(.85),
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: i == selectedIndex
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: i == selectedIndex
                          ? Colors.white
                          : AppColors.adminDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CarpoolRoundIconButton extends StatelessWidget {
  const CarpoolRoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.background = Colors.transparent,
    this.color = AppColors.adminDark,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: size * .55, color: color),
    ),
  );
}

class CarpoolPageHeader extends StatelessWidget {
  const CarpoolPageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.showBack = true,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          if (showBack)
            CarpoolRoundIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack ?? () => Navigator.maybePop(context),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ),
          trailing ?? const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class CarpoolAvatar extends StatelessWidget {
  const CarpoolAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.icon,
    this.ring = false,
  });

  final String name;
  final double size;
  final IconData? icon;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB9A6FF), Color(0xFF6B4BE8)],
        ),
      ),
      child: icon != null
          ? Icon(icon, color: Colors.white, size: size * .5)
          : Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: size * .42,
              ),
            ),
    );
    if (!ring) return inner;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: inner,
    );
  }
}

class CarpoolRatingRow extends StatelessWidget {
  const CarpoolRatingRow({super.key, required this.rating, this.trips});
  final double rating;
  final int? trips;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.star_rounded, color: AppColors.star, size: 16),
      const SizedBox(width: 2),
      Text(
        rating.toStringAsFixed(1),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      if (trips != null)
        Text(
          ' ($trips trips)',
          style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
        ),
    ],
  );
}

class CarpoolStepper extends StatelessWidget {
  const CarpoolStepper({
    super.key,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData i, VoidCallback f) => GestureDetector(
      onTap: f,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: AppColors.lilac,
          shape: BoxShape.circle,
        ),
        child: Icon(i, size: 18, color: AppColors.primary),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove, onMinus),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        btn(Icons.add, onPlus),
      ],
    );
  }
}

class CarpoolBadge extends StatelessWidget {
  const CarpoolBadge({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    width: 17,
    height: 17,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Color(0xFFEF4444),
      shape: BoxShape.circle,
    ),
    child: Text(
      '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        height: 1.0,
      ),
    ),
  );
}

class CarpoolSectionHeader extends StatelessWidget {
  const CarpoolSectionHeader({super.key, required this.title, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const Spacer(),
      if (onSeeAll != null)
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            'See All →',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
    ],
  );
}

/// Car illustration placeholder (swap for a real asset image later).
class CarpoolCarIllustration extends StatelessWidget {
  const CarpoolCarIllustration({super.key, this.size = 110});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: size * 1.2,
          height: size * .14,
          margin: EdgeInsets.only(bottom: size * .02),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: AppColors.primaryDeep.withOpacity(.25),
          ),
        ),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFB8C2E0)],
          ).createShader(r),
          child: Icon(
            Icons.directions_car_filled_rounded,
            size: size,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class CarpoolSkylineHeader extends StatelessWidget {
  const CarpoolSkylineHeader({
    super.key,
    this.height = 170,
    this.carSize = 160,
  });

  final double height;
  final double carSize;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: MediaQuery.of(context).size.width,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: const CarpoolSkylinePainter()),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Transform.flip(
            flipX: true,
            child: Image.asset(
              'assets/images/rider_image.jpg',
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.directions_car,
                  size: 70,
                  color: Colors.white,
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}

class CarpoolBottomNav extends StatelessWidget {
  const CarpoolBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
    this.unreadMessages = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;
  final int unreadMessages;

  @override
  Widget build(BuildContext context) {
    Widget item(int index, IconData icon, String label, {int badge = 0}) {
      final selected = currentIndex == index;
      final color = selected ? const Color(0xFF3815D8) : const Color(0xFF8A86AA);
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 26),
                  if (badge > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: CarpoolBadge(count: badge),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3BF5).withOpacity(.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              item(0, Icons.home_rounded, 'Home'),
              item(1, Icons.directions_car_rounded, 'Your Rides'),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -10),
                  child: GestureDetector(
                    onTap: onCenterTap,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF5D24F7),
                            Color(0xFF300AB3),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4C1CDD).withOpacity(.38),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              item(
                3,
                Icons.chat_bubble_outline_rounded,
                'Messages',
                badge: unreadMessages,
              ),
              item(4, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
