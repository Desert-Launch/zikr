import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';

class SNPrayerSettingsOverview extends StatefulWidget {
  const SNPrayerSettingsOverview({super.key});

  @override
  State<SNPrayerSettingsOverview> createState() =>
      _SNPrayerSettingsOverviewState();
}

class _SNPrayerSettingsOverviewState extends State<SNPrayerSettingsOverview> {
  static const _green = Color(0xFF2F7E63);
  static const _canvas = Color(0xFFFAF9F7);
  static const _border = Color(0xFFE2ECE8);

  bool _automaticLocation = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: WGradientAppBar(title: 'prayer_settings_title'.tr()),
      body: ListView(
        padding: EdgeInsets.fromLTRB(19.w, 26.h, 19.w, 28.h),
        children: [
          _Group(
            children: [
              _Row(
                icon: Icons.explore_outlined,
                title: 'prayer_settings_qibla'.tr(),
                subtitle: 'prayer_settings_qibla_hint'.tr(),
                onTap: () => Modular.to.pushNamed(RoutesNames.qiblaBase),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _Group(
            children: [
              _Row(
                icon: Icons.notifications_none_rounded,
                title: 'prayer_settings_alerts'.tr(),
                subtitle: 'prayer_settings_alerts_hint'.tr(),
                onTap: () =>
                    Modular.to.pushNamed(AdhanRoutes.notificationsScreen()),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          Padding(
            padding: EdgeInsetsDirectional.only(start: 8.w, bottom: 8.h),
            child: Text(
              'prayer_settings_location_section'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 10.sp,
                color: const Color(0xFF777777),
              ),
            ),
          ),
          _Group(
            children: [
              _Row(
                icon: Icons.location_on_outlined,
                title: 'prayer_settings_auto_location'.tr(),
                subtitle: 'prayer_settings_auto_location_hint'.tr(),
                trailing: Transform.scale(
                  scale: .75,
                  child: Switch(
                    value: _automaticLocation,
                    activeTrackColor: _green,
                    thumbColor: WidgetStateProperty.all(Colors.white),
                    onChanged: (value) =>
                        setState(() => _automaticLocation = value),
                  ),
                ),
              ),
              _Row(
                icon: Icons.location_on_outlined,
                title: 'prayer_settings_manual_location'.tr(),
                onTap: () => Modular.to.pushNamed(RoutesNames.prayerBase),
              ),
            ],
          ),
          SizedBox(height: 142.h),
          const _VirtueCard(),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19.r),
        border: Border.all(color: _SNPrayerSettingsOverviewState._border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19.r),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                const Divider(height: 1, color: Color(0xFFEDF1EF)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 82.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Row(
            children: [
              Container(
                width: 42.r,
                height: 42.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F4ED),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: _SNPrayerSettingsOverviewState._green,
                  size: 21.r,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 14.sp,
                        color: const Color(0xFF303030),
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 3.h),
                      Text(
                        subtitle!,
                        style: GoogleFonts.cairo(
                          fontSize: 9.sp,
                          color: const Color(0xFF858585),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_left_rounded,
                    color: const Color(0xFF777777),
                    size: 22.r,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VirtueCard extends StatelessWidget {
  const _VirtueCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 18.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF6DE), Color(0xFFF4DDA8)],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFD9B947), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: const Color(0xFFD9B947),
            child: Icon(Icons.star_rounded, color: Colors.white, size: 22.r),
          ),
          SizedBox(height: 8.h),
          Text(
            'khatma_virtue_title'.tr(),
            style: GoogleFonts.cairo(
              fontSize: 11.sp,
              color: const Color(0xFF8C7A55),
            ),
          ),
          SizedBox(height: 11.h),
          Text(
            'إِنَّ الَّذِينَ يَتْلُونَ كِتَابَ اللَّهِ وَأَقَامُوا الصَّلَاةَ وَأَنفَقُوا مِمَّا رَزَقْنَاهُمْ سِرًّا وَعَلَانِيَةً يَرْجُونَ تِجَارَةً لَّن تَبُورَ',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 14.sp,
              height: 1.8,
              color: const Color(0xFF3E3522),
            ),
          ),
          Text(
            '[فاطر: 29]',
            style: GoogleFonts.cairo(
              fontSize: 10.sp,
              color: const Color(0xFF8C7A55),
            ),
          ),
        ],
      ),
    );
  }
}
