import 'package:flutter/material.dart';
import 'package:quran/core/config/params/params_custom_input.dart';
import 'package:quran/core/utils/input_field_validator.dart';
import 'package:quran/core/widgets/forms/base_form_field.dart';
import 'package:quran/core/widgets/forms/w_shared_field.dart';

class WEmailField extends BaseFormField {
  WEmailField({
    super.isRequired = true,
    super.hint = '',
    super.label = '',
    super.icon = Icons.mail_outline_rounded,
    super.validators = const [InputFieldValidator.validateEmail],
    super.fieldName = '',
  });

  @override
  Widget buildField(BuildContext context, {ParamsCustomInput? param}) {
    return WSharedField(
      controller: controller,
      focusNode: focusNode,
      validatorKey: fieldKey,
      hint: hint,
      onValidate: validate,
      keyboardType: TextInputType.emailAddress,
      textInputAction: param?.inputAction ?? textInputAction,
      onChanged: param?.onChanged,
      onFieldSubmitted: param?.onFieldSubmitted,
      enabled: param?.enabled ?? true,
      prefixIcon: param?.prefixIcon ?? buildPrefix(),
    );
  }
}
