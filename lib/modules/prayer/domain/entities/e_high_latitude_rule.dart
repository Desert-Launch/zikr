/// How Fajr and Isha are resolved where the sun never drops far enough below
/// the horizon for the method's angle to occur — Norway, Sweden, Finland,
/// Iceland, northern Canada, and anywhere else in high summer or deep winter.
///
/// The accepted values were read off live `/v1/timings` responses
/// (`meta.latitudeAdjustmentMethod`) rather than assumed, and omitting the
/// parameter leaves Aladhan on its own default. The numbers themselves live in
/// `AladhanQueryBuilder`, not here — this enum is the app's vocabulary, not the
/// API's.
enum EHighLatitudeRule {
  /// Send nothing and take Aladhan's own default. The right choice almost
  /// everywhere, and the reason this is not a required setting.
  automatic,

  /// The night is split in half; Fajr and Isha sit at the midpoint.
  middleOfTheNight,

  /// The night is split in sevenths — one seventh after sunset for Isha, one
  /// before sunrise for Fajr.
  oneSeventh,

  /// The night is divided in proportion to the method's own Fajr/Isha angles.
  angleBased,
}
