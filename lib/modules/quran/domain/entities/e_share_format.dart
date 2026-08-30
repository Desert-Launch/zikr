/// The three shapes a shared ayah can take.
enum EShareFormat {
  /// A rendered card: the verses set under an illuminated surah banner, with
  /// any attached commentary beneath them. What most people forward.
  image,

  /// The verse text as the Mushaf writes it — harakat, hamzat wasl and all.
  text,

  /// The same text with the diacritics taken off. Some keyboards, chat clients
  /// and screen readers make a mess of fully vocalised Uthmani; this is the
  /// version that survives them.
  plainText,
}
