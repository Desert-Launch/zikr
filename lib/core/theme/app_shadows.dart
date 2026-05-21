import 'package:flutter/material.dart';
import 'package:quran/core/theme/app_colors.dart';

class AppShadows {
  AppShadows._();

  static List<BoxShadow> card() => [
    BoxShadow(color: AppColors.cleanCardShadow, blurRadius: 12, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> cardLight() => [
    BoxShadow(color: AppColors.cleanCardShadowLight, blurRadius: 8, offset: const Offset(0, 2)),
  ];
}
