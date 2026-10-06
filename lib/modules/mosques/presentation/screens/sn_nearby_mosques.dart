import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/utils/helper/app_alert.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/mosques/domain/entities/e_mosque.dart';
import 'package:quran/modules/mosques/presentation/cubits/cb_nearby_mosques.dart';
import 'package:quran/modules/mosques/presentation/cubits/s_nearby_mosques.dart';
import 'package:quran/modules/mosques/presentation/widgets/w_maps_app_sheet.dart';
import 'package:quran/modules/mosques/presentation/widgets/w_mosques_failure.dart';
import 'package:quran/modules/mosques/presentation/widgets/w_mosques_hero.dart';
import 'package:quran/modules/mosques/presentation/widgets/w_mosques_list.dart';
import 'package:quran/modules/mosques/presentation/widgets/w_mosques_map.dart';
import 'package:quran/modules/mosques/presentation/widgets/w_mosques_message.dart';
import 'package:quran/modules/mosques/services/maps_launcher.dart';
import 'package:quran/modules/prayer/domain/entities/e_location_failure.dart';

/// The mosques nearest to the reader on a map and in a list, each with a
/// hand-off to a map app for directions. A pin and its card select together.
class SNNearbyMosques extends StatefulWidget {
  const SNNearbyMosques({super.key});

  @override
  State<SNNearbyMosques> createState() => _SNNearbyMosquesState();
}

