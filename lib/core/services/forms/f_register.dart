import 'package:flutter/material.dart';
import 'package:quran/core/extension/string_extensions.dart';
import 'package:quran/core/services/forms/base_form_controller.dart';
import 'package:quran/core/utils/input_field_validator.dart';
import 'package:quran/core/widgets/forms/w_confirm_password_field.dart';
import 'package:quran/core/widgets/forms/w_date_field.dart';
import 'package:quran/core/widgets/forms/w_email_field.dart';
import 'package:quran/core/widgets/forms/w_password_field.dart';
import 'package:quran/core/widgets/forms/w_phone_field.dart';
import 'package:quran/core/widgets/forms/w_text_field.dart';

class FRegister extends BaseFormController {
  late WTextField nameField;
  late WDateField birthDateField;
  late WEmailField emailField;
  late WPhoneField phoneField;
  late WPasswordField passwordField;
  late WConfirmPasswordField confirmPasswordField;

  @override
  void init() {
    nameField = WTextField(
      hint: 'auth_name'.translated,
      icon: Icons.person_outline_rounded,
      validators: [InputFieldValidator.validateFullName],
    );
    birthDateField = WDateField(
      hint: 'auth_birth_date'.translated,
      isRequired: true,
      validators: [InputFieldValidator.validateDateRequired],
    );
    emailField = WEmailField(hint: 'auth_email'.translated);
    phoneField = WPhoneField(
      hint: 'auth_phone'.translated,
      isRequired: true,
      validators: [InputFieldValidator.validateQatarPhoneRequired],
    );
    passwordField = WPasswordField(hint: 'auth_password'.translated);
    confirmPasswordField = WConfirmPasswordField(
      hint: 'auth_confirm_password'.translated,
      validators: [
        (value) => InputFieldValidator.validateConfirmPassword(
          value,
          passwordField.controller.text,
        ),
      ],
    );
  }

  @override
  bool validate() {
    return formKey.currentState?.validate() ?? false;
  }

  @override
  void clear() {
    nameField.clear();
    birthDateField.clear();
    emailField.clear();
    phoneField.clear();
    passwordField.clear();
    confirmPasswordField.clear();
  }
}
