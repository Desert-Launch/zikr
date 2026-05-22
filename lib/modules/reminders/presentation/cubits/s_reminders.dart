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

  @override
  List<Object?> get props => [items, error];
}