class _SNNearbyMosquesState extends State<SNNearbyMosques>
    with WidgetsBindingObserver {
  late final CBNearbyMosques _cubit = Modular.get<CBNearbyMosques>();

  /// Set when a location failure sent the reader to a settings page, so the
  /// list reloads on their way back. Only then: reloading on every resume
  /// would re-trigger the permission dialog the reader just answered.
  bool _sentToSettings = false;

  /// One per card, so a tapped pin can scroll its card into view.
  final Map<String, GlobalKey> _cardKeys = {};

  GlobalKey _cardKey(String mosqueId) =>
      _cardKeys.putIfAbsent(mosqueId, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit
      ..load()
      ..checkMaps();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed && _sentToSettings) {
      _sentToSettings = false;
      _cubit.load();
    }
  }

  void _recover() {
    if (_cubit.state.locationFailure?.needsSystemSettings ?? false) {
      _sentToSettings = true;
    }
    _cubit.recover();
  }

  /// A pin was tapped: light up its card and bring it into view.
  void _onPinTap(EMosque mosque) {
    _cubit.selectMosque(mosque.id);
    final card = _cardKeys[mosque.id]?.currentContext;
    if (card == null) return;
    Scrollable.ensureVisible(
      card,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  Future<void> _directions(EMosque mosque) async {
    final app = await WMapsAppSheet.pick(context);
    if (app == null) return;
    await _open(MapsLauncher.directionsTo(app, mosque));
  }

  Future<void> _viewOnMap() async {
    final lat = _cubit.state.latitude;
    final lng = _cubit.state.longitude;
    if (lat == null || lng == null) return;
    final app = await WMapsAppSheet.pick(context);
    if (app == null) return;
    await _open(MapsLauncher.mosquesAround(app, lat, lng));
  }

  Future<void> _open(Uri uri) async {
    final opened = await MapsLauncher.open(uri);
    if (!opened) AppAlert.error('mosques_open_failed'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return WSharedScaffold(
      backgroundColor: brand.background,
      withSafeArea: false,
      padding: EdgeInsets.zero,
      body: BlocProvider.value(
        value: _cubit,
        // The map stays put above the list, so a card tapped anywhere down
        // the list still has its pin in view.
        child: Column(
          children: [
            _Hero(
              onViewOnMap: _viewOnMap,
              map: (hidden) => _Map(
                hidden: hidden,
                onPinTap: _onPinTap,
                onDirections: _directions,
                onClearSelection: () => _cubit.selectMosque(null),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: brand.primary,
                onRefresh: _cubit.load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _Body(
                      cardKey: _cardKey,
                      onSelect: _cubit.selectMosque,
                      onDirections: _directions,
                      onRecover: _recover,
                      onRetry: _cubit.load,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onViewOnMap, required this.map});

  final VoidCallback onViewOnMap;
  final Widget Function(EdgeInsets hidden) map;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CBNearbyMosques, SNearbyMosques,
        (String, bool, bool, bool)>(
      selector: (s) => (
        s.locationLabel,
        s.hasLocation,
        s.status == NearbyMosquesStatus.loading,
        s.mapsReady,
      ),
      builder: (_, selected) {
        final (label, hasLocation, loading, mapsReady) = selected;
        final subtitle = label.isNotEmpty
            ? 'mosques_current_location'.tr().replaceFirst('{{city}}', label)
            : (loading
                ? 'mosques_locating'.tr()
                : 'mosques_current_location_unknown'.tr());
        return WMosquesHero(
          subtitle: subtitle,
          onViewOnMap: hasLocation ? onViewOnMap : null,
          // Without a key the Maps SDK can't start a map — it crashes the app
          // instead — so the photo stays until the SDK is ready.
          mapBuilder: hasLocation && mapsReady ? map : null,
        );
      },
    );
  }
}

/// The map, fed from the cubit. Rebuilds for the fix, the list and the pick.
class _Map extends StatelessWidget {
  const _Map({
    required this.hidden,
    required this.onPinTap,
    required this.onDirections,
    required this.onClearSelection,
  });

  final EdgeInsets hidden;
  final ValueChanged<EMosque> onPinTap;
  final ValueChanged<EMosque> onDirections;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CBNearbyMosques, SNearbyMosques,
        (double?, double?, List<EMosque>, String?)>(
      selector: (s) => (s.latitude, s.longitude, s.mosques, s.selectedMosqueId),
      builder: (context, selected) {
        final (lat, lng, mosques, selectedId) = selected;
        if (lat == null || lng == null) return const SizedBox.shrink();
        return WMosquesMap(
          latitude: lat,
          longitude: lng,
          mosques: mosques,
          selectedId: selectedId,
          padding: hidden,
          onMosqueTap: onPinTap,
          onDirections: onDirections,
          onClearSelection: onClearSelection,
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.cardKey,
    required this.onSelect,
    required this.onDirections,
    required this.onRecover,
    required this.onRetry,
  });

  final GlobalKey Function(String mosqueId) cardKey;
  final ValueChanged<String> onSelect;
  final void Function(EMosque mosque) onDirections;
  final VoidCallback onRecover;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBNearbyMosques, SNearbyMosques>(
      // The header owns the location line; this rebuilds for the list only.
      buildWhen: (a, b) =>
          a.status != b.status ||
          a.mosques != b.mosques ||
          a.selectedMosqueId != b.selectedMosqueId ||
          a.locationFailure != b.locationFailure ||
          a.errorKey != b.errorKey,
      builder: (context, state) {
        switch (state.status) {
          case NearbyMosquesStatus.loading:
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: context.brand.primary),
              ),
            );
          case NearbyMosquesStatus.failure:
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: WMosquesFailure(
                  state: state,
                  onRecover: onRecover,
                  onRetry: onRetry,
                ),
              ),
            );
          case NearbyMosquesStatus.success:
            if (state.mosques.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: WMosquesMessage(
                    icon: Icons.mosque_outlined,
                    title: 'mosques_empty_title'.tr(),
                    body: 'mosques_empty_body'.tr(),
                    actionLabel: 'common_retry'.tr(),
                    onAction: onRetry,
                  ),
                ),
              );
            }
            return WMosquesList(
              mosques: state.mosques,
              selectedId: state.selectedMosqueId,
              cardKey: cardKey,
              onSelect: onSelect,
              onDirections: onDirections,
            );
        }
      },
    );
  }
}
