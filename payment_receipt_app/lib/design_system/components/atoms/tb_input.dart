import 'package:flutter/material.dart';
import '../../colors/tb_colors.dart';
import '../../typography/tb_typography.dart';
import '../../spacing/tb_spacing.dart';
import '../../../utils/currency_input_formatter.dart';

class TBInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final bool isCurrency;

  const TBInput({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.isCurrency = false,
  });

  @override
  State<TBInput> createState() => _TBInputState();
}

class _TBInputState extends State<TBInput> {
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TBTypography.labelMedium.copyWith(
              color: widget.errorText != null ? TBColors.error : TBColors.grey700,
            ),
          ),
          const SizedBox(height: TBSpacing.xs),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
            border: Border.all(
              color: widget.errorText != null 
                  ? TBColors.error 
                  : _isFocused 
                      ? TBColors.primary 
                      : TBColors.grey300,
              width: _isFocused ? 2 : 1,
            ),
            color: TBColors.surface,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.isCurrency ? [CurrencyInputFormatter()] : null,
            onChanged: widget.onChanged,
            style: TBTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TBTypography.bodyMedium.copyWith(color: TBColors.grey500),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(TBSpacing.md),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: TBSpacing.xs),
          Text(
            widget.errorText!,
            style: TBTypography.labelMedium.copyWith(color: TBColors.error),
          ),
        ],
      ],
    );
  }
}