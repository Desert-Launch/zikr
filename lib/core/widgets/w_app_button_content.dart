import 'package:flutter/material.dart';
import 'package:quran/core/extension/num_ext.dart';
import 'package:quran/core/responsive/responsive_extensions.dart';

/// Internal visual content (text, loading spinner, icons, leading/trailing
/// widgets) used by [WAppButton]. Kept separate so it can be embedded inside
/// multiple container layouts (primary gradient, danger, outline, ...).
class WAppButtonContent extends StatelessWidget {
  final String title;
  final bool isLoading;
  final Color textColor;
  final TextStyle? style;
  final double? fontSize;
  final Widget? customChild;
  final Widget? icon;
  final Widget? leading;
  final Widget? trailing;
  final TextDirection? textDirection;

  const WAppButtonContent({
    super.key,
    required this.title,
    required this.isLoading,
    required this.textColor,
    this.style,
    this.fontSize,
    this.customChild,
    this.icon,
    this.leading,
    this.trailing,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: textDirection ?? Directionality.of(context),
      child:
          customChild ??
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) leading!,
              if (leading != null) 8.widthBox,
              if (icon != null) icon!,
              if (icon != null) 8.widthBox,
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? SizedBox(
                          key: const ValueKey('_btn_loading_'),
                          width: 20.rCapped(24),
                          height: 20.rCapped(24),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(textColor),
                          ),
                        )
                      : Text(
                          title,
                          textAlign: TextAlign.center,
                          style:
                              style ??
                              TextStyle(
                                fontSize: fontSize ?? 16.spCapped(20),
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                ),
              ),
              if (trailing != null) 8.widthBox,
              if (trailing != null) trailing!,
            ],
          ),
    );
  }
}
