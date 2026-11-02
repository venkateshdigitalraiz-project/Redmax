import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';

import '../../core/party_colors.dart';
import '../../core/party_formatters.dart';
import '../../domain/entities/party_entities.dart';
import '../bloc/party_favorites_bloc.dart';

// ---------------------------------------------------------------------------
// Category visuals (id → icon + placeholder gradient)
// ---------------------------------------------------------------------------
class PartyCategoryVisual {
  const PartyCategoryVisual(this.icon, this.color, this.gradient);
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  static PartyCategoryVisual of(String id) {
    switch (id) {
      case 'birthday':
        return const PartyCategoryVisual(Icons.cake_rounded, Color(0xFFEC4899),
            [Color(0xFFFFC1D6), Color(0xFF8B2E58)]);
      case 'wedding':
        return const PartyCategoryVisual(Icons.favorite_rounded,
            Color(0xFFF59E0B), [Color(0xFFE9B96E), Color(0xFF6B4410)]);
      case 'corporate':
        return const PartyCategoryVisual(Icons.business_center_rounded,
            Color(0xFF4A21C4), [Color(0xFFB8A27A), Color(0xFF2B2013)]);
      case 'celebrations':
        return const PartyCategoryVisual(Icons.wine_bar_rounded,
            Color(0xFF9333EA), [Color(0xFFE8A04C), Color(0xFF3A1D0B)]);
      case 'baby_shower':
        return const PartyCategoryVisual(Icons.child_friendly_rounded,
            Color(0xFF0EA5E9), [Color(0xFFD9B98F), Color(0xFF3D5A3A)]);
      case 'get_together':
        return const PartyCategoryVisual(Icons.groups_rounded,
            Color(0xFFEA580C), [Color(0xFFF2B35C), Color(0xFF3A1E0B)]);
      default:
        return const PartyCategoryVisual(Icons.star_rounded, Color(0xFFF59E0B),
            [Color(0xFFE0C068), Color(0xFF3F2F0E)]);
    }
  }
}

// ---------------------------------------------------------------------------
// Image with graceful gradient fallback (no assets required)
// ---------------------------------------------------------------------------
class PartyImage extends StatelessWidget {
  const PartyImage({
    super.key,
    this.url = '',
    this.seed = 0,
    this.gradient,
    this.icon = Icons.celebration_rounded,
    this.radius = BorderRadius.zero,
    this.height,
    this.width,
    this.child,
  });

  final String url;
  final int seed;
  final List<Color>? gradient;
  final IconData icon;
  final BorderRadius radius;
  final double? height;
  final double? width;
  final Widget? child;

  static const _palette = [
    [Color(0xFFE8C27A), Color(0xFF3A2812)],
    [Color(0xFFB57BD9), Color(0xFF2A1040)],
    [Color(0xFFF0A878), Color(0xFF6B2E1B)],
    [Color(0xFF9FB8E8), Color(0xFF1E2A55)],
    [Color(0xFFE6B8A2), Color(0xFF4B2A2A)],
  ];

  Widget _fallback() {
    final colors = gradient ?? _palette[seed.abs() % _palette.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white.withOpacity(.35), size: 44),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        width: width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url.isEmpty)
              _fallback()
            else
              Image.network(url,
                  fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback()),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header bar (purple) used by Booking / My Bookings / Favorites / Profile
// ---------------------------------------------------------------------------
class PartyHeaderBar extends StatelessWidget {
  const PartyHeaderBar({
    super.key,
    required this.title,
    this.onBack,
    this.showBack = true,
    this.trailing,
    this.fillColor,
    this.gradient,
    this.borderRadius,
  });

