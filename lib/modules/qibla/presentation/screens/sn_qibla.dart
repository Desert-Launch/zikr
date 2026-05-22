import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_cache.dart';

class SNQibla extends StatefulWidget {
  const SNQibla({super.key});

  @override
  State<SNQibla> createState() => _SNQiblaState();
}

class _SNQiblaState extends State<SNQibla> {
  // Kaaba coordinates (decimal degrees).
  static const _kaabaLat = 21.4225;
  static const _kaabaLng = 39.8262;

  double? _qiblaBearing;
  String? _error;
  StreamSubscription<CompassEvent>? _compassSub;
  double _heading = 0;
  bool _hasMagnetometer = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _wireCompass();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    final cache = Modular.get<BoxPrayerCache>().current();
    double? lat;
    double? lng;
    if (cache != null) {
      lat = cache.latitude;
      lng = cache.longitude;
    } else {
      try {
        final loc = await Modular.get<DSLocation>().currentPosition();
        if (loc != null) {
          lat = loc.latitude;
          lng = loc.longitude;
        }
      } on LocationException catch (e) {
        setState(() => _error = e.message);
        return;
      } catch (e) {
        setState(() => _error = e.toString());
        return;
      }
    }
    if (lat == null || lng == null) return;
    setState(() => _qiblaBearing = _bearingTo(lat!, lng!, _kaabaLat, _kaabaLng));
  }

  void _wireCompass() {
    final stream = FlutterCompass.events;
    if (stream == null) {
      setState(() => _hasMagnetometer = false);
      return;
    }
    _compassSub = stream.listen((event) {
      final h = event.heading;
      if (h != null && mounted) setState(() => _heading = h);
    });
  }

  /// Initial bearing from `(lat1,lng1)` to `(lat2,lng2)` in degrees (0..360).
  static double _bearingTo(double lat1, double lng1, double lat2, double lng2) {
    final phi1 = lat1 * math.pi / 180.0;
    final phi2 = lat2 * math.pi / 180.0;
    final dLambda = (lng2 - lng1) * math.pi / 180.0;
    final y = math.sin(dLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
    final theta = math.atan2(y, x);
    return (theta * 180.0 / math.pi + 360.0) % 360.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('qibla_title'.tr(),
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadLocation,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _build(context),
        ),
      ),
    );
  }

  Widget _build(BuildContext context) {
    if (!_hasMagnetometer) {
      return _ErrorState(
        icon: Icons.compass_calibration_rounded,
        title: 'qibla_no_compass_title'.tr(),
        body: 'qibla_no_compass_body'.tr(),
      );
    }
    if (_error != null) {
      return _ErrorState(
        icon: Icons.location_off_rounded,
        title: 'qibla_no_location_title'.tr(),
        body: _error!,
        onRetry: _loadLocation,
      );
    }
    if (_qiblaBearing == null) {
      return const CircularProgressIndicator();
    }
    // The dial rotates with the device. The qibla pointer sits relative to it.
    final qiblaAngle = (_qiblaBearing! - _heading) * math.pi / 180.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('qibla_heading_label'.tr(),
            style: TextStyle(
              fontSize: 12.sp, color: context.brand.muted,
            )),
        SizedBox(height: 4.h),
        Text('${_heading.toStringAsFixed(0)}°',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
        SizedBox(height: 24.h),
        SizedBox(
          width: 280.r,
          height: 280.r,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Static compass rose — rotates with heading so N points north.
              Transform.rotate(
                angle: -_heading * math.pi / 180.0,
                child: Container(
                  width: 280.r,
                  height: 280.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: context.brand.border, width: 2),
                  ),
                  child: const _CompassRose(),
                ),
              ),
              // Qibla arrow — aligned with kaaba direction.
              Transform.rotate(
                angle: qiblaAngle,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: AppColorsLight.accent, size: 36.r),
                    SizedBox(height: 4.h),
                    Container(
                      width: 4.w,
                      height: 110.r,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColorsLight.accent, Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ],
                ),
              ),
              // Centerpoint.
              Container(
                width: 12.r,
                height: 12.r,
                decoration: const BoxDecoration(
                  color: AppColorsLight.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColorsLight.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            'qibla_bearing_label'.tr().replaceFirst(
                  '{{deg}}',
                  _qiblaBearing!.toStringAsFixed(1),
                ),
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColorsLight.primaryDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompassRose extends StatelessWidget {
  const _CompassRose();

  @override
  Widget build(BuildContext context) {
    Widget label(String text, Alignment align, Color color) => Align(
          alignment: align,
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Text(text,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                )),
          ),
        );
    return Stack(children: [
      label('N', Alignment.topCenter, AppColorsLight.error),
      label('E', Alignment.centerRight, context.brand.muted),
      label('S', Alignment.bottomCenter, context.brand.muted),
      label('W', Alignment.centerLeft, context.brand.muted),
    ]);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64.r, color: context.brand.muted),
        SizedBox(height: 12.h),
        Text(title,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 6.h),
        Text(body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: context.brand.muted)),
        if (onRetry != null) ...[
          SizedBox(height: 16.h),
          FilledButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: Text('common_retry'.tr()),
            onPressed: onRetry,
          ),
        ],
      ],
    );
  }
}
