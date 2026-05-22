import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

class WLanguagePicker extends StatelessWidget {
  const WLanguagePicker({super.key});

  static const _supported = [
    ('ar', 'العربية'),
    ('en', 'English'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = LocalizeAndTranslate.getLanguageCode();
    return RadioGroup<String>(
      groupValue: current,
      onChanged: (code) async {
        if (code == null || code == current) return;
        await LocalizeAndTranslate.setLanguageCode(code);
        if (!context.mounted) return;
        (context as Element).markNeedsBuild();
      },
      child: Column(
        children: _supported
            .map((tuple) => RadioListTile<String>(
                  value: tuple.$1,
                  title: Text(tuple.$2,
                      style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w600,
                      )),
                ))
            .toList(),
      ),
    );
  }
}
