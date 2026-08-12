import 'package:equatable/equatable.dart';
import 'package:quran/modules/reminders/data/models/m_reminder.dart';

class SReminders extends Equatable {
  SReminders({
    this.items = const [],
    this.error,
  }) : _signature = _signatureOf(items);

  final List<MReminder> items;
  final String? error;

  /// Snapshot of [items]' contents taken when this state was built — see
  /// [_signatureOf].
  final String _signature;

  int get count => items.length;
  bool get isAtCap => count >= 30;

  SReminders copyWith({
    List<MReminder>? items,
    String? error,
    bool clearError = false,
  }) {
    return SReminders(
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Content signature so in-place mutations of the Hive-backed [MReminder]
  /// objects (editing a time, toggling `enabled`) still produce a non-equal
  /// state and trigger a rebuild.
  ///
  /// It MUST be captured eagerly in the constructor. As a lazy getter it was
  /// computed at comparison time, and since the previous state and the new one
  /// both reference the SAME mutated `MReminder` instances, both sides produced
  /// the *new* values — the states compared equal, `emit` was dropped, and the
  /// list kept showing the old time / the switch snapped back. Storing the
  /// string freezes each state's view of the data at the moment it was built.
  static String _signatureOf(List<MReminder> items) => items
      .map(
        (r) => '${r.id}:${r.enabled}:${r.hour}:${r.minute}:${r.title}'
            ':${r.iconId}:${r.colorId}:${r.daysOfWeek.join()}',
      )
      .join('|');

  @override
  List<Object?> get props => [_signature, error];
}
