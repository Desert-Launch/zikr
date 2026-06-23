import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/responsive/responsive_extensions.dart';
import 'package:quran/core/theme/brand_colors.dart';
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
    final brand = context.brand;
    final borderRadius = BorderRadius.circular(widget.radius ?? 12.rCapped(14));
    final height = widget.height ?? 48.h;
    final width = widget.isExpanded ? (widget.width ?? double.infinity) : widget.width;
    final disabledFill = brand.border.withValues(alpha: 0.5);

    final borderColor = widget.borderColor ?? _resolveBorderColor(brand, isDisabled);
    final textColor = _resolveTextColor(brand, isDisabled);

    // Primary — brand green gradient (or a solid fill override), white label.
    if (_variant == AppButtonVariant.primary) {
      final primaryFill = widget.backgroundColor ?? widget.color;
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: isDisabled || primaryFill != null
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [brand.primary, brand.primaryDark],
                ),
          color: isDisabled ? disabledFill : primaryFill,
          borderRadius: borderRadius,
          boxShadow: widget.withShadow && !isDisabled
              ? [BoxShadow(color: brand.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
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

    // Danger — solid error fill from the theme.
    if (_variant == AppButtonVariant.danger) {
      final dangerColor = brand.error;
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDisabled ? disabledFill : dangerColor,
          borderRadius: borderRadius,
          boxShadow: widget.withShadow && !isDisabled
              ? [BoxShadow(color: dangerColor.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
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

    // Secondary / outline — ElevatedButton using theme tokens.
    final background = _resolveBackground(brand, isDisabled);
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
            backgroundColor: WidgetStatePropertyAll(background),
            foregroundColor: WidgetStatePropertyAll(textColor),
            overlayColor: WidgetStatePropertyAll(brand.primary.withValues(alpha: 0.08)),
            shadowColor: WidgetStatePropertyAll(brand.primary.withValues(alpha: 0.2)),
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

  Color _resolveBackground(BrandColors brand, bool isDisabled) {
    if (isDisabled) return brand.border.withValues(alpha: 0.5);
    switch (_variant) {
      case AppButtonVariant.secondary:
        return widget.backgroundColor ?? brand.primary.withValues(alpha: 0.12);
      case AppButtonVariant.outline:
        return widget.backgroundColor ?? brand.surface;
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return widget.backgroundColor ?? brand.primary;
    }
  }

  Color _resolveTextColor(BrandColors brand, bool isDisabled) {
    if (isDisabled) {
      // Primary/danger keep white text so the label stays legible when greyed.
      if (_variant == AppButtonVariant.primary || _variant == AppButtonVariant.danger) {
        return Colors.white;
      }
      return brand.muted;
    }

    switch (_variant) {
      case AppButtonVariant.primary:
        return widget.color ?? Colors.white;
      case AppButtonVariant.secondary:
        return widget.color ?? brand.primary;
      case AppButtonVariant.outline:
        return widget.color ?? widget.borderColor ?? brand.onSurface;
      case AppButtonVariant.danger:
        return Colors.white;
    }
  }

  Color _resolveBorderColor(BrandColors brand, bool isDisabled) {
    if (isDisabled) return brand.border;
    if (_variant == AppButtonVariant.outline) {
      return widget.borderColor ?? brand.border;
    }
    return widget.borderColor ?? brand.primary;
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
