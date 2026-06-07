import 'package:quran/core/extension/string_extensions.dart';
import 'package:quran/core/services/forms/base_form_controller.dart';
import 'package:quran/core/widgets/forms/w_email_field.dart';

class FForgetPassword extends BaseFormController {
  late WEmailField emailField;

  FForgetPassword() {
    init();
  }

  @override
  void init() {
    emailField = WEmailField(hint: 'auth_email'.translated, isRequired: true);
  }

  @override
  bool validate() {
    return formKey.currentState?.validate() ?? false;
  }

  @override
  void clear() {
    emailField.clear();
  }
}
