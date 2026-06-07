import 'package:quran/core/extension/string_extensions.dart';
import 'package:quran/core/services/forms/base_form_controller.dart';
import 'package:quran/core/widgets/forms/w_email_field.dart';
import 'package:quran/core/widgets/forms/w_password_field.dart';

class FLogin extends BaseFormController {
  late WEmailField emailField;
  late WPasswordField passwordField;

  @override
  void init() {
    emailField = WEmailField(hint: 'auth_email'.translated, isRequired: true);
    passwordField = WPasswordField(hint: 'auth_password'.translated);
  }

  @override
  bool validate() {
    return formKey.currentState?.validate() ?? false;
  }

  @override
  void clear() {
    emailField.clear();
    passwordField.clear();
  }
}
