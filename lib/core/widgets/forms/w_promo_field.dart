import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/config/params/params_custom_input.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/extension/string_extensions.dart';
import 'package:quran/core/extension/text_theme_extension.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/forms/base_form_field.dart';
import 'package:quran/core/widgets/forms/w_shared_field.dart';

class WPromoField extends BaseFormField {
  WPromoField({
    super.isRequired = true,
    super.hint = '',
    super.label = '',
    super.fieldName = '',
  });

  @override
  Widget buildField(BuildContext context, {ParamsCustomInput? param}) {
    return WSharedField(
      controller: controller,
      focusNode: focusNode,
      hint: hint,
      label: label,
      onValidate: validate,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      onChanged: param?.onChanged,
      enabled: param?.enabled ?? true,
      prefixIcon: InkWell(
        onTap: param?.onPrefixIconPressed,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child:
              param?.prefixIcon ??
              Container(
                decoration: BoxDecoration(
                  color: context.brand.primary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                width: 60.w,
                child: Center(
                  child: Text(
                    'Confirm'.translated,
                    style: context.textTheme.white14w700,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
