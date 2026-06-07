import 'package:quran/core/extension/string_extensions.dart';
import 'package:quran/core/services/forms/base_form_controller.dart';
import 'package:quran/core/utils/input_field_validator.dart';
import 'package:quran/core/widgets/forms/w_confirm_password_field.dart';
import 'package:quran/core/widgets/forms/w_password_field.dart';

class FResetPassword extends BaseFormController {
  late WPasswordField passwordField;
  late WConfirmPasswordField confirmPasswordField;

  @override
  void init() {
    passwordField = WPasswordField(hint: 'auth_new_password'.translated);
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
    passwordField.clear();
    confirmPasswordField.clear();
  }
}
