import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/mosques/domain/entities/e_mosque.dart';
import 'package:quran/modules/mosques/presentation/widgets/w_mosque_card.dart';

/// The reader's surroundings on a Google map: a pin per nearby mosque, the
/// blue my-location dot, and a button that brings both back into view.
///
/// Selection lives in the screen's cubit. [selectedId]'s pin turns gold, and
/// whenever it changes the camera glides to that mosque and opens its label.
class WMosquesMap extends StatefulWidget {
  const WMosquesMap({
    required this.latitude,
    required this.longitude,
    required this.mosques,
    required this.selectedId,
    required this.onMosqueTap,
    required this.onDirections,
    required this.onClearSelection,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// The fix the list was built from, where the camera starts.
  final double latitude;
  final double longitude;

  /// Nearest first.
  final List<EMosque> mosques;
  final String? selectedId;
  final ValueChanged<EMosque> onMosqueTap;

  /// A tap on a pin's label, which offers directions like the card's button.
  final ValueChanged<EMosque> onDirections;

  /// A tap on the map away from any pin.
  final VoidCallback onClearSelection;

  /// The part of the map covered by other widgets. Keeps the camera framing
  /// and the overlay button inside the visible part.
  final EdgeInsets padding;

  @override
  State<WMosquesMap> createState() => _WMosquesMapState();
}

class _WMosquesMapState extends State<WMosquesMap> {
  /// How many of the nearest mosques the camera frames along with the reader.
  /// The list reaches 50 km out; framing all of it would zoom out past the
  /// streets that make the map worth having.
  static const _framed = 5;

  GoogleMapController? _controller;
  ({BitmapDescriptor normal, BitmapDescriptor selected})? _pins;

  /// What [_pins] were drawn for, so a theme or density change redraws them.
  (Color, double)? _pinsFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final key = (context.brand.primary, MediaQuery.devicePixelRatioOf(context));
    if (key == _pinsFor) return;
    _pinsFor = key;
    _loadPins(key.$1, key.$2);
  }

  @override
  void didUpdateWidget(covariant WMosquesMap old) {
    super.didUpdateWidget(old);
    if (old.mosques != widget.mosques ||
        old.latitude != widget.latitude ||
        old.longitude != widget.longitude) {
      _frame();
    }
    final id = widget.selectedId;
    if (id != null && id != old.selectedId) _focus(id);
  }

  Future<void> _loadPins(Color color, double pixelRatio) async {
    final pins = (
      normal: await _pinBitmap(color, pixelRatio),
      selected: await _pinBitmap(AppColors.accentGoldAmber, pixelRatio),
    );
    if (mounted) setState(() => _pins = pins);
  }

  /// Fits the reader and the nearest mosques on screen.
  Future<void> _frame() async {
    final controller = _controller;
    if (controller == null) return;
    final me = LatLng(widget.latitude, widget.longitude);
    final points = [
      me,
      for (final m in widget.mosques.take(_framed)) LatLng(m.latitude, m.longitude),
    ];
    if (points.length == 1) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(me, 15));
      return;
    }
    var south = me.latitude, north = me.latitude;
    var west = me.longitude, east = me.longitude;
    for (final p in points) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
    } on PlatformException {
      // Android rejects bounds while the map view has no size yet.
      await controller.animateCamera(CameraUpdate.newLatLngZoom(me, 14));
    }
  }

  Future<void> _focus(String id) async {
    final controller = _controller;
    final mosque = widget.mosques.where((m) => m.id == id).firstOrNull;
    if (controller == null || mosque == null) return;
    await controller.animateCamera(
      CameraUpdate.newLatLng(LatLng(mosque.latitude, mosque.longitude)),
    );
    if (mounted) await controller.showMarkerInfoWindow(_markerId(mosque));
  }

  Set<Marker> _markers() {
    final pins = _pins;
    if (pins == null) return const {};
    return {
      for (final mosque in widget.mosques)
        Marker(
          markerId: _markerId(mosque),
          position: LatLng(mosque.latitude, mosque.longitude),
          icon: mosque.id == widget.selectedId ? pins.selected : pins.normal,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: mosque.id == widget.selectedId ? 1 : 0,
          infoWindow: InfoWindow(
            title: mosque.name,
            snippet: '${WMosqueCard.distanceLabel(mosque.distanceMeters)}'
                ' · ${'mosques_directions'.tr()}',
            onTap: () => widget.onDirections(mosque),
          ),
          onTap: () => widget.onMosqueTap(mosque),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.latitude, widget.longitude),
            zoom: 14,
          ),
          // Pinned LTR so Google's logo and attribution keep their standard
          // bottom-left spot; the overlay buttons all sit at the top.
          layoutDirection: TextDirection.ltr,
          padding: widget.padding,
          markers: _markers(),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          onMapCreated: (controller) {
            _controller = controller;
            _frame();
          },
          onTap: (_) => widget.onClearSelection(),
        ),
        PositionedDirectional(
          top: widget.padding.top + 10.h,
          end: 12.w,
          child: _RecenterButton(onTap: _frame),
        ),
      ],
    );
  }
}

/// Places normally return an id; the coordinates keep two id-less pins apart.
MarkerId _markerId(EMosque mosque) => MarkerId(
      mosque.id.isNotEmpty ? mosque.id : '${mosque.latitude},${mosque.longitude}',
    );

/// A rounded square in [fill] with a white ring and a white mosque glyph, drawn
/// at the device's pixel ratio so it stays sharp.
Future<BitmapDescriptor> _pinBitmap(Color fill, double pixelRatio) async {
  const logicalSize = 30.0;
  final size = logicalSize * pixelRatio;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final box = RRect.fromRectAndRadius(
    Offset.zero & Size.square(size),
    Radius.circular(size * 0.3),
  );
  canvas.drawRRect(box, Paint()..color = Colors.white);
  canvas.drawRRect(box.deflate(2 * pixelRatio), Paint()..color = fill);
  final glyph = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(Icons.mosque.codePoint),
      style: TextStyle(
        fontFamily: Icons.mosque.fontFamily,
        package: Icons.mosque.fontPackage,
        fontSize: size * 0.6,
        color: Colors.white,
      ),
    ),
  )..layout();
  glyph.paint(canvas, Offset((size - glyph.width) / 2, (size - glyph.height) / 2));
  glyph.dispose();
  final image = await recorder.endRecording().toImage(size.ceil(), size.ceil());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (png == null) return BitmapDescriptor.defaultMarker;
  return BitmapDescriptor.bytes(png.buffer.asUint8List(), imagePixelRatio: pixelRatio);
}

class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: IconButton(
        onPressed: onTap,
        tooltip: 'mosques_recenter'.tr(),
        icon: Icon(Icons.my_location_rounded, size: 20.r, color: context.brand.primary),
      ),
    );
  }
}
