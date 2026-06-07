import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/core/config/params/params_custom_input.dart';
import 'package:quran/core/utils/input_field_validator.dart';
import 'package:quran/core/widgets/forms/w_input_prefix_icon.dart';

abstract class BaseFormField {
  final TextEditingController controller;
  final FocusNode focusNode;
  final GlobalKey<FormFieldState> fieldKey;
  final String hint;
  final String label;
  final String fieldName;
  final bool isRequired;
  final IconData? icon;
  final String? customRequiredMessage;
  final ParamsCustomInput? params;
  final List<TextInputFormatter> inputFormatters = [];
  List<String? Function(String?)?>? validators;
  TextInputAction? textInputAction;

  BaseFormField({
    required this.hint,
    required this.label,
    this.fieldName = '',
    this.icon,
    this.validators,
    this.isRequired = false,
    this.customRequiredMessage,
    this.params,
  }) : controller = TextEditingController(),
       focusNode = FocusNode(),
       fieldKey = GlobalKey<FormFieldState>(),
       textInputAction = TextInputAction.next;

  String? validate(String? v) {
    final value = v ?? controller.text;
    if (isRequired) {
      final error = InputFieldValidator.validateRequired(
        value: value,
        fieldName: fieldName,
        customMessage: customRequiredMessage,
      );
      if (error != null) {
        return error;
      }
    }
    if (validators != null) {
      for (final validator in (params?.validators ?? validators ?? [])) {
        final error = validator?.call(value);
        if (error != null) {
          return error;
        }
      }
    }
    return null;
  }

  /// Leading affix shown inside the field: the field icon, a divider and the
  /// required `*` marker — matching the auth design. Returns null when the
  /// field has no icon (the divider/star are anchored to the icon).
  Widget? buildPrefix() {
    if (icon == null) return null;
    return WInputPrefixIcon(icon: icon!, isRequired: isRequired);
  }

  void clear() {
    controller.clear();
  }

  Widget buildField(BuildContext context, {ParamsCustomInput? param});
}
