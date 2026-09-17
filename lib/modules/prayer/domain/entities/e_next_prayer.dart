import 'package:equatable/equatable.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';

/// The upcoming salah and when it falls.
///
/// The countdown is deliberately NOT a field: a stored `Duration` is wrong one
/// second after it is computed, and persisting one is how a card ends up
/// counting down to a prayer that has already passed. [remainingFrom] derives
/// it from the current time and [time] every tick instead.
class ENextPrayer extends Equatable {
  const ENextPrayer({required this.prayer, required this.time});

  /// Always one of the five — sunrise is listed on the screen but is not a
  /// salah and is never "the next prayer".
  final EPrayer prayer;

  /// The absolute instant, carrying the location's zone.
  final DateTime time;

  Duration remainingFrom(DateTime now) => time.difference(now);

  /// Convenience for a widget that is already rebuilding on a ticker.
  Duration get remaining => remainingFrom(DateTime.now());

  @override
  List<Object?> get props => [prayer, time];
}
