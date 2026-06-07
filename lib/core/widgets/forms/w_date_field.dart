import 'package:flutter/material.dart';
import 'package:quran/core/config/params/params_custom_input.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/widgets/forms/base_form_field.dart';
import 'package:quran/core/widgets/forms/w_shared_field.dart';

/// Read-only date field that opens a calendar picker on tap and writes the
/// selected date back as `dd/MM/yyyy`.
class WDateField extends BaseFormField {
  WDateField({
    super.isRequired = false,
    super.hint = '',
    super.label = '',
    super.fieldName = '',
    super.icon = Icons.calendar_today_outlined,
    super.validators,
    this.firstDate,
    this.lastDate,
    this.initialDate,
  });

  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;

  DateTime? selectedDate;

  @override
  Widget buildField(BuildContext context, {ParamsCustomInput? param}) {
    return WSharedField(
      controller: controller,
      focusNode: focusNode,
      validatorKey: fieldKey,
      hint: hint,
      readOnly: true,
      onValidate: validate,
      enabled: param?.enabled ?? true,
      prefixIcon: param?.prefixIcon ?? buildPrefix(),
      onTap: () => _pick(context, param),
    );
  }

  Future<void> _pick(BuildContext context, ParamsCustomInput? param) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? initialDate ?? DateTime(now.year - 18),
      firstDate: firstDate ?? DateTime(1920),
      lastDate: lastDate ?? now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColorsLight.primary,
            onPrimary: AppColorsLight.onPrimary,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null) return;
    selectedDate = picked;
    final text = '${_two(picked.day)}/${_two(picked.month)}/${picked.year}';
    controller.text = text;
    fieldKey.currentState?.didChange(text);
    param?.onChanged?.call(text);
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  void clear() {
    super.clear();
    selectedDate = null;
  }
}
