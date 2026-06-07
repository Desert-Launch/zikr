import 'package:quran/core/extension/string_extensions.dart';
import 'package:quran/core/services/forms/base_form_controller.dart';
import 'package:quran/core/utils/input_field_validator.dart';
import 'package:quran/core/widgets/forms/w_email_field.dart';
import 'package:quran/core/widgets/forms/w_phone_field.dart';
import 'package:quran/core/widgets/forms/w_text_field.dart';

class FEditProfile extends BaseFormController {
  late WTextField username;
  late WEmailField emailField;
  late WPhoneField phoneField;

  @override
  void init() {
    username = WTextField(
      hint: 'Name'.translated,
      validators: [InputFieldValidator.validateFullName],
    );

    emailField = WEmailField(hint: 'Email'.translated);
    phoneField = WPhoneField(hint: 'Phone number'.translated);
  }

  @override
  bool validate() {
    return formKey.currentState!.validate();
  }

  @override
  void clear() {
    username.clear();
    emailField.clear();
    phoneField.clear();
  }
}
