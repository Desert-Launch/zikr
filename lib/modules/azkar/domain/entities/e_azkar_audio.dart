/// Shape of a recording relative to the app's adhkar.
enum EAzkarAudioType {
  /// One file = one dhikr. Renders as a play button on that dhikr.
  singleAdhkar,

  /// One file = a whole sitting (morning adhkar end-to-end, say). Renders at
  /// category level only — attaching it to a single dhikr would be a lie.
  categoryRecording;

  static EAzkarAudioType fromJson(String? raw) =>
      raw == 'category_recording'
      ? EAzkarAudioType.categoryRecording
      : EAzkarAudioType.singleAdhkar;

  String get asJson => this == EAzkarAudioType.categoryRecording
      ? 'category_recording'
      : 'single_adhkar';

  bool get isCategory => this == EAzkarAudioType.categoryRecording;
}

/// How confident the build-time matcher is that this file really is the audio
/// of the dhikr it is attached to.
///
/// Only [exact] and [manual] are produced without human review; [high] comes
/// from fuzzy matching that cleared the confidence *and* the time-of-day guard.
/// [unknown] never ships — the validator rejects it.
enum EAzkarAudioMatch {
  /// Normalised Arabic text is identical on both sides.
  exact,

  /// Fuzzy match above threshold, unique winner, no time-of-day conflict.
  high,

  /// Hand-verified entry from the reader's `manual` overrides.
  manual,

  /// Provenance not established. Treated as unusable.
  unknown;

  static EAzkarAudioMatch fromJson(String? raw) => switch (raw) {
    'exact' => EAzkarAudioMatch.exact,
    'high' => EAzkarAudioMatch.high,
    'manual' => EAzkarAudioMatch.manual,
    _ => EAzkarAudioMatch.unknown,
  };

  String get asJson => name;

  /// Whether an entry with this confidence may be shown to a user.
  bool get isPlayable => this != EAzkarAudioMatch.unknown;
}

/// Redistribution status of a source, tracked per reader.
///
/// Nothing but [open] may ever be bundled into the app package; everything else
/// is fetched from its origin at the user's request, with attribution kept.
enum EAzkarLicenseStatus {
  /// Explicit licence allowing redistribution (public domain, CC-BY, …).
  open,

  /// Publicly and freely served, no licence statement found.
  unknown,

  /// Known to forbid redistribution.
  restricted;

  static EAzkarLicenseStatus fromJson(String? raw) => switch (raw) {
    'open' => EAzkarLicenseStatus.open,
    'restricted' => EAzkarLicenseStatus.restricted,
    _ => EAzkarLicenseStatus.unknown,
  };

  String get asJson => name;

  /// Only an [open] source may be shipped inside the app package.
  bool get canBundle => this == EAzkarLicenseStatus.open;
}

/// Lifecycle of one audio file on this device.
enum EAzkarAudioStatus {
  /// Known and reachable, not on disk. Plays by streaming.
  available,

  /// Complete file on disk. Plays offline.
  downloaded,

  /// Transfer in flight.
  downloading,

  /// Last transfer failed; retryable.
  failed,

  /// Source is gone (404/dead). Hidden from the reader's counts.
  unavailable;

  bool get isOnDisk => this == EAzkarAudioStatus.downloaded;
}
