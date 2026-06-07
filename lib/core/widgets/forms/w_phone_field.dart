import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/config/params/params_custom_input.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/utils/input_field_validator.dart';
import 'package:quran/core/utils/input_formatters/phone_number_formatter.dart';
import 'package:quran/core/widgets/forms/base_form_field.dart';
import 'package:quran/core/widgets/forms/w_shared_field.dart';

class WPhoneField extends BaseFormField {
  WPhoneField({
    super.isRequired = false,
    super.hint = '',
    super.label = '',
    super.icon = Icons.phone_outlined,
    super.validators = const [InputFieldValidator.validateOptionalPhoneNumber],
    super.fieldName = '',
  });

  /// Qatar dial code — single source of truth for display and API body.
  static const String countryCode = '+974';

  @override
  Widget buildField(BuildContext context, {ParamsCustomInput? param}) {
    final brand = context.brand;
    final isEnabled = param?.enabled ?? true;
    return WSharedField(
      controller: controller,
      focusNode: focusNode,
      validatorKey: fieldKey,
      hint: hint,
      onValidate: validate,
      keyboardType: TextInputType.phone,
      textInputAction: param?.inputAction ?? textInputAction,
      onChanged: param?.onChanged,
      onFieldSubmitted: param?.onFieldSubmitted,
      enabled: isEnabled,
      textDirection: TextDirection.ltr,
      inputFormatters: [
        PhoneNumberFormatter(),
        LengthLimitingTextInputFormatter(9),
        FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
        FilteringTextInputFormatter.deny(RegExp(r'^( |0)')),
      ],
      prefixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 12.w),
          if (isRequired) ...[
            Text(
              '*',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                height: 1,
                color: brand.error,
              ),
            ),
            SizedBox(width: 6.w),
          ],
          const Text('🇶🇦', style: TextStyle(fontSize: 16)),
          SizedBox(width: 4.w),
          Text(
            countryCode,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: brand.onSurface,
            ),
          ),
          SizedBox(width: 8.w),
          Container(width: 1, height: 22.h, color: brand.border),
          SizedBox(width: 10.w),
        ],
      ),
      suffixIcon: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(icon, size: 20.sp, color: brand.muted),
      ),
    );
  }

  String toApiBody() {
    return '$countryCode${controller.text.replaceAll(' ', '')}';
  }

  /// Set raw digits (no spaces) and apply the same formatter used on input.
  void setRawDigits(String digits) {
    final cleaned = digits.replaceAll(RegExp(r'[^0-9]'), '');
    final formatter = PhoneNumberFormatter();
    final formatted = formatter.formatEditUpdate(
      const TextEditingValue(text: ''),
      TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      ),
    );
    controller.value = formatted;
  }
}
