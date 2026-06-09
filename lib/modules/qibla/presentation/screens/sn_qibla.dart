import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_cache.dart';

class SNQibla extends StatefulWidget {
  const SNQibla({super.key});

  @override
  State<SNQibla> createState() => _SNQiblaState();
}

class _SNQiblaState extends State<SNQibla> {
  // Brand palette for this screen.
  static const _green = Color(0xFF0E6B47);
  static const _greenLight = Color(0xFF3A8366);
  static const _gold = Color(0xFFC9A227);
  static const _canvas = Color(0xFFF4F2EC);

  // Kaaba coordinates (decimal degrees).
  static const _kaabaLat = 21.4225;
  static const _kaabaLng = 39.8262;

  double? _qiblaBearing;
  double? _distanceKm;
  String? _city;
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
      _city = cache.cityName;
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
    setState(() {
      _error = null;
      _qiblaBearing = _bearingTo(lat!, lng!, _kaabaLat, _kaabaLng);
      _distanceKm = _haversineKm(lat, lng, _kaabaLat, _kaabaLng);
    });
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

  /// Great-circle distance between two coordinates in kilometres.
  static double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dPhi = (lat2 - lat1) * math.pi / 180.0;
    final dLambda = (lng2 - lng1) * math.pi / 180.0;
    final phi1 = lat1 * math.pi / 180.0;
    final phi2 = lat2 * math.pi / 180.0;
    final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) * math.cos(phi2) * math.sin(dLambda / 2) * math.sin(dLambda / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: Column(
        children: [
          _QiblaHeader(city: _city, green: _green, greenLight: _greenLight),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20.w, 26.h, 20.w, 26.h),
              child: _build(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build(BuildContext context) {
    if (!_hasMagnetometer) {
      return Padding(
        padding: EdgeInsets.only(top: 60.h),
        child: _ErrorState(
          icon: Icons.compass_calibration_rounded,
          title: 'qibla_no_compass_title'.tr(),
          body: 'qibla_no_compass_body'.tr(),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: EdgeInsets.only(top: 60.h),
        child: _ErrorState(
          icon: Icons.location_off_rounded,
          title: 'qibla_no_location_title'.tr(),
          body: _error ?? '',
          onRetry: _loadLocation,
        ),
      );
    }
    if (_qiblaBearing == null) {
      return Padding(
        padding: EdgeInsets.only(top: 80.h),
        child: const Center(child: CircularProgressIndicator(color: _green)),
      );
    }

    final bearing = _qiblaBearing ?? 0;
    // Pointer angle relative to the device's current facing direction.
    final qiblaAngle = (bearing - _heading) * math.pi / 180.0;
    return Column(
      children: [
        _CompassDial(
          heading: _heading,
          qiblaAngle: qiblaAngle,
          green: _green,
          gold: _gold,
        ),
        SizedBox(height: 26.h),
        _InfoCard(
          bearing: bearing,
          distanceKm: _distanceKm ?? 0,
          green: _green,
          gold: _gold,
        ),
        SizedBox(height: 14.h),
        _StatusPill(
          text: 'qibla_success'.tr(),
          background: const Color(0xFFE2EFE8),
          foreground: const Color(0xFF0A5639),
          dotColor: _green,
          showCheck: true,
        ),
        SizedBox(height: 10.h),
        _StatusPill(
          text: 'qibla_tip'.tr(),
          background: const Color(0xFFF3EEDE),
          foreground: const Color(0xFF8A7A45),
          leadingEmoji: '💡',
        ),
      ],
    );
  }
}

// ============================ Header ============================

class _QiblaHeader extends StatelessWidget {
  const _QiblaHeader({
    required this.city,
    required this.green,
    required this.greenLight,
  });

  final String? city;
  final Color green;
  final Color greenLight;

  @override
  Widget build(BuildContext context) {
    final subtitle = (city != null && city!.isNotEmpty)
        ? city!
        : 'qibla_title'.tr();
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 6.h, 18.w, 22.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [greenLight, green],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: Modular.to.pop,
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'home_qibla'.tr(),
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================ Compass dial ============================

class _CompassDial extends StatelessWidget {
  const _CompassDial({
    required this.heading,
    required this.qiblaAngle,
    required this.green,
    required this.gold,
  });

  final double heading;
  final double qiblaAngle;
  final Color green;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final size = 300.r;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer neumorphic plate.
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFBFAF6), Color(0xFFE8E5DC)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
                BoxShadow(
                  color: Color(0xCCFFFFFF),
                  blurRadius: 18,
                  offset: Offset(-8, -8),
                ),
              ],
            ),
          ),
          // Rotating rose: cardinals, ticks and intermediate dots.
          Transform.rotate(
            angle: -heading * math.pi / 180.0,
            child: SizedBox(
              width: size,
              height: size,
              child: const _CompassRose(),
            ),
          ),
          // Qibla pointer — orbits to point toward Mecca.
          Transform.rotate(
            angle: qiblaAngle,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 20.h),
                child: Icon(Icons.navigation_rounded, color: gold, size: 24.r),
              ),
            ),
          ),
          // Static Kaaba center.
          _KaabaCore(green: green, gold: gold),
        ],
      ),
    );
  }
}

