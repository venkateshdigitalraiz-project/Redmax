import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';

import '../../core/party_colors.dart';
import '../bloc/party_nav_cubit.dart';
import '../widgets/party_widgets.dart';

class PartyProfilePage extends StatelessWidget {
  const PartyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    void soon(String name) => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$name is coming soon')));

    final items = <_Item>[
      _Item(
        Icons.calendar_month_rounded,
        'My Bookings',
        () => context.read<PartyNavCubit>().select(1),
      ),
      _Item(
        Icons.favorite_border_rounded,
        'Favorites',
        () => context.read<PartyNavCubit>().select(2),
      ),
      _Item(
        Icons.payments_outlined,
        'Payment Methods',
        () => soon('Payment Methods'),
      ),
      _Item(
        Icons.help_outline_rounded,
        'Help & Support',
        () => soon('Help & Support'),
      ),
      _Item(
        Icons.arrow_back_rounded,
        'Back to Dashboard',
        () => Navigator.of(context, rootNavigator: true).maybePop(),
      ),
    ];

    return Column(
      children: [
        PartyHeaderBar(
          title: 'Profile',
          onBack: () => context.read<PartyNavCubit>().select(0),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: PartyColors.primaryGradient,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Your Party Account',
                  style: AppTypography.titleLarge,
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: PartyColors.tile,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      ListTile(
                        leading: Icon(
                          items[i].icon,
                          color: PartyColors.primary,
                        ),
                        title: Text(
                          items[i].label,
                          style: AppTypography.bodyLarge,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: items[i].onTap,
                      ),
                      if (i != items.length - 1)
                        const Divider(height: 1, indent: 56),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Item {
  const _Item(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
