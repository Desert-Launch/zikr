import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_check.dart';

/// One option in a [WPrayerChoiceSheet].
class PrayerChoice<T> {
  const PrayerChoice({required this.value, required this.label, this.hint});

  final T value;
  final String label;

  /// Optional one-line explanation — what the option actually does, for
  /// settings (the high-latitude rules especially) that mean nothing from
  /// their name alone.
  final String? hint;
}

/// Single-choice bottom sheet, used for the short calculation settings that
/// don't earn a screen of their own (Asr school, high-latitude rule).
///
/// Returns the chosen value, or null when dismissed.
class WPrayerChoiceSheet<T> extends StatelessWidget {
  const WPrayerChoiceSheet({
    required this.title,
    required this.choices,
    required this.selected,
    super.key,
  });

  final String title;
  final List<PrayerChoice<T>> choices;
  final T selected;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<PrayerChoice<T>> choices,
    required T selected,
  }) => showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
    ),
    builder: (_) => WPrayerChoiceSheet<T>(
      title: title,
      choices: choices,
      selected: selected,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isTab = context.isTablet;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(22.w, 18.h, 22.w, 8.h),
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: isTab ? 18 : 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF252525),
              ),
            ),
          ),
          for (final choice in choices)
            ListTile(
              onTap: () => Navigator.of(context).pop(choice.value),
              title: Text(
                choice.label,
                style: GoogleFonts.cairo(
                  fontSize: isTab ? 16 : 13.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF303030),
                ),
              ),
              subtitle: choice.hint == null
                  ? null
                  : Text(
                      choice.hint ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: isTab ? 12.5 : 10.sp,
                        color: const Color(0xFF858585),
                      ),
                    ),
              trailing: WSettingsCheck(selected: choice.value == selected),
            ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }
}
