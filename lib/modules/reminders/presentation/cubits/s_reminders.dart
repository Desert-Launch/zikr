import 'package:equatable/equatable.dart';
import 'package:quran/modules/reminders/data/models/m_reminder.dart';

class SReminders extends Equatable {
  const SReminders({
    this.items = const [],
    this.error,
  });

  final List<MReminder> items;
  final String? error;

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

  // Content signature so in-place mutations of the Hive-backed [MReminder]
  // objects (e.g. toggling `enabled`) still produce a non-equal state and
  // trigger a rebuild. Comparing `items` directly uses identity equality on the
  // same mutated instances, so the change would be missed and `emit` skipped.
  String get _signature => items
      .map((r) =>
          '${r.id}:${r.enabled}:${r.hour}:${r.minute}:${r.title}:${r.iconId}:${r.colorId}')
      .join('|');

  @override
  List<Object?> get props => [_signature, error];
}
