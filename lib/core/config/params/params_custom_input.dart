import 'package:flutter/material.dart';
import 'package:quran/core/config/params/custom_pin_code_options.dart';

class ParamsCustomInput {
  final String? hint;
  final String? label;
  final bool isRequired;
  final String? customRequiredMessage;
  final FocusNode? nextFocusNode;
  final List<String? Function(String?)?>? validators;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? confirmPaswordValidation;
  final void Function()? onPrefixIconPressed;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color? fillColor;
  final bool enabled;
  final CustomPinCodeOptions? pinCodeOptions;
  final double? height;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? inputAction;
  final InputBorder? disabledBorder;
  final InputBorder? border;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? enabledBorder;
  final EdgeInsetsGeometry? contentPadding;

  const ParamsCustomInput({
    this.height,
    this.hint,
    this.label,
    this.isRequired = false,
    this.customRequiredMessage,
    this.nextFocusNode,
    this.validators,
    this.prefixIcon,
    this.onPrefixIconPressed,
    this.suffixIcon,
    this.fillColor,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.pinCodeOptions,
    this.confirmPaswordValidation,
    this.maxLength,
    this.maxLines,
    this.minLines,
    this.keyboardType,
    this.inputAction,
    this.disabledBorder,
    this.border,
    this.focusedBorder,
    this.errorBorder,
    this.enabledBorder,
    this.contentPadding,
  });
}
