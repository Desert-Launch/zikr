import 'dart:async';

import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/app_gradients.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/responsive/responsive_extensions.dart';
import 'package:quran/core/widgets/w_app_button_content.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

class WAppButton extends StatefulWidget {
  const WAppButton({
    super.key,
    required this.title,
    required this.onTap,
    this.variant = AppButtonVariant.primary,
    this.isDisabled = false,
    this.width,
    this.height,
    this.style,
    this.fontSize,
    this.padding,
    this.radius,
    this.color,
    this.borderColor,
    this.icon,
    this.backgroundColor,
    this.textDirection,
    this.customChild,
    this.withShadow = true,
    this.leading,
    this.trailing,
    this.isExpanded = true,
    this.isFilled,
    this.isLoading,
  });

  final String title;
  final bool? isFilled; // Legacy support
  final bool isDisabled;
  final bool withShadow;
  final bool isExpanded;
  final FutureOr<void> Function()? onTap;
  final double? width;
  final double? height;
  final double? radius;
  final double? fontSize;
  final TextStyle? style;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final Widget? customChild;
  final Widget? icon;
  final Widget? leading;
  final Widget? trailing;
  final Color? backgroundColor;
  final TextDirection? textDirection;
  final AppButtonVariant variant;
  final bool? isLoading;

  @override
  State<WAppButton> createState() => _WAppButtonState();
}

class _WAppButtonState extends State<WAppButton> {
  bool _internalLoading = false;

  bool get _isLoading => widget.isLoading ?? _internalLoading;

  bool get _isOutline {
    if (widget.isFilled != null) {
      return !widget.isFilled!;
    }
    return widget.variant == AppButtonVariant.outline;
  }

  AppButtonVariant get _variant {
    if (widget.isFilled != null && widget.isFilled == false) {
      return AppButtonVariant.outline;
    }
    return widget.variant;
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.isDisabled || _isLoading;
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(widget.radius ?? 12.rCapped(14));
    final height = widget.height ?? 48.h;
    final width = widget.isExpanded ? (widget.width ?? double.infinity) : widget.width;

    final borderColor = widget.borderColor ?? _resolveBorderColor(theme, isDisabled);
    final textColor = _resolveTextColor(theme, isDisabled);

    // For primary variant, use Container with gradient
    if (_variant == AppButtonVariant.primary) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: isDisabled ? null : AppGradients.button,
          color: isDisabled ? Colors.grey.shade300 : null,
          borderRadius: borderRadius,
          boxShadow: widget.withShadow && !isDisabled
              ? [
                  BoxShadow(
                    color: AppColors.authPrimary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : _onTap,
            borderRadius: borderRadius,
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            child: Center(
              child: WAppButtonContent(
                title: widget.title,
                isLoading: _isLoading,
                textColor: textColor,
                style: widget.style,
                fontSize: widget.fontSize,
                customChild: widget.customChild,
                icon: widget.icon,
                leading: widget.leading,
                trailing: widget.trailing,
                textDirection: widget.textDirection,
              ),
            ),
          ),
        ),
      );
    }

    // For danger variant, use solid red background
    if (_variant == AppButtonVariant.danger) {
      const dangerColor = AppColors.semanticDanger;
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade300 : dangerColor,
          borderRadius: borderRadius,
          boxShadow: widget.withShadow && !isDisabled
              ? [BoxShadow(color: dangerColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : _onTap,
            borderRadius: borderRadius,
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            child: Center(
              child: WAppButtonContent(
                title: widget.title,
                isLoading: _isLoading,
                textColor: Colors.white,
                style: widget.style,
                fontSize: widget.fontSize,
                customChild: widget.customChild,
                icon: widget.icon,
                leading: widget.leading,
                trailing: widget.trailing,
                textDirection: widget.textDirection,
              ),
            ),
          ),
        ),
      );
    }

    // For other variants, use ElevatedButton
    final background = _resolveBackground(theme, isDisabled);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isDisabled ? 0.7 : 1,
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          onPressed: isDisabled ? null : _onTap,
          style: ButtonStyle(
            elevation: WidgetStatePropertyAll(widget.withShadow ? 6 : 0),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: borderRadius)),
            backgroundColor: WidgetStatePropertyAll(background.color),
            foregroundColor: WidgetStatePropertyAll(textColor),
            overlayColor: const WidgetStatePropertyAll(Colors.white10),
            shadowColor: WidgetStatePropertyAll(AppColors.black800.withValues(alpha: 0.2)),
            side: _isOutline ? WidgetStatePropertyAll(BorderSide(color: borderColor, width: 1.5)) : null,
          ),
          child: WAppButtonContent(
            title: widget.title,
            isLoading: _isLoading,
            textColor: textColor,
            style: widget.style,
            fontSize: widget.fontSize,
            customChild: widget.customChild,
            icon: widget.icon,
            leading: widget.leading,
            trailing: widget.trailing,
            textDirection: widget.textDirection,
          ),
        ),
      ),
    );
  }

  _ButtonBackground _resolveBackground(ThemeData theme, bool isDisabled) {
    final disabledColor = AppColors.lightBorderDefault.withValues(alpha: 0.5);
    if (isDisabled) {
      return _ButtonBackground(color: disabledColor);
    }

    switch (_variant) {
      case AppButtonVariant.primary:
        return _ButtonBackground(
          color: widget.backgroundColor ?? AppColors.brandPurple,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius ?? 4.rCapped(5)),
            gradient: AppGradients.main,
          ),
        );
      case AppButtonVariant.secondary:
        return _ButtonBackground(color: widget.backgroundColor ?? AppColors.brandPurple100);
      case AppButtonVariant.outline:
        return _ButtonBackground(color: widget.backgroundColor ?? theme.colorScheme.surface);
      case AppButtonVariant.danger:
        return _ButtonBackground(color: widget.backgroundColor ?? AppColors.semanticDanger);
    }
  }

  Color _resolveTextColor(ThemeData theme, bool isDisabled) {
    if (isDisabled) {
      // For primary/danger variants, keep white text when disabled
      if (_variant == AppButtonVariant.primary || _variant == AppButtonVariant.danger) {
        return Colors.white;
      }
      return AppColors.textInactiveLight;
    }

    switch (_variant) {
      case AppButtonVariant.primary:
        return AppColors.lightForeground;
      case AppButtonVariant.secondary:
        return AppColors.brandPurpleDark;
      case AppButtonVariant.outline:
        return widget.borderColor ?? Colors.grey.shade600;
      case AppButtonVariant.danger:
        return Colors.white;
    }
  }

  Color _resolveBorderColor(ThemeData theme, bool isDisabled) {
    if (isDisabled) {
      return AppColors.lightBorderDefault;
    }
    if (_variant == AppButtonVariant.outline) {
      return widget.borderColor ?? Colors.grey.shade600;
    }
    return widget.borderColor ?? theme.colorScheme.primary;
  }

  Future<void> _onTap() async {
    final handler = widget.onTap;
    if (handler == null || _internalLoading) return;
    if (widget.isLoading != null) {
      final result = handler();
      if (result is Future) {
        await result;
      }
      return;
    }
    if (mounted) {
      setState(() {
        _internalLoading = true;
      });
    }
    try {
      final result = handler();
      if (result is Future) {
        await result;
      }
    } finally {
      if (mounted) {
        setState(() {
          _internalLoading = false;
        });
      }
    }
  }
}

class _ButtonBackground {
  _ButtonBackground({required this.color, this.decoration});

  final Color color;
  final Decoration? decoration;
}
