import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../bloc/carpool_messages_bloc.dart';

/// CarpoolMessagesPage - Matches screenshot design:
/// 1. Lavender gradient background with ambient lilac wave wash in bottom right.
/// 2. Top bar: Bold "Messages" title and right compose square icon.
/// 3. Filter Pills: "All" (royal purple gradient with glow shadow), "Rides", "Support".
/// 4. Unified white messages card:
///    - Ramesh Kumar (avatar, "Thanks for the ride!", "2m", red "1" badge)
///    - Srinivas (avatar, "See you soon", "1h")
///    - Support Team (blue bot icon avatar, "Your ticket #4587 is upd...", "1d")
///    - System (celestial flame avatar, "Welcome to RideMax!", "2d")
/// 5. Fits comfortably on screen with no overflow on any device height.
class CarpoolMessagesPage extends StatelessWidget {
  final CarpoolMessagesBloc? bloc;

  const CarpoolMessagesPage({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: const _MessagesView(),
      );
    }
    try {
      context.read<CarpoolMessagesBloc>();
      return const _MessagesView();
    } catch (_) {
      final repo = CarpoolRepositoryImpl(CarpoolMockDataSource());
      return BlocProvider(
        create: (_) => CarpoolMessagesBloc(
          getMessages: CarpoolGetMessagesUseCase(repo),
        )..add(const CarpoolMessagesStarted()),
        child: const _MessagesView(),
      );
    }
  }
}

class _MessagesView extends StatelessWidget {
  const _MessagesView();

  void _snack(BuildContext c, String text) {
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openChat(BuildContext context, CarpoolMessageEntity message) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE8FF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _buildAvatar(message),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.senderName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF140D43),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message.timeAgo,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B658C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF3F0FD)),
            const SizedBox(height: 10),
            Text(
              message.preview,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3815D8),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3815D8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _snack(context, 'Chat opened with ${message.senderName}');
                },
                child: const Text(
                  'Reply in Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(CarpoolMessageEntity message) {
    if (message.senderName.contains('Ramesh')) {
      return ClipOval(
        child: Image.network(
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?fit=crop&w=150&h=150',
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 50,
            height: 50,
            color: const Color(0xFFEBE6FC),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF3815D8),
              size: 28,
            ),
          ),
        ),
      );
    }

    if (message.senderName.contains('Srinivas')) {
      return ClipOval(
        child: Image.network(
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=150&h=150',
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 50,
            height: 50,
            color: const Color(0xFFEBE6FC),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF3815D8),
              size: 28,
            ),
          ),
        ),
      );
    }

    if (message.senderName.contains('Support')) {
      return Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: Color(0xFFE3EDFE),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    // System avatar
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: Color(0xFFE0F2FE),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFBAE6FD),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFF0284C7),
            size: 18,
          ),
        ),
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
        child: Stack(
          children: [
            // Ambient soft purple wave in bottom right
            Positioned(
              right: -40,
              bottom: 40,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFDED6FD).withOpacity(0.55),
                        const Color(0xFFEBE6FC).withOpacity(0.20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: BlocBuilder<CarpoolMessagesBloc, CarpoolMessagesState>(
                builder: (context, s) {
                  final visibleList = s.visible;

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      // 1. Top Bar: "Messages" title and right compose button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                        child: Row(
                          children: [
                            const Text(
                              'Messages',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF140D43),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _snack(context, 'Compose new message'),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.edit_square,
                                  color: Color(0xFF140D43),
                                  size: 26,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      // 2. Filter Pills: "All", "Rides", "Support"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _FilterPill(
                              label: 'All',
                              isSelected: s.tabIndex == 0,
                              onTap: () => context
                                  .read<CarpoolMessagesBloc>()
                                  .add(const CarpoolMessagesTabChanged(0)),
                            ),
                            const SizedBox(width: 10),
                            _FilterPill(
                              label: 'Rides',
                              isSelected: s.tabIndex == 1,
                              onTap: () => context
                                  .read<CarpoolMessagesBloc>()
                                  .add(const CarpoolMessagesTabChanged(1)),
                            ),
                            const SizedBox(width: 10),
                            _FilterPill(
                              label: 'Support',
                              isSelected: s.tabIndex == 2,
                              onTap: () => context
                                  .read<CarpoolMessagesBloc>()
                                  .add(const CarpoolMessagesTabChanged(2)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 3. Unified White Messages Card
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
                            child: visibleList.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40),
                                    child: Center(
                                      child: Text(
                                        'No messages in this folder.',
                                        style: TextStyle(
                                          color: Color(0xFF6B658C),
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: List.generate(
                                      visibleList.length,
                                      (index) {
                                        final msg = visibleList[index];
                                        final isLast =
                                            index == visibleList.length - 1;

                                        return Column(
                                          children: [
                                            _MessageRow(
                                              message: msg,
                                              avatar: _buildAvatar(msg),
                                              onTap: () => _openChat(context, msg),
                                            ),
                                            if (!isLast)
                                              const Divider(
                                                height: 1,
                                                thickness: 1,
                                                color: Color(0xFFF1EEFC),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter pill button with active gradient and soft glow shadow
class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFF6F35FF),
                    Color(0xFF3309B8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFFEBE6FC),
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4C1CDD).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF140D43),
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }
}

/// Message row inside the unified card
class _MessageRow extends StatelessWidget {
  final CarpoolMessageEntity message;
  final Widget avatar;
  final VoidCallback onTap;

  const _MessageRow({
    required this.message,
    required this.avatar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Avatar
            avatar,
            const SizedBox(width: 14),

            // 2. Sender Name and Preview (Indigo/Purple text)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.senderName,
                    style: const TextStyle(
                      color: Color(0xFF140D43),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF3815D8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // 3. Time and Red Unread Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.timeAgo,
                  style: const TextStyle(
                    color: Color(0xFF140D43),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 6),
                if (message.unreadCount > 0)
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53935).withOpacity(0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${message.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        height: 1.0,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
