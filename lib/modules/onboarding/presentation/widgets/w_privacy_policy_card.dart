import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/assets/assets.gen.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/legal/presentation/widgets/w_markdown_view.dart';

/// Scrollable privacy policy in the language picked on the same screen.
class WPrivacyPolicyCard extends StatelessWidget {
  const WPrivacyPolicyCard({super.key, required this.languageCode});
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final asset = languageCode == 'ar' ? Assets.legal.privacyAr : Assets.legal.privacyEn;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.brand.surface,
        border: Border.all(color: context.brand.border),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: WMarkdownView(asset: asset, padding: EdgeInsets.all(16.r), dense: true),
    );
  }
}
