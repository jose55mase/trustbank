import 'package:flutter/material.dart';
import '../colors/tb_colors.dart';
import '../typography/tb_typography.dart';
import '../spacing/tb_spacing.dart';

class TBInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLines;
  final VoidCallback? onTap;
  final Function(String)? onChanged;

  const TBInput({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.onTap,
    this.onChanged,
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
              color: _getBorderColor(),
              width: _isFocused ? 2 : 1,
            ),
            color: widget.enabled ? TBColors.surface : TBColors.grey100,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            style: TBTypography.bodyMedium.copyWith(
              color: widget.enabled ? TBColors.black : TBColors.grey500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TBTypography.bodyMedium.copyWith(
                color: TBColors.grey500,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TBSpacing.md,
                vertical: TBSpacing.md,
              ),
            ),
          ),
        ),
        if (widget.helperText != null || widget.errorText != null) ...[
          const SizedBox(height: TBSpacing.xs),
          Text(
            widget.errorText ?? widget.helperText!,
            style: TBTypography.labelSmall.copyWith(
              color: widget.errorText != null ? TBColors.error : TBColors.grey600,
            ),
          ),
        ],
      ],
    );
  }

  Color _getBorderColor() {
    if (widget.errorText != null) return TBColors.error;
    if (_isFocused) return TBColors.primary;
    return TBColors.grey300;
  }
}