import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_cache.dart';
import 'package:quran/modules/qibla/presentation/widgets/w_compass_dial.dart';
import 'package:quran/modules/qibla/presentation/widgets/w_qibla_error_state.dart';
import 'package:quran/modules/qibla/presentation/widgets/w_qibla_info_card.dart';
import 'package:quran/modules/qibla/presentation/widgets/w_qibla_status_pill.dart';

class SNQibla extends StatefulWidget {
  const SNQibla({super.key});

  @override
  State<SNQibla> createState() => _SNQiblaState();
}

class _SNQiblaState extends State<SNQibla> {
  // Brand palette for this screen.
  static const _green = Color(0xFF0E6B47);
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
    final x =
        math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
    final theta = math.atan2(y, x);
    return (theta * 180.0 / math.pi + 360.0) % 360.0;
  }

  /// Great-circle distance between two coordinates in kilometres.
  static double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0;
    final dPhi = (lat2 - lat1) * math.pi / 180.0;
    final dLambda = (lng2 - lng1) * math.pi / 180.0;
    final phi1 = lat1 * math.pi / 180.0;
    final phi2 = lat2 * math.pi / 180.0;
    final a =
        math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(dLambda / 2) *
            math.sin(dLambda / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  @override
  Widget build(BuildContext context) {
    return WSharedScaffold(
      backgroundColor: _canvas,
      withSafeArea: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          WGradientAppBar(subtitle: _city ?? '', title: 'home_qibla'.tr()),
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
        child: WQiblaErrorState(
          icon: Icons.compass_calibration_rounded,
          title: 'qibla_no_compass_title'.tr(),
          body: 'qibla_no_compass_body'.tr(),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: EdgeInsets.only(top: 60.h),
        child: WQiblaErrorState(
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
        WCompassDial(
          heading: _heading,
          qiblaAngle: qiblaAngle,
          green: _green,
          gold: _gold,
        ),
        SizedBox(height: 26.h),
        WQiblaInfoCard(
          bearing: bearing,
          distanceKm: _distanceKm ?? 0,
          green: _green,
          gold: _gold,
        ),
        SizedBox(height: 14.h),
        WQiblaStatusPill(
          text: 'qibla_success'.tr(),
          background: const Color(0xFFE2EFE8),
          foreground: const Color(0xFF0A5639),
          dotColor: _green,
          showCheck: true,
        ),
        SizedBox(height: 10.h),
        WQiblaStatusPill(
          text: 'qibla_tip'.tr(),
          background: const Color(0xFFF3EEDE),
          foreground: const Color(0xFF8A7A45),
          leadingEmoji: '💡',
        ),
      ],
    );
  }
}
