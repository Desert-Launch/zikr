import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/cubits/cb_theme.dart';
import 'package:quran/core/cubits/s_theme.dart';

class WThemePicker extends StatelessWidget {
  const WThemePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBTheme, STheme>(
      bloc: Modular.get<CBTheme>(),
      builder: (context, state) {
        return RadioGroup<EThemeMode>(
          groupValue: state.mode,
          onChanged: (m) {
            if (m != null) Modular.get<CBTheme>().setMode(m);
          },
          child: Column(
            children: EThemeMode.values
                .map((mode) => RadioListTile<EThemeMode>(
                      value: mode,
                      title: Text(
                        _labelFor(mode),
                        style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(_subtitleFor(mode),
                          style: TextStyle(fontSize: 11.sp)),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  String _labelFor(EThemeMode m) => switch (m) {
        EThemeMode.system => 'settings_theme_system'.tr(),
        EThemeMode.light => 'settings_theme_light'.tr(),
        EThemeMode.dark => 'settings_theme_dark'.tr(),
      };

  String _subtitleFor(EThemeMode m) => switch (m) {
        EThemeMode.system => 'settings_theme_system_hint'.tr(),
        EThemeMode.light => 'settings_theme_light_hint'.tr(),
        EThemeMode.dark => 'settings_theme_dark_hint'.tr(),
      };
}
