import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';

/// Horizontal target picker: preset chips plus a custom-value chip that
/// opens a number dialog. Drives [STasbih.target] via [onChanged].
class WTasbihTargetSelector extends StatelessWidget {
  const WTasbihTargetSelector({
    super.key,
    required this.target,
    required this.green,
    required this.onChanged,
  });

  final int target;
  final Color green;
  final ValueChanged<int> onChanged;

  static const _presets = [33, 99, 100, 500, 1000];

  @override
  Widget build(BuildContext context) {
    final isCustom = !_presets.contains(target);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('tasbih_target_label'.tr(), style: AppTextStyles.grey12W400),
        SizedBox(height: 8.h),
        SizedBox(
          height: 38.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: _presets.length + 1,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (_, index) {
              if (index < _presets.length) {
                final value = _presets[index];
                return _chip(label: '$value', active: target == value, onTap: () => onChanged(value));
              }
              return _chip(
                label: isCustom ? '$target' : 'tasbih_target_custom'.tr(),
                active: isCustom,
                icon: Icons.edit_outlined,
                onTap: () => _openCustom(context),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip({required String label, required bool active, required VoidCallback onTap, IconData? icon}) {
    return InkWell(
      borderRadius: BorderRadius.circular(19.r),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: active ? green.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(19.r),
          border: Border.all(color: active ? green : const Color(0xFFE8E7E2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14.sp, color: active ? green : Colors.black54),
              SizedBox(width: 4.w),
            ],
            Text(
              label,
              style: active
                  ? AppTextStyles.ink14W400.copyWith(color: green, fontWeight: FontWeight.w700)
                  : AppTextStyles.ink14W400,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCustom(BuildContext context) async {
    final controller = TextEditingController(text: _presets.contains(target) ? '' : '$target');
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('tasbih_target_custom_title'.tr(), style: AppTextStyles.ink16W400),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          decoration: InputDecoration(hintText: 'tasbih_target_custom_hint'.tr()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('common_cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: Text('common_done'.tr()),
          ),
        ],
      ),
    );
    if (value != null && value > 0) onChanged(value);
  }
}
