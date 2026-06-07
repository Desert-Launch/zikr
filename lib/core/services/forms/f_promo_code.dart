import 'package:quran/core/extension/string_extensions.dart';
import 'package:quran/core/services/forms/base_form_controller.dart';
import 'package:quran/core/widgets/forms/w_promo_field.dart';

class FPromoCode extends BaseFormController {
  late WPromoField promoCodeField;

  @override
  void init() {
    promoCodeField = WPromoField(hint: 'Promo Code'.translated);
  }

  @override
  bool validate() {
    return formKey.currentState!.validate();
  }

  @override
  void clear() {
    promoCodeField.clear();
  }
}
