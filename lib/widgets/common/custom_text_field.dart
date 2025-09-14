import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final Color? fillColor;
  final double borderRadius;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.focusNode,
    this.fillColor,
    this.borderRadius = 12.0,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.titleSmall?.copyWith(
              color: _isFocused ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],

        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: _isFocused
                ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onFieldSubmitted,
            onTap: widget.onTap,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: widget.enabled ? AppColors.textPrimary : AppColors.textLight,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              helperText: widget.helperText,
              errorText: widget.errorText,
              filled: true,
              fillColor: widget.fillColor ??
                  (theme.brightness == Brightness.dark
                      ? AppColors.surfaceDark
                      : AppColors.surface),

              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                widget.prefixIcon,
                color: _isFocused ? AppColors.primary : AppColors.textLight,
                size: 20,
              )
                  : null,

              suffixIcon: widget.suffixIcon,

              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textLight,
              ),

              helperStyle: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),

              errorStyle: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide.none,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(
                  color: AppColors.border.withOpacity(0.5),
                  width: 1,
                ),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),

              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1,
                ),
              ),

              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 2,
                ),
              ),

              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(
                  color: AppColors.border.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}