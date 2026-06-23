import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_app_button.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/reminders/data/sources/local/box_reminders.dart';
import 'package:quran/modules/reminders/presentation/cubits/cb_reminders.dart';
import 'package:quran/modules/reminders/presentation/reminder_styles.dart';
import 'package:quran/modules/reminders/presentation/widgets/w_reminders_header.dart';

class SNReminderForm extends StatefulWidget {
  const SNReminderForm({super.key, this.reminderId});

  /// When present, edit this reminder; otherwise create a new one.
  final String? reminderId;

  @override
  State<SNReminderForm> createState() => _SNReminderFormState();
}

class _SNReminderFormState extends State<SNReminderForm> {
  final _titleCtrl = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  int _iconId = ReminderStyles.defaultIcon;
  int _colorId = ReminderStyles.defaultColor;
  bool _repeatDaily = true;
  String _existingBody = '';
  bool _isSubmitting = false;
  String? _error;

  bool get _isEdit => widget.reminderId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final existing = Modular.get<BoxReminders>().byId(widget.reminderId ?? '');
      if (existing != null) {
        _titleCtrl.text = existing.title;
        _existingBody = existing.body;
        _time = TimeOfDay(hour: existing.hour, minute: existing.minute);
        _iconId = existing.iconId;
        _colorId = existing.colorId;
        _repeatDaily = existing.isDaily;
      }
    }
    _titleCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  /// Sunday..Saturday mask. Daily repeat → all true; otherwise just today's
  /// weekday (index 0 = Sunday) so the reminder fires only on that single day.
  List<bool> _buildDays() {
    if (_repeatDaily) return List<bool>.filled(7, true);
    final days = List<bool>.filled(7, false);
    final weekday = DateTime.now().weekday; // 1 = Mon .. 7 = Sun
    days[weekday == DateTime.sunday ? 0 : weekday] = true;
    return days;
  }

  String _formatTime() {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = _time.hour > 12 ? _time.hour - 12 : (_time.hour == 0 ? 12 : _time.hour);
    final suffix = _time.hour >= 12 ? 'reminders_pm'.tr() : 'reminders_am'.tr();
    return '${two(h)}:${two(_time.minute)} $suffix';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'reminders_title_required'.tr());
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final cb = Modular.get<CBReminders>();
    if (_isEdit) {
      final r = Modular.get<BoxReminders>().byId(widget.reminderId ?? '');
      if (r != null) {
        r
          ..title = title
          ..hour = _time.hour
          ..minute = _time.minute
          ..daysOfWeek = _buildDays()
          ..iconId = _iconId
          ..colorId = _colorId;
        await cb.update(r);
      }
    } else {
      final err = await cb.create(
        title: title,
        body: _existingBody,
        hour: _time.hour,
        minute: _time.minute,
        daysOfWeek: _buildDays(),
        iconId: _iconId,
        colorId: _colorId,
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('reminders_delete_confirm'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common_cancel'.tr())),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColorsLight.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common_delete'.tr()),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await Modular.get<CBReminders>().delete(widget.reminderId ?? '');
    if (!mounted) return;
    Modular.to.pop();
  }

  @override
  Widget build(BuildContext context) {
    return WSharedScaffold(
      backgroundColor: context.brand.background,
      withSafeArea: false,
      padding: EdgeInsets.zero,
      body: Directionality(
        textDirection: context.isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          children: [
            WRemindersHeader(title: 'reminders_title'.tr()),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isEdit ? 'reminders_edit'.tr() : 'reminders_new_title'.tr(),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: context.brand.onSurface,
                          ),
                        ),
                      ),
                      if (_isEdit)
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: AppColorsLight.error),
                          onPressed: _delete,
                        ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  _label('reminders_title_label'.tr()),
                  SizedBox(height: 6.h),
                  _titleField(context),
                  SizedBox(height: 16.h),
                  _label('reminders_time_label'.tr()),
                  SizedBox(height: 6.h),
                  _timeField(context),
                  SizedBox(height: 18.h),
                  _label('reminders_choose_icon'.tr()),
                  SizedBox(height: 8.h),
                  _iconGrid(context),
                  SizedBox(height: 14.h),
                  _label('reminders_choose_color'.tr()),
                  SizedBox(height: 10.h),
                  _colorRow(),
                  SizedBox(height: 18.h),
                  _repeatToggle(context),
                  SizedBox(height: 18.h),
                  _preview(context),
                  if (_error != null) ...[SizedBox(height: 14.h), _errorBanner()],
                  SizedBox(height: 22.h),
                  Row(
                    children: [
                      Expanded(
                        child: WAppButton(
                          title: 'common_cancel'.tr(),
                          variant: AppButtonVariant.outline,
                          onTap: () => Modular.to.pop(),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: WAppButton(
                          title: 'reminders_save'.tr(),
                          isLoading: _isSubmitting,
                          backgroundColor: AppColorsLight.primary,
                          onTap: _save,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: context.brand.onSurface),
  );

  Widget _titleField(BuildContext context) {
    return TextField(
      controller: _titleCtrl,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: 'reminders_title_hint'.tr(),
        hintStyle: TextStyle(color: context.brand.muted, fontSize: 13.sp),
        filled: true,
        fillColor: context.brand.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: context.brand.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColorsLight.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _timeField(BuildContext context) {
    return InkWell(
      onTap: _pickTime,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: context.brand.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: context.brand.border),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, size: 18.r, color: AppColorsLight.primary),
            SizedBox(width: 10.w),
            Text(
              _formatTime(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: context.brand.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            Icon(Icons.keyboard_arrow_down_rounded, color: context.brand.muted, size: 22.r),
          ],
        ),
      ),
    );
  }

  Widget _iconGrid(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GridView.count(
        crossAxisCount: 4,
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 1.75,
        children: List.generate(ReminderStyles.iconAssets.length, (i) {
          final selected = i == _iconId;
          return GestureDetector(
            onTap: () => setState(() => _iconId = i),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColorsLight.primary.withValues(alpha: 0.10) : Colors.transparent,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: selected ? AppColorsLight.primary : AppColorsLight.primary.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              child: SvgPicture.asset(
                ReminderStyles.iconAssets[i],
                width: 20.r,
                height: 20.r,
                colorFilter: ColorFilter.mode(
                  selected ? AppColorsLight.primary : context.brand.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _colorRow() {
    final last = ReminderStyles.colors.length - 1;
    return Row(
      children: List.generate(ReminderStyles.colors.length, (i) {
        final color = ReminderStyles.colors[i];
        final selected = i == _colorId;
        return Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: i == last ? 0 : 12.w),
            child: GestureDetector(
              onTap: () => setState(() => _colorId = i),
              child: Container(
                height: 48.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.r),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(color, Colors.white, 0.22) ?? color, color],
                  ),
                  border: selected ? Border.all(color: Colors.white, width: 3) : null,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: selected ? 0.45 : 0.22),
                      blurRadius: selected ? 12 : 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: selected ? Icon(Icons.check_rounded, color: Colors.white, size: 24.r) : null,
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Toggle: ON → repeats every day; OFF → fires only on the current weekday.
  Widget _repeatToggle(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(8.w, 4.h, 16.w, 4.h),
      decoration: BoxDecoration(
        color: context.brand.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.brand.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'reminders_daily_repeat'.tr(),
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: context.brand.onSurface),
          ),

          Switch.adaptive(
            value: _repeatDaily,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColorsLight.primary,
            onChanged: (v) => setState(() => _repeatDaily = v),
          ),
        ],
      ),
    );
  }

  Widget _preview(BuildContext context) {
    final color = ReminderStyles.colorFor(_colorId);
    final title = _titleCtrl.text.trim().isEmpty ? 'reminders_preview_placeholder'.tr() : _titleCtrl.text.trim();
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 18.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColorsLight.primary.withValues(alpha: 0.25)),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topCenter,
          end: AlignmentDirectional.bottomCenter,
          colors: [color.withValues(alpha: 0.16), AppColorsLight.accent.withValues(alpha: 0.16)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'reminders_preview'.tr(),
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.brand.muted),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54.r,
                      height: 54.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: SvgPicture.asset(
                        ReminderStyles.iconAssetFor(_iconId),
                        width: 24.r,
                        height: 24.r,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                    ),

                    SizedBox(width: 12.w),
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: context.brand.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.brand.muted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.access_time_rounded, size: 14.r, color: context.brand.muted),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColorsLight.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColorsLight.error, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16.r, color: AppColorsLight.error),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _error ?? '',
              style: TextStyle(color: AppColorsLight.error, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }
}
