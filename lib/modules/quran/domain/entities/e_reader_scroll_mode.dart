/// How the Mushaf reader moves between pages. Declaration order IS the order
/// shown in the settings picker.
///
/// - [horizontal] one page per screen, swiped sideways and snapped into place —
///   the printed-book feel, and the long-standing default.
/// - [vertical] the Mushaf as one continuous column: pages flow into each other
///   with no snap, so a verse split across a page break can be read without
///   turning anything.
///
/// Persisted (and shared with an open reader) through `CBReaderSettings`.
enum EReaderScrollMode { horizontal, vertical }

extension EReaderScrollModeX on EReaderScrollMode {
  /// Stable token persisted to local storage.
  String get storageKey => name;

  bool get isVertical => this == EReaderScrollMode.vertical;

  /// Resolves a persisted [value] back to a mode, defaulting to [horizontal] —
  /// so an existing install keeps the paging it already had.
  static EReaderScrollMode fromStorage(String? value) =>
      EReaderScrollMode.values.firstWhere(
        (m) => m.name == value,
        orElse: () => EReaderScrollMode.horizontal,
      );
}
