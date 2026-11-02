import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../bloc/carpool_wallet_bloc.dart';

/// CarpoolWalletPage - Matches screenshot design:
/// 1. Lavender gradient background.
/// 2. Top bar: Back arrow, "Wallet" title, settings gear icon.
/// 3. Cosmic Purple Wallet Card:
///    - "Wallet Balance" & large "₹850"
///    - 3D illustrated golden-orange wallet
///    - "Add Money +" white pill button
/// 4. "Recent Transactions" header with "See All →".
/// 5. Unified rounded white card with 3 transactions:
///    - Ride Payment (car icon, – ₹250)
///    - Referral Reward (gift icon, + ₹100)
///    - Added Money (wallet icon, + 5500)
class CarpoolWalletPage extends StatelessWidget {
  final CarpoolWalletBloc? bloc;

  const CarpoolWalletPage({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: const _WalletView(),
      );
    }
    try {
      context.read<CarpoolWalletBloc>();
      return const _WalletView();
    } catch (_) {
      final repo = CarpoolRepositoryImpl(CarpoolMockDataSource());
      return BlocProvider(
        create: (_) => CarpoolWalletBloc(
          getWallet: CarpoolGetWalletUseCase(repo),
          addMoney: CarpoolAddMoneyUseCase(repo),
        )..add(const CarpoolWalletStarted()),
        child: const _WalletView(),
      );
    }
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView();

  Future<void> _addMoney(BuildContext context) async {
    final controller = TextEditingController(text: '500');
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Money to Wallet',
          style: TextStyle(
            color: Color(0xFF140D43),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '₹ ',
            hintText: 'Enter amount',
            filled: true,
            fillColor: const Color(0xFFF7F5FE),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEDE8FF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF3815D8), width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B658C)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3815D8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(controller.text.trim())),
            child: const Text(
              'Add Money',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (amount != null && context.mounted) {
      context.read<CarpoolWalletBloc>().add(
        CarpoolWalletAddMoneyPressed(amount),
      );
    }
  }

  String _formatTxDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && (now.day - d.day).abs() <= 1) {
      return DateFormat('MMM dd, hh:mm a').format(d);
    }
    return DateFormat('MMM dd, yyyy').format(d);
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
          child: BlocConsumer<CarpoolWalletBloc, CarpoolWalletState>(
            listenWhen: (p, c) => c.message != null && p.message != c.message,
            listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.message!),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            builder: (context, s) {
              final wallet = s.wallet;
              final balance = wallet?.balance ?? 850;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  // 1. Top Bar: Back arrow, "Wallet", Settings gear
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
                          'Wallet',
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
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Wallet settings'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
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

                  // 2. Cosmic Purple Wallet Card with 3D Wallet & Add Money Button
                  Container(
                    height: 185,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6F35FF),
                          Color(0xFF3309B8),
                          Color(0xFF1E076C),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4C1CDD).withOpacity(0.40),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          // Organic decorative wave background
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _CardBackgroundWavePainter(),
                            ),
                          ),

                          // Card Contents
                          Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Balance Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Wallet Balance',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₹${balance.toInt()}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 42,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 3D Leather Wallet Illustration
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4.0),
                                      child: _WalletIllustration(),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                // Add Money + Button
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _addMoney(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 9.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.12),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'Add Money +',
                                        style: TextStyle(
                                          color: Color(0xFF2E12C8),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                    ),
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

                  // 3. "Recent Transactions" Header & "See All →"
                  Row(
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF140D43),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All transactions displayed'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'See All',
                              style: TextStyle(
                                color: Color(0xFF3815D8),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF3815D8),
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 4. Unified Transactions Card
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
                      child: wallet == null
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF3815D8),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                for (
                                  int i = 0;
                                  i < wallet.transactions.length;
                                  i++
                                ) ...[
                                  _TransactionRow(
                                    tx: wallet.transactions[i],
                                    dateText: _formatTxDate(
                                      wallet.transactions[i].date,
                                    ),
                                  ),
                                  if (i != wallet.transactions.length - 1)
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Transaction Row matching screenshot format
class _TransactionRow extends StatelessWidget {
  final CarpoolTransactionEntity tx;
  final String dateText;

  const _TransactionRow({
    required this.tx,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = tx.amount < 0;

    IconData icon;
    Color iconColor;
    Color badgeColor;

    switch (tx.type) {
      case CarpoolTransactionType.payment:
        icon = Icons.directions_car_rounded;
        iconColor = const Color(0xFF3815D8);
        badgeColor = const Color(0xFFEBE6FC);
        break;
      case CarpoolTransactionType.reward:
        icon = Icons.card_giftcard_rounded;
        iconColor = const Color(0xFFFF7A00);
        badgeColor = const Color(0xFFFFECEB);
        break;
      case CarpoolTransactionType.topUp:
        icon = Icons.account_balance_wallet_rounded;
        iconColor = const Color(0xFF3815D8);
        badgeColor = const Color(0xFFEBE6FC);
        break;
    }

    // Format amount text matching screenshot
    final String amountText;
    final Color amountColor;
    if (isNegative) {
      amountText = '– ₹${tx.amount.abs().toInt()}';
      amountColor = const Color(0xFF140D43);
    } else {
      amountText = '+ ₹${tx.amount.toInt()}';
      amountColor = const Color(0xFF16A34A);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        children: [
          // Circular Badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),

          // Title & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: Color(0xFF140D43),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateText,
                  style: const TextStyle(
                    color: Color(0xFF6B658C),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Amount Text
          Text(
            amountText,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: amountColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 3D Leather Wallet Illustration for the card top-right
class _WalletIllustration extends StatelessWidget {
  const _WalletIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cash/bills sticking out from top
          Positioned(
            top: 0,
            left: 10,
            child: Container(
              width: 50,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFD4B37F),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFF0D5A6),
                  width: 1.2,
                ),
              ),
            ),
          ),
          // Front leather wallet
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 70,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9E2C), Color(0xFFFF7A00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  // Clasp flap
                  Positioned(
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB04A),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(-2, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle glowing organic background waves inside the balance card
class _CardBackgroundWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF8B5CF6).withOpacity(0.20)
      ..style = PaintingStyle.fill;
    final paint2 = Paint()
      ..color = const Color(0xFF3815D8).withOpacity(0.25)
      ..style = PaintingStyle.fill;

    // Wave 1
    final path1 = Path()
      ..moveTo(0, size.height * 0.40)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.15,
        size.width * 0.70,
        size.height * 0.50,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.65,
        size.width,
        size.height * 0.60,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path1, paint1);

    // Wave 2
    final path2 = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.50,
        size.width * 0.75,
        size.height * 0.80,
      )
      ..quadraticBezierTo(
        size.width * 0.90,
        size.height * 0.90,
        size.width,
        size.height * 0.85,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
