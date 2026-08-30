import 'package:equatable/equatable.dart';

/// What to resolve for a share: a run of verses out of one surah, plus the
/// commentary books to send with them.
class ParamShareRange extends Equatable {
  const ParamShareRange({
    required this.surah,
    required this.from,
    required this.to,
    this.bookIds = const [],
  });

  final int surah;
  final int from;
  final int to;

  /// Ids of the tafsir books to attach, in the order the reader arranged them.
  /// Empty for the default share, which is the verses on their own.
  final List<String> bookIds;

  @override
  List<Object?> get props => [surah, from, to, bookIds];
}
