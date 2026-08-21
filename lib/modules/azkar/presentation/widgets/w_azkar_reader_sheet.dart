import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';

/// Bottom sheet for picking a reader.
///
/// Only ever handed readers that actually have the dhikr in question, so a
/// choice here always produces sound. Returns the chosen reader id, or the
/// sentinel [autoValue] when the user picks "any available reader".
class WAzkarReaderSheet extends StatelessWidget {
  const WAzkarReaderSheet({
    required this.readers,
    required this.selectedId,
    this.title,
    this.showAutoOption = true,
    super.key,
  });

  /// Chosen when the user wants the app to decide — clears the pin.
  static const String autoValue = '__auto__';

  final List<MAzkarReader> readers;
  final String? selectedId;
  final String? title;
  final bool showAutoOption;

  /// Returns the picked reader id, [autoValue], or null when dismissed.
  static Future<String?> show(
    BuildContext context, {
    required List<MAzkarReader> readers,
    String? selectedId,
    String? title,
    bool showAutoOption = true,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WAzkarReaderSheet(
        readers: readers,
        selectedId: selectedId,
        title: title,
        showAutoOption: showAutoOption,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: brand.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 10.h, bottom: 6.h),
            child: Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: brand.border,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 10.h),
            child: Text(
              title ?? 'azkar_audio_reader'.tr(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: brand.onSurface,
              ),
            ),
          ),
          if (readers.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Text(
                'azkar_audio_no_readers'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: brand.muted),
              ),
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.only(bottom: 20.h),
              children: [
                if (showAutoOption)
                  _ReaderTile(
                    title: 'azkar_audio_reader_auto'.tr(),
                    subtitle: 'azkar_audio_reader_auto_hint'.tr(),
                    selected: selectedId == null || selectedId!.isEmpty,
                    icon: Icons.auto_awesome_rounded,
                    onTap: () => Navigator.of(context).pop(autoValue),
                  ),
                for (final reader in readers)
                  _ReaderTile(
                    title: reader.displayName(isArabic),
                    subtitle: _subtitleFor(reader),
                    selected: reader.id == selectedId,
                    icon: Icons.record_voice_over_rounded,
                    onTap: () => Navigator.of(context).pop(reader.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Says plainly what the reader offers — individual adhkar, whole sittings,
  /// or both — so nobody downloads 174 MB expecting per-dhikr playback.
  String _subtitleFor(MAzkarReader reader) {
    final parts = <String>[
      if (reader.mappedAdhkar > 0)
        '${reader.mappedAdhkar} ${'azkar_audio_unit_adhkar'.tr()}',
      if (reader.categoryRecordings > 0)
        '${reader.categoryRecordings} ${'azkar_audio_unit_sittings'.tr()}',
    ];
    return parts.isEmpty ? reader.sourceName : parts.join(' · ');
  }
}

class _ReaderTile extends StatelessWidget {
  const _ReaderTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18.r,
        backgroundColor: brand.primary.withValues(alpha: 0.12),
        child: Icon(icon, size: 18.r, color: brand.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: brand.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11.sp, color: brand.muted),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: brand.primary, size: 22.r)
          : null,
    );
  }
}
