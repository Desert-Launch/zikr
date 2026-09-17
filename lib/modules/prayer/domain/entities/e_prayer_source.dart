/// Where the prayer times on screen came from.
///
/// Exposed to the presentation layer so a day served from a cache that could
/// not be refreshed can say so, quietly, instead of pretending it is live —
/// and so nothing ever fabricates times to fill an empty screen.
enum EPrayerSource {
  /// Fetched from Aladhan just now.
  network,

  /// Read from a cached month that is still valid for this location and these
  /// settings. The normal path — most opens should land here.
  cache,

  /// A cached month kept past its refresh point, or fetched at a location the
  /// user has since left, served because the network could not be reached.
  /// The UI should mark this.
  staleCache,

  /// Computed on-device from coordinates, because the network and every cache
  /// missed. Approximate but always available — without it a cold, offline
  /// install would schedule no adhan at all.
  calculated,
}

extension EPrayerSourceX on EPrayerSource {
  /// Whether the data is known to be behind — the flag the UI shows an
  /// offline/stale hint for.
  bool get isStale =>
      this == EPrayerSource.staleCache || this == EPrayerSource.calculated;
}
