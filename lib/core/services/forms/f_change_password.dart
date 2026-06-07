import 'package:quran/core/extension/string_extensions.dart';
import 'package:quran/core/services/forms/base_form_controller.dart';
import 'package:quran/core/widgets/forms/w_confirm_password_field.dart';
import 'package:quran/core/widgets/forms/w_password_field.dart';

class FChangePassword extends BaseFormController {
  late WPasswordField currentPasswordField;
  late WPasswordField newPasswordField;
  late WConfirmPasswordField confirmNewPasswordField;

  @override
  void init() {
    currentPasswordField = WPasswordField(hint: 'Old Password'.translated);
    newPasswordField = WPasswordField(hint: 'New Password'.translated);
    confirmNewPasswordField = WConfirmPasswordField(
      hint: 'Confirm New Password'.translated,
    );
  }

  @override
  bool validate() {
    return formKey.currentState!.validate();
  }

  @override
  void clear() {
    currentPasswordField.clear();
    newPasswordField.clear();
    confirmNewPasswordField.clear();
  }
}
