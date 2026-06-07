import 'package:quran/core/services/forms/base_form_controller.dart';
import 'package:quran/core/widgets/forms/w_pin_code_field.dart';

class FOtp extends BaseFormController {
  late WPinCodeField pinCodeField;

  @override
  void init() {
    pinCodeField = WPinCodeField(hint: '');
  }

  @override
  bool validate() {
    return pinCodeField.controller.text.isNotEmpty;
  }

  @override
  void clear() {
    pinCodeField.clear();
  }
}