class _CompassRose extends StatelessWidget {
  const _CompassRose();

  static const _tickColor = Color(0xFFB8B4A8);
  static const _dotColor = Color(0xFFC9C5B8);
  static const _labelColor = Color(0xFF7B7768);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Intermediate dots (NE, SE, SW, NW).
        const _Dot(alignment: Alignment(0.62, -0.62)),
        const _Dot(alignment: Alignment(0.62, 0.62)),
        const _Dot(alignment: Alignment(-0.62, 0.62)),
        const _Dot(alignment: Alignment(-0.62, -0.62)),
        // Cardinals: label + tick.
        _cardinal(
          align: Alignment.topCenter,
          label: 'qibla_north'.tr(),
          axis: Axis.vertical,
          labelFirst: true,
        ),
        _cardinal(
          align: Alignment.bottomCenter,
          label: 'qibla_south'.tr(),
          axis: Axis.vertical,
          labelFirst: false,
        ),
        _cardinal(
          align: Alignment.centerRight,
          label: 'qibla_east'.tr(),
          axis: Axis.horizontal,
          labelFirst: true,
        ),
        _cardinal(
          align: Alignment.centerLeft,
          label: 'qibla_west'.tr(),
          axis: Axis.horizontal,
          labelFirst: false,
        ),
      ],
    );
  }

  Widget _cardinal({
    required Alignment align,
    required String label,
    required Axis axis,
    required bool labelFirst,
  }) {
    final tick = Container(
      width: axis == Axis.vertical ? 3.w : 16.w,
      height: axis == Axis.vertical ? 16.h : 3.w,
      decoration: BoxDecoration(
        color: _tickColor,
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
    final text = Text(
      label,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: _labelColor,
      ),
    );
    final gap = SizedBox(width: 8.w, height: 8.h);
    final children = labelFirst ? [text, gap, tick] : [tick, gap, text];
    return Align(
      alignment: align,
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: axis == Axis.vertical
            ? Column(mainAxisSize: MainAxisSize.min, children: children)
            : Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 9.r,
        height: 9.r,
        decoration: const BoxDecoration(
          color: _CompassRose._dotColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _KaabaCore extends StatelessWidget {
  const _KaabaCore({required this.green, required this.gold});

  final Color green;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116.r,
      height: 116.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white, width: 6),
        boxShadow: [
          BoxShadow(
            color: green.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.hexagon, color: gold, size: 52.r),
          Icon(Icons.hexagon_outlined, color: green, size: 26.r),
        ],
      ),
    );
  }
}

// ============================ Info card ============================

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.bearing,
    required this.distanceKm,
    required this.green,
    required this.gold,
  });

  final double bearing;
  final double distanceKm;
  final Color green;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bearing degree + cardinal name.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_localizeDigits(bearing.round().toString())}°',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  color: gold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                _cardinalName(bearing),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.brand.muted,
                ),
              ),
            ],
          ),
          // Direction button.
          Container(
            width: 46.r,
            height: 46.r,
            decoration: BoxDecoration(
              color: green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: green.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.navigation_rounded, color: Colors.white),
          ),
          // Distance to Mecca.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'qibla_distance_label'.tr(),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.brand.muted,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                '${_formatDistance(distanceKm)} ${'qibla_km'.tr()}',
                style: TextStyle(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _cardinalName(double bearing) {
    const keys = [
      'qibla_dir_n',
      'qibla_dir_ne',
      'qibla_dir_e',
      'qibla_dir_se',
      'qibla_dir_s',
      'qibla_dir_sw',
      'qibla_dir_w',
      'qibla_dir_nw',
    ];
    final index = (((bearing % 360) + 22.5) ~/ 45) % 8;
    return keys[index].tr();
  }

  String _formatDistance(double km) {
    final withSep = km.round().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
        );
    return _localizeDigits(withSep);
  }
}

// ============================ Status pills ============================

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.text,
    required this.background,
    required this.foreground,
    this.dotColor,
    this.showCheck = false,
    this.leadingEmoji,
  });

  final String text;
  final Color background;
  final Color foreground;
  final Color? dotColor;
  final bool showCheck;
  final String? leadingEmoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingEmoji != null) ...[
                Text(leadingEmoji ?? '', style: TextStyle(fontSize: 13.sp)),
                SizedBox(width: 6.w),
              ],
              Flexible(
                child: Text(
                  showCheck ? '$text ✓' : text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
          if (dotColor != null)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 8.r,
                height: 8.r,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================ Error state ============================

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

/// Converts Western digits (and the `,` thousands separator) to Arabic-Indic
/// glyphs when the active locale is Arabic; returns the input untouched
/// otherwise.
String _localizeDigits(String input) {
  if (LocalizeAndTranslate.getLanguageCode() != 'ar') return input;
  const western = '0123456789,';
  const arabic = '٠١٢٣٤٥٦٧٨٩٬';
  final buffer = StringBuffer();
  for (final ch in input.split('')) {
    final index = western.indexOf(ch);
    buffer.write(index == -1 ? ch : arabic[index]);
  }
  return buffer.toString();
}
