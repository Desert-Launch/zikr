import 'package:equatable/equatable.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';

class SAzkarSession extends Equatable {
  const SAzkarSession({
    this.category,
    this.itemIndex = 0,
    this.completed = const {},
    this.audioPlaying = false,
  });

  final MAzkarCategory? category;
  final int itemIndex;
  /// item id → number of taps on this zekr today.
  final Map<String, int> completed;

  /// Whether the recitation is running (or loading) — drives the play/pause
  /// icon, and while true each finished clip moves on to the next zekr.
  final bool audioPlaying;

  MAzkarItem? get currentItem {
    final c = category;
    if (c == null || c.items.isEmpty) return null;
    final i = itemIndex.clamp(0, c.items.length - 1);
    return c.items[i];
  }

  int countFor(String itemId) => completed[itemId] ?? 0;

  bool isComplete(MAzkarItem item) => countFor(item.id) >= item.repeat;

  SAzkarSession copyWith({
    MAzkarCategory? category,
    int? itemIndex,
    Map<String, int>? completed,
    bool? audioPlaying,
  }) {
    return SAzkarSession(
      category: category ?? this.category,
      itemIndex: itemIndex ?? this.itemIndex,
      completed: completed ?? this.completed,
      audioPlaying: audioPlaying ?? this.audioPlaying,
    );
  }

  @override
  List<Object?> get props => [category, itemIndex, completed, audioPlaying];
}
