import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';

/// Shared text field used across the app's forms.
///
/// Defaults to the auth design language: a white rounded card with a soft
/// shadow, no resting border, a green focus ring and a red error ring. All of
/// it is overridable via the border/style params so other screens can opt out.
class WSharedField extends StatelessWidget {
  const WSharedField({
    required this.controller,
    this.hint,
    this.label,
    this.enabled = true,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength,
    this.minLines,
    this.maxLines,
    this.onValidate,
    this.textStyle,
    this.hintStyle,
    this.errorStyle,
    this.validatorKey,
    this.textDirection,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.focusNode,
    this.onTap,
    this.readOnly = false,
    this.obscureText,
    this.fillColor,
    this.withShadow = true,
    this.disabledBorder,
    this.contentPadding,
    this.border,
    this.focusedBorder,
    this.errorBorder,
    this.enabledBorder,
    super.key,
  });

  /// Controllers
  final TextEditingController controller;
  final GlobalKey<FormFieldState>? validatorKey;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final String? hint;
  final String? label;
  final bool? obscureText;
  final bool? enabled;
  final bool readOnly;
  final bool withShadow;

  /// Text Field
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Color? fillColor;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final TextStyle? errorStyle;
  final TextDirection? textDirection;
  final List<TextInputFormatter>? inputFormatters;

  /// Icons
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  /// Actions
  final void Function()? onTap;
  final String? Function(String?)? onValidate;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;

  /// Borders
  final InputBorder? disabledBorder;
  final InputBorder? border;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? enabledBorder;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final radius = BorderRadius.circular(14.r);

    OutlineInputBorder ring(Color color, double width) => OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: color, width: width),
    );

    final restingBorder = enabledBorder ?? ring(Colors.transparent, 0);

    final field = TextFormField(
      key: validatorKey,
      focusNode: focusNode,
      controller: controller,
      maxLines: maxLines ?? 1,
      minLines: minLines,
      maxLength: maxLength,
      readOnly: readOnly,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textAlignVertical: TextAlignVertical.center,
      textDirection:
          textDirection ??
          (context.isRTL ? TextDirection.rtl : TextDirection.ltr),
      onTap: onTap,
      validator: onValidate,
      onChanged: onChanged,
      style:
          textStyle ??
          TextStyle(
            fontSize: 15.sp,
            color: brand.onSurface,
            fontWeight: FontWeight.w500,
          ),
      keyboardType:
          keyboardType ??
          ((textInputAction == TextInputAction.newline || (maxLines ?? 1) > 1)
              ? TextInputType.multiline
              : TextInputType.text),
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      obscureText: obscureText ?? false,
      enabled: enabled,
      cursorColor: brand.primary,
      decoration: InputDecoration(
        hintText: hint?.trim().isNotEmpty == true ? hint : null,
        labelText: label,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        isDense: true,
        counterText: '',
        filled: true,
        fillColor: fillColor ?? brand.surface,
        contentPadding:
            contentPadding ??
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        hintStyle:
            hintStyle ??
            TextStyle(
              fontSize: 14.sp,
              color: brand.muted,
              fontWeight: FontWeight.w400,
            ),
        errorStyle:
            errorStyle ??
            TextStyle(fontSize: 11.sp, color: AppColorsLight.error),
        border: border ?? restingBorder,
        enabledBorder: restingBorder,
        disabledBorder: disabledBorder ?? restingBorder,
        focusedBorder: focusedBorder ?? ring(brand.primary, 1.4),
        errorBorder: errorBorder ?? ring(AppColorsLight.error, 1),
        focusedErrorBorder: errorBorder ?? ring(AppColorsLight.error, 1.4),
      ),
    );

    if (!withShadow) return field;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: field,
    );
  }
}