  final String title;
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? trailing;
  final Color? fillColor;
  final Gradient? gradient;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ??
        const BorderRadius.vertical(bottom: Radius.circular(24));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: gradient == null && fillColor != null ? fillColor : null,
          gradient: gradient ??
              (fillColor == null ? PartyColors.headerGradient : null),
          borderRadius: effectiveBorderRadius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4210B7).withOpacity(0.30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 58,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Positioned(
                  left: 6,
                  child: showBack
                      ? IconButton(
                          onPressed: onBack ?? () => Navigator.maybePop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (trailing != null)
                  Positioned(right: 12, child: trailing!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons (compact pills – full width CTAs use the app's CustomButton)
// ---------------------------------------------------------------------------
class PartyPillButton extends StatelessWidget {
  const PartyPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.height = 38,
    this.horizontal = 16,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final double height;
  final double horizontal;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(height / 2),
          border: filled
              ? null
              : Border.all(color: PartyColors.primary, width: 1.4),
        ),
        child: Text(label,
            style: AppTypography.labelMedium.copyWith(
                color: PartyColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Favourite heart (reads PartyFavoritesBloc)
// ---------------------------------------------------------------------------
class PartyFavoriteButton extends StatelessWidget {
  const PartyFavoriteButton({super.key, required this.venueId, this.size = 36});
  final String venueId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PartyFavoritesBloc, PartyFavoritesState>(
      buildWhen: (p, c) => p.isFavorite(venueId) != c.isFavorite(venueId),
      builder: (context, state) {
        final fav = state.isFavorite(venueId);
        return GestureDetector(
          onTap: () =>
              context.read<PartyFavoritesBloc>().add(PartyFavoriteToggled(venueId)),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.28),
              shape: BoxShape.circle,
            ),
            child: Icon(
              fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: fav ? const Color(0xFFFF5B6E) : Colors.white,
              size: size * .56,
            ),
          ),
        );
      },
    );
  }
}

class PartyRatingRow extends StatelessWidget {
  const PartyRatingRow({super.key, required this.venue, this.fontSize = 13});
  final PartyVenueEntity venue;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: PartyColors.star, size: 18),
          const SizedBox(width: 3),
          Text(venue.rating.toStringAsFixed(1),
              style: AppTypography.bodyLarge
                  .copyWith(fontWeight: FontWeight.w700, fontSize: fontSize + 1)),
          const SizedBox(width: 4),
          Text('(${PartyFormatters.reviews(venue.reviewCount)})',
              style: AppTypography.bodyMedium.copyWith(fontSize: fontSize)),
        ],
      );
}

// ---------------------------------------------------------------------------
// Venue card (Home → Popular Venues, lists, favourites)
// ---------------------------------------------------------------------------
class PartyVenueCard extends StatelessWidget {
  const PartyVenueCard({super.key, required this.venue, required this.onTap});
  final PartyVenueEntity venue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PartyImage(
            url: venue.coverImage,
            seed: venue.id.hashCode,
            height: 170,
            width: double.infinity,
            radius: BorderRadius.circular(18),
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: PartyFavoriteButton(venueId: venue.id),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(venue.name,
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              Text('${PartyFormatters.rupee(venue.priceFrom)} onwards',
                  style: AppTypography.bodyLarge
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 13.5)),
            ],
          ),
          const SizedBox(height: 4),
          PartyRatingRow(venue: venue),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------
class PartyStatusChip extends StatelessWidget {
  const PartyStatusChip({super.key, required this.status});
  final PartyBookingStatus status;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color fg;
    late final Color bg;
    switch (status) {
      case PartyBookingStatus.confirmed:
        label = 'Confirmed';
        fg = PartyColors.success;
        bg = PartyColors.successSurface;
        break;
      case PartyBookingStatus.pending:
        label = 'Pending';
        fg = PartyColors.info;
        bg = PartyColors.infoSurface;
        break;
      case PartyBookingStatus.completed:
        label = 'Completed';
        fg = PartyColors.muted;
        bg = PartyColors.chip;
        break;
      case PartyBookingStatus.cancelled:
        label = 'Cancelled';
        fg = PartyColors.error;
        bg = PartyColors.errorSurface;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Text(label,
          style: AppTypography.labelMedium
              .copyWith(color: fg, fontWeight: FontWeight.w700, fontSize: 11.5)),
    );
  }
}

// ---------------------------------------------------------------------------
// Icon + text row (booking meta)
// ---------------------------------------------------------------------------
class PartyMetaRow extends StatelessWidget {
  const PartyMetaRow({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Icon(icon, size: 14, color: PartyColors.muted),
            const SizedBox(width: 6),
            Text(text,
                style: AppTypography.bodyMedium
                    .copyWith(color: PartyColors.text, fontSize: 12.5)),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// 4-step progress indicator
// ---------------------------------------------------------------------------
class PartyStepIndicator extends StatelessWidget {
  const PartyStepIndicator({super.key, required this.current});
  final int current;

  static const _labels = ['Date & Time', 'Details', 'Payment', 'Confirm'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _labels.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1.5,
                          color: i == 0
                              ? Colors.transparent
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      _Dot(index: i, current: current),
                      Expanded(
                        child: Container(
                          height: 1.5,
                          color: i == _labels.length - 1
                              ? Colors.transparent
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          i == current ? FontWeight.w800 : FontWeight.w600,
                      color: i == current
                          ? const Color(0xFF4C1CDD)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.index, required this.current});
  final int index;
  final int current;

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    final done = index < current;

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (active || done) ? const Color(0xFF4C1CDD) : Colors.white,
        border: (active || done)
            ? null
            : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: (active || done)
            ? [
                BoxShadow(
                  color: const Color(0xFF4C1CDD).withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: done
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : Text(
              '${index + 1}',
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation: Home · My Bookings · Favorites · Profile
// ---------------------------------------------------------------------------
class PartyBottomNav extends StatelessWidget {
  const PartyBottomNav({super.key, required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    Widget item(int i, IconData icon, String label) {
      final selected = i == currentIndex;
      final color = selected ? PartyColors.primary : PartyColors.muted;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(i),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 25),
              const SizedBox(height: 3),
              Text(label,
                  style: AppTypography.bodySmall.copyWith(
                      color: color,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: PartyColors.border.withOpacity(.6))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              item(0, Icons.home_rounded, 'Home'),
              item(1, Icons.calendar_month_rounded, 'My Bookings'),
              item(2, Icons.favorite_border_rounded, 'Favorites'),
              item(3, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Row of overlapping people (placeholder for the celebration illustration)
// ---------------------------------------------------------------------------
class PartyCrowd extends StatelessWidget {
  const PartyCrowd({super.key});

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF3B82F6), Color(0xFFFFB400), Color(0xFFEC4899),
      Color(0xFF22C55E), Color(0xFF9333EA),
    ];
    return SizedBox(
      height: 84,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          for (int i = 0; i < colors.length; i++)
            Positioned(
              bottom: -14 + (i.isEven ? 0 : 8),
              left: null,
              child: Transform.translate(
                offset: Offset((i - 2) * 58.0, 0),
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                      color: colors[i], shape: BoxShape.circle),
                  child: const Icon(Icons.celebration_rounded,
                      color: Colors.white, size: 34),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
