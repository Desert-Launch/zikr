/// Where the Quran module should open when it is entered from outside (Home).
enum QuranEntryTarget {
  /// Still reading the last-read record out of Hive.
  resolving,

  /// A page has been read before — go straight back to it.
  reader,

  /// Nothing read yet — show the index so the reader can pick a start.
  /// (Named `indexScreen` because every enum already owns `index`.)
  indexScreen,
}

class SQuranEntry {
  const SQuranEntry({this.target = QuranEntryTarget.resolving, this.page});

  final QuranEntryTarget target;

  /// The page to reopen. Only meaningful when [target] is
  /// [QuranEntryTarget.reader].
  final int? page;
}
