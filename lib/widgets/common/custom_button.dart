import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final Gradient? gradient;
  final IconData? icon;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.gradient,
    this.icon,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null && !isLoading;

    Widget button = SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50,
      child: isOutlined ? _buildOutlinedButton(theme, isEnabled) : _buildElevatedButton(theme, isEnabled),
    );

    return button;
  }

  Widget _buildElevatedButton(ThemeData theme, bool isEnabled) {
    if (gradient != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: isEnabled ? gradient : null,
          color: isEnabled ? null : Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isEnabled
              ? [
            BoxShadow(
              color: (backgroundColor ?? AppColors.primary).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _buildButtonContent(theme),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: textColor ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: isEnabled ? 2 : 0,
      ),
      child: _buildButtonContent(theme),
    );
  }

  Widget _buildOutlinedButton(ThemeData theme, bool isEnabled) {
    return OutlinedButton(
      onPressed: isEnabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor ?? AppColors.primary,
        side: BorderSide(
          color: backgroundColor ?? AppColors.primary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: _buildButtonContent(theme),
    );
  }

  Widget _buildButtonContent(ThemeData theme) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            textColor ?? (isOutlined ? AppColors.primary : Colors.white),
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              color: textColor ?? (isOutlined ? AppColors.primary : Colors.white),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(
        color: textColor ?? (isOutlined ? AppColors.primary : Colors.white),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}