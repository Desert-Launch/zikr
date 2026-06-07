import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/config/params/params_custom_input.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/extension/color_extension.dart';
import 'package:quran/core/extension/text_theme_extension.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/forms/base_form_field.dart';

class WCheckboxField extends BaseFormField {
  WCheckboxField({
    super.label = '',
    super.hint = '',
    super.fieldName = '',
    super.isRequired = false,
    bool initialValue = false,
    this.checkboxLabel,
    this.onChanged,
  }) : _value = initialValue;

  bool _value;
  final String? checkboxLabel;
  final ValueChanged<bool>? onChanged;

  set value(bool newValue) {
    _value = newValue;
  }

  @override
  Widget buildField(BuildContext context, {ParamsCustomInput? param}) {
    return _CheckboxFieldContent(
      fieldLabel: label,
      hint: hint,
      checkboxLabel: checkboxLabel ?? label,
      value: _value,
      onChanged: (newValue) {
        _value = newValue;
        onChanged?.call(newValue);
      },
    );
  }

  @override
  void clear() {
    _value = false;
  }
}

class _CheckboxFieldContent extends StatefulWidget {
  const _CheckboxFieldContent({
    required this.fieldLabel,
    required this.hint,
    required this.checkboxLabel,
    required this.value,
    required this.onChanged,
  });

  final String fieldLabel;
  final String hint;
  final String checkboxLabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<_CheckboxFieldContent> createState() => _CheckboxFieldContentState();
}

class _CheckboxFieldContentState extends State<_CheckboxFieldContent> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant _CheckboxFieldContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _value = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final textTheme = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.fieldLabel.isNotEmpty)
          Text(widget.fieldLabel, style: textTheme.darkGrey14w700),
        if (widget.hint.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(widget.hint, style: textTheme.grey12w400),
          ),
        Padding(
          padding: EdgeInsets.only(top: 12.h),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: _toggle,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    Checkbox(
                      value: _value,
                      onChanged: (_) => _toggle(),
                      activeColor: context.brand.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        widget.checkboxLabel,
                        style: textTheme.darkGrey14w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggle() {
    setState(() {
      _value = !_value;
    });
    widget.onChanged(_value);
  }
}
