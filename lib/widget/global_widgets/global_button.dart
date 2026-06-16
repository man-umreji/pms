import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/app_color/app_color.dart';

enum ButtonIconPosition { left, right }

enum ButtonType { filled, outlined }

class GlobalButton extends StatelessWidget {
  const GlobalButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 12.0,
    this.icon,
    this.iconPosition = ButtonIconPosition.left,
    this.gradient = const LinearGradient(
      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], // Modern blue gradient
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.type = ButtonType.filled,
    this.outlineColor,
    this.outlineWidth = 1.5,
    this.elevation = 2,
    this.width = double.infinity,
    this.height = 50,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.letterSpacing = 0.5,
    this.shadowColor,
    this.loadingIndicatorColor,
    this.hoverColor,
  });

  // Core
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;

  // Style
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final Gradient? gradient;
  final ButtonType type;
  final double elevation;
  final double width;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final Color? shadowColor;
  final Color? loadingIndicatorColor;
  final Color? hoverColor;

  // Icon
  final Widget? icon;
  final ButtonIconPosition iconPosition;

  // Outline-specific
  final Color? outlineColor;
  final double outlineWidth;

  @override
  Widget build(BuildContext context) {
    // --- 1. Determine Colors ---
    final bool isOutlined = type == ButtonType.outlined;
    final bool isInteractive = !isLoading && !isDisabled;

    // Foreground Color (Text & Icon)
    final Color finalFgColor = () {
      if (isDisabled) {
        return isOutlined
            ? AppColors.textLight.withValues(alpha: 0.5)
            : AppColors.textLight;
      }
      if (foregroundColor != null) return foregroundColor!;
      if (isOutlined) {
        return outlineColor ?? AppColors.primaryLight;
      }
      return Colors.white;
    }();

    // Background Color / Gradient
    final Gradient? finalGradient = (!isOutlined && isInteractive && gradient != null)
        ? gradient
        : null;

    final Color? finalBgColor = () {
      if (isOutlined) return Colors.transparent;
      if (isDisabled) return AppColors.textDark.withValues(alpha: 0.3);
      if (backgroundColor != null) return backgroundColor;
      if (gradient == null) return AppColors.primaryLight;
      return null;
    }();

    // Shadow Color
    final Color? finalShadowColor = shadowColor ??
        (isOutlined ? null : AppColors.primaryLight.withValues(alpha: 0.3));

    // Loading Indicator Color
    final Color finalLoadingColor = loadingIndicatorColor ?? finalFgColor;

    // --- 2. Build Inner Child ---
    Widget buttonChild;
    if (isLoading) {
      buttonChild = SizedBox(
        height: 22.h,
        width: 22.w,
        child: CircularProgressIndicator(
          color: finalLoadingColor,
          strokeWidth: 2.5,
        ),
      );
    } else {
      final textWidget = Text(
        text,
        style: TextStyle(
          color: finalFgColor,
          fontSize: fontSize.sp,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        ),
      );

      if (icon != null) {
        buttonChild = Row(
          mainAxisSize: MainAxisSize.min,
          children: iconPosition == ButtonIconPosition.left
              ? [icon!, SizedBox(width: 8.w), textWidget]
              : [textWidget, SizedBox(width: 8.w), icon!],
        );
      } else {
        buttonChild = textWidget;
      }
    }

    // --- 3. Build Decoration ---
    BoxDecoration boxDecoration = BoxDecoration(
      gradient: finalGradient,
      color: finalBgColor,
      borderRadius: BorderRadius.circular(borderRadius.r),
      border: isOutlined
          ? Border.all(
        color: isDisabled
            ? AppColors.textLight.withValues(alpha: 0.4)
            : (outlineColor ?? AppColors.primaryLight),
        width: outlineWidth,
      )
          : null,
      boxShadow: (!isOutlined && isInteractive && elevation > 0)
          ? [
        BoxShadow(
          color: finalShadowColor ?? Colors.transparent,
          blurRadius: elevation * 2,
          offset: Offset(0, elevation / 2),
          spreadRadius: elevation / 4,
        ),
      ]
          : null,
    );

    // --- 4. Build Button Style ---
    final ButtonStyle style = ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      foregroundColor: finalFgColor,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      minimumSize: Size(width, height.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius.r),
      ),
      elevation: 0,
      overlayColor: isOutlined
          ? (hoverColor ?? AppColors.primaryLight.withValues(alpha: 0.1))
          : (hoverColor ?? Colors.white.withValues(alpha: 0.1)),
      animationDuration: const Duration(milliseconds: 200),
    );

    // --- 5. Final Wrapper ---
    return Container(
      width: width,
      height: height.h,
      decoration: boxDecoration,
      child: ElevatedButton(
        style: style,
        onPressed: isInteractive ? onPressed : null,
        child: buttonChild,
      ),
    );
  }
}

// Extension for common button presets
extension GlobalButtonPresets on GlobalButton {
  // Primary Button - Solid Blue
  static GlobalButton primary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    Widget? icon,
    ButtonIconPosition iconPosition = ButtonIconPosition.left,
  }) {
    return GlobalButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      iconPosition: iconPosition,
      gradient: const LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      foregroundColor: Colors.white,
      elevation: 3,
    );
  }

  // Secondary Button - Outline
  static GlobalButton secondary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    Widget? icon,
    ButtonIconPosition iconPosition = ButtonIconPosition.left,
  }) {
    return GlobalButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      iconPosition: iconPosition,
      type: ButtonType.outlined,
      outlineColor: const Color(0xFF2563EB),
      foregroundColor: const Color(0xFF2563EB),
      elevation: 0,
    );
  }

  // Success Button - Green
  static GlobalButton success({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    Widget? icon,
    ButtonIconPosition iconPosition = ButtonIconPosition.left,
  }) {
    return GlobalButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      iconPosition: iconPosition,
      gradient: const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      foregroundColor: Colors.white,
      elevation: 3,
    );
  }

  // Danger Button - Red
  static GlobalButton danger({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    Widget? icon,
    ButtonIconPosition iconPosition = ButtonIconPosition.left,
  }) {
    return GlobalButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      iconPosition: iconPosition,
      gradient: const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      foregroundColor: Colors.white,
      elevation: 3,
    );
  }

  // Warning Button - Orange
  static GlobalButton warning({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    Widget? icon,
    ButtonIconPosition iconPosition = ButtonIconPosition.left,
  }) {
    return GlobalButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      iconPosition: iconPosition,
      gradient: const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      foregroundColor: Colors.white,
      elevation: 3,
    );
  }

  // Dark Button
  static GlobalButton dark({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    Widget? icon,
    ButtonIconPosition iconPosition = ButtonIconPosition.left,
  }) {
    return GlobalButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      iconPosition: iconPosition,
      gradient: const LinearGradient(
        colors: [Color(0xFF1F2937), Color(0xFF111827)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      foregroundColor: Colors.white,
      elevation: 3,
    );
  }

  // Light Button
  static GlobalButton light({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    Widget? icon,
    ButtonIconPosition iconPosition = ButtonIconPosition.left,
  }) {
    return GlobalButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      iconPosition: iconPosition,
      backgroundColor: Colors.grey.shade100,
      foregroundColor: Colors.grey.shade800,
      elevation: 1,
    );
  }
}