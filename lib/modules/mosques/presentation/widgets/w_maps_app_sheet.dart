import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/mosques/services/maps_launcher.dart';

/// Lets an iPhone reader choose between Apple Maps and Google Maps.
class WMapsAppSheet extends StatelessWidget {
  const WMapsAppSheet({super.key});

  /// The map app to hand off to, or null when the sheet was dismissed.
  ///
  /// Android has one obvious answer (Google Maps ships on the device), so it
  /// skips the question; iOS asks, since Apple Maps is the built-in one but
  /// many readers navigate with Google Maps.
  static Future<MapsApp?> pick(BuildContext context) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return MapsApp.google;
    return showModalBottomSheet<MapsApp>(
      context: context,
      backgroundColor: context.brand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (_) => const WMapsAppSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(22.w, 18.h, 22.w, 6.h),
            child: Text(
              'mosques_open_with'.tr(),
              style: AppTextStyles.ink16W700.copyWith(color: brand.onSurface),
            ),
          ),
          _Option(
            app: MapsApp.apple,
            icon: Icons.map_outlined,
            label: 'mosques_apple_maps'.tr(),
          ),
          _Option(
            app: MapsApp.google,
            icon: Icons.public_rounded,
            label: 'mosques_google_maps'.tr(),
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.app, required this.icon, required this.label});

  final MapsApp app;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return ListTile(
      onTap: () => Navigator.of(context).pop(app),
      leading: Icon(icon, color: brand.primary),
      title: Text(
        label,
        style: AppTextStyles.ink14W500.copyWith(color: brand.onSurface),
      ),
    );
  }
}
