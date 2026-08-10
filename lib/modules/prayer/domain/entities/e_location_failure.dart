/// Why a location fix could not be obtained.
///
/// Carried from `DSLocation` up to the prayer UI, which needs two things a
/// free-text message cannot give it: an explanation it can translate, and the
/// recovery that will actually work. Re-asking for the permission only helps
/// while the OS is still willing to show its dialog — in the other two cases a
/// retry is silently refused, and the user has to be taken to a settings page
/// instead.
enum ELocationFailure {
  /// Device location is switched off. No permission dialog can appear until it
  /// is back on, so the only way forward is the system location settings.
  serviceDisabled,

  /// Declined this time. Asking again still shows the OS dialog, so a plain
  /// retry is enough.
  denied,

  /// Declined permanently ("don't ask again"). Every further request is refused
  /// without a dialog, so the permission has to be granted from the app's own
  /// settings page.
  deniedForever,
}

extension ELocationFailureX on ELocationFailure {
  /// Flat i18n key explaining the failure to the reader.
  String get messageKey => switch (this) {
    ELocationFailure.serviceDisabled => 'prayer_location_service_off',
    ELocationFailure.denied => 'prayer_location_denied',
    ELocationFailure.deniedForever => 'prayer_location_denied_forever',
  };

  /// Whether recovering needs a trip to a system settings page, rather than
  /// just asking for the permission again.
  bool get needsSystemSettings => this != ELocationFailure.denied;
}
