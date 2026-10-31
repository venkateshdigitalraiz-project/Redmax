import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class FourDigitOtpInput extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final double boxSize;

  const FourDigitOtpInput({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.boxSize = 56.0,
  });

  @override
  State<FourDigitOtpInput> createState() => _FourDigitOtpInputState();
}

class _FourDigitOtpInputState extends State<FourDigitOtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (index) {
      final node = FocusNode();
      node.onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _controllers[index].text.isEmpty &&
            index > 0) {
          _focusNodes[index - 1].requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
      return node;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    final otp = _currentOtp;
    widget.onChanged?.call(otp);

    if (otp.length == 4) {
      widget.onCompleted(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 4; i++) ...[
          _buildDigitBox(i),
          if (i < 3) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _buildDigitBox(int index) {
    final bool hasFocus = _focusNodes[index].hasFocus;
    final bool hasValue = _controllers[index].text.isNotEmpty;

    return Container(
      width: widget.boxSize,
      height: widget.boxSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFocus || hasValue ? AppColors.primary : AppColors.border,
          width: hasFocus ? 1.8 : 1.0,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        showCursor: false,
        style: AppTypography.displayLarge.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryNavy,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: const InputDecoration(
          isDense: true,
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          counterText: '',
        ),
        onChanged: (val) => _onDigitChanged(index, val),
      ),
    );
  }
}
