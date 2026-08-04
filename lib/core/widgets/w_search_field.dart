import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';

/// The app's one search input. Used by every list that filters live on typing
/// (azkar categories, radio stations, the Quran index popup).
///
/// Direction-aware: text, hint and the clear button all follow the active
/// language, so the caret and hint sit on the right in Arabic. The magnifier is
/// a `prefixIcon`, which resolves to the leading (right in RTL) edge.
///
/// Two visual skins:
/// - [WSearchField] — light field for a normal page surface.
/// - [WSearchField.onColor] — translucent field for a coloured/gradient header.
class WSearchField extends StatefulWidget {
  const WSearchField({
    super.key,
    required this.onChanged,
    this.hint,
    this.initialValue,
    this.autofocus = false,
    this.onColor = false,
  });

  /// Translucent white-on-colour variant for coloured headers.
  const WSearchField.onColor({
    super.key,
    required this.onChanged,
    this.hint,
    this.initialValue,
    this.autofocus = false,
  }) : onColor = true;

  final ValueChanged<String> onChanged;

  /// Defaults to the shared `search_hint` string.
  final String? hint;
  final String? initialValue;
  final bool autofocus;
  final bool onColor;

  @override
  State<WSearchField> createState() => _WSearchFieldState();
}

class _WSearchFieldState extends State<WSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Rebuild so the clear button appears/disappears with the text.
    setState(() {});
    widget.onChanged(value);
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final brand = context.brand;
    final foreground = widget.onColor ? Colors.white : brand.onSurface;
    final hintColor = widget.onColor
        ? Colors.white.withValues(alpha: 0.62)
        : brand.muted;
    final iconColor = widget.onColor
        ? Colors.white.withValues(alpha: 0.7)
        : brand.muted;
    final border = widget.onColor
        ? Colors.white.withValues(alpha: 0.2)
        : brand.border;
    final focusBorder = widget.onColor ? Colors.white : brand.primary;
    final hasText = _controller.text.isNotEmpty;

    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      autofocus: widget.autofocus,
      textDirection: direction,
      textAlign: TextAlign.start,
      textAlignVertical: TextAlignVertical.center,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: foreground, fontSize: 13.sp),
      cursorColor: foreground,
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint ?? 'search_hint'.tr(),
        hintTextDirection: direction,
        hintStyle: TextStyle(color: hintColor, fontSize: 11.sp),
        prefixIcon: Icon(Icons.search_rounded, color: iconColor, size: 20.r),
        prefixIconConstraints: BoxConstraints(minWidth: 40.w),
        suffixIcon: hasText
            ? IconButton(
                onPressed: _clear,
                splashRadius: 18.r,
                icon: Icon(Icons.close_rounded, color: iconColor, size: 18.r),
              )
            : null,
        filled: true,
        fillColor: widget.onColor
            ? Colors.white.withValues(alpha: 0.07)
            : brand.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: focusBorder),
        ),
      ),
    );
  }
}
