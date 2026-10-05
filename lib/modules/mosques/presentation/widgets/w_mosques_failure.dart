import 'package:flutter/material.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/mosques/presentation/cubits/s_nearby_mosques.dart';
import 'package:quran/modules/mosques/presentation/widgets/w_mosques_message.dart';
import 'package:quran/modules/prayer/domain/entities/e_location_failure.dart';

/// Explains why the list is missing and offers the one action that can fix it.
class WMosquesFailure extends StatelessWidget {
  const WMosquesFailure({
    required this.state,
    required this.onRecover,
    required this.onRetry,
    super.key,
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
