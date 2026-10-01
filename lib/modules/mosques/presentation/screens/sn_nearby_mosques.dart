import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/utils/helper/app_alert.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/mosques/domain/entities/e_mosque.dart';
import 'package:quran/modules/mosques/presentation/cubits/cb_nearby_mosques.dart';
import 'package:quran/modules/mosques/presentation/cubits/s_nearby_mosques.dart';
import 'package:quran/modules/mosques/presentation/widgets/w_maps_app_sheet.dart';
import 'package:quran/modules/mosques/presentation/widgets/w_mosque_card.dart';
import 'package:quran/modules/mosques/presentation/widgets/w_mosques_hero.dart';
import 'package:quran/modules/mosques/presentation/widgets/w_mosques_message.dart';
import 'package:quran/modules/mosques/services/maps_launcher.dart';
import 'package:quran/modules/prayer/domain/entities/e_location_failure.dart';

/// The mosques nearest to the reader, each with a hand-off to a map app for
/// directions.
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit.load();
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
        child: RefreshIndicator(
          color: brand.primary,
          onRefresh: _cubit.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _Hero(onViewOnMap: _viewOnMap)),
              _Body(
                onDirections: _directions,
                onRecover: _recover,
                onRetry: _cubit.load,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onViewOnMap});

  final VoidCallback onViewOnMap;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CBNearbyMosques, SNearbyMosques, (String, bool, bool)>(
      selector: (s) => (
        s.locationLabel,
        s.hasLocation,
        s.status == NearbyMosquesStatus.loading,
      ),
      builder: (_, selected) {
        final (label, hasLocation, loading) = selected;
        final subtitle = label.isNotEmpty
            ? 'mosques_current_location'.tr().replaceFirst('{{city}}', label)
            : (loading
                ? 'mosques_locating'.tr()
                : 'mosques_current_location_unknown'.tr());
        return WMosquesHero(
          subtitle: subtitle,
          onViewOnMap: hasLocation ? onViewOnMap : null,
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.onDirections,
    required this.onRecover,
    required this.onRetry,
  });

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
                child: _Failure(
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
            final bottomInset = MediaQuery.paddingOf(context).bottom;
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h + bottomInset),
              sliver: SliverList.separated(
                itemCount: state.mosques.length,
                separatorBuilder: (_, _) => SizedBox(height: 12.h),
                itemBuilder: (_, index) {
                  final mosque = state.mosques[index];
                  return WMosqueCard(
                    rank: index + 1,
                    mosque: mosque,
                    onDirections: () => onDirections(mosque),
                  );
                },
              ),
            );
        }
      },
    );
  }
}

/// Explains why the list is missing and offers the one action that can fix it.
class _Failure extends StatelessWidget {
  const _Failure({
    required this.state,
    required this.onRecover,
    required this.onRetry,
  });

  final SNearbyMosques state;
  final VoidCallback onRecover;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final locationFailure = state.locationFailure;
    if (locationFailure != null) {
      return WMosquesMessage(
        icon: Icons.location_off_outlined,
        title: 'mosques_location_title'.tr(),
        body: switch (locationFailure) {
          ELocationFailure.serviceDisabled => 'mosques_location_service_off',
          ELocationFailure.denied => 'mosques_location_denied',
          ELocationFailure.deniedForever => 'mosques_location_denied_forever',
        }
            .tr(),
        actionLabel: locationFailure.needsSystemSettings
            ? 'mosques_open_settings'.tr()
            : 'mosques_allow_location'.tr(),
        onAction: onRecover,
      );
    }

    final key = state.errorKey ?? 'mosques_error_generic';
    return WMosquesMessage(
      icon: switch (key) {
        'mosques_error_network' => Icons.wifi_off_rounded,
        'mosques_no_location' => Icons.location_searching_rounded,
        _ => Icons.error_outline_rounded,
      },
      title: key == 'mosques_no_location'
          ? 'mosques_location_title'.tr()
          : 'mosques_error_title'.tr(),
      body: key.tr(),
      actionLabel: 'common_retry'.tr(),
      onAction: onRetry,
    );
  }
}
