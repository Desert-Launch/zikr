import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';

import 'package:quran/modules/reminders/data/sources/local/box_reminders.dart';
import 'package:quran/modules/reminders/presentation/cubits/cb_reminders.dart';

class SNReminderForm extends StatefulWidget {
  const SNReminderForm({super.key, this.reminderId});

  /// When present, edit this reminder; otherwise create a new one.
  final String? reminderId;

  @override
  State<SNReminderForm> createState() => _SNReminderFormState();
}

class _SNReminderFormState extends State<SNReminderForm> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  List<bool> _days = List<bool>.filled(7, true);
  bool _isSubmitting = false;
  String? _error;

  static const _dayLabels = ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];

  bool get _isEdit => widget.reminderId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final existing = Modular.get<BoxReminders>().byId(widget.reminderId!);
      if (existing != null) {
        _titleCtrl.text = existing.title;
        _bodyCtrl.text = existing.body;
        _time = TimeOfDay(hour: existing.hour, minute: existing.minute);
        _days = List<bool>.from(existing.daysOfWeek);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'reminders_title_required'.tr());
      return;
    }
    if (!_days.any((d) => d)) {
      setState(() => _error = 'reminders_days_required'.tr());
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final cb = Modular.get<CBReminders>();
    if (_isEdit) {
      final r = Modular.get<BoxReminders>().byId(widget.reminderId!);
      if (r != null) {
        r
          ..title = title
          ..body = _bodyCtrl.text.trim()
          ..hour = _time.hour
          ..minute = _time.minute
          ..daysOfWeek = _days;
        await cb.update(r);
      }
    } else {
      final err = await cb.create(
        title: title,
        body: _bodyCtrl.text.trim(),
        hour: _time.hour,
        minute: _time.minute,
        daysOfWeek: _days,
      );
      if (err != null) {
        setState(() {
          _isSubmitting = false;
          _error = 'reminders_max_reached'.tr();
        });
        return;
      }
    }
    if (!mounted) return;
    Modular.to.pop();
  }

  Future<void> _delete() async {
    if (!_isEdit) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('reminders_delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common_cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColorsLight.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common_delete'.tr()),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await Modular.get<CBReminders>().delete(widget.reminderId!);
    if (!mounted) return;
    Modular.to.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'reminders_edit'.tr() : 'reminders_add'.tr(),
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'reminders_title_field'.tr(),
              border: const OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _bodyCtrl,
            decoration: InputDecoration(
              labelText: 'reminders_body_field'.tr(),
              border: const OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16.h),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(color: context.brand.border),
            ),
            child: ListTile(
              title: Text('reminders_time'.tr(),
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
              subtitle: Text(_time.format(context),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColorsLight.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
              trailing: const Icon(Icons.access_time_rounded),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (picked != null) setState(() => _time = picked);
              },
            ),
          ),
          SizedBox(height: 14.h),
          Text('reminders_days'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                color: context.brand.muted,
                fontWeight: FontWeight.w700,
              )),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final selected = _days[i];
              return GestureDetector(
                onTap: () => setState(() => _days[i] = !selected),
                child: Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColorsLight.primary
                        : context.brand.surface,
                    border: Border.all(
                      color: selected
                          ? AppColorsLight.primary
                          : context.brand.border,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _dayLabels[i],
                    style: TextStyle(
                      color: selected ? Colors.white : context.brand.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              );
            }),
          ),
          if (_error != null) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColorsLight.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColorsLight.error, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 16.r, color: AppColorsLight.error),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(_error!,
                        style: TextStyle(
                          color: AppColorsLight.error,
                          fontSize: 12.sp,
                        )),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColorsLight.primary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 20.r, height: 20.r,
                      child: const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.2,
                      ),
                    )
                  : Text(_isEdit ? 'common_done'.tr() : 'reminders_create'.tr(),
                      style: TextStyle(
                        fontSize: 15.sp, fontWeight: FontWeight.w700,
                      )),
            ),
          ),
        ],
      ),
    );
  }
}
