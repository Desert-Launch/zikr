import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

/// A contiguous stretch of the mushaf named by its first and last ayah — a
/// khatma wird, for instance.
class ParamAyahRange extends Equatable {
  const ParamAyahRange({required this.start, required this.end});

  /// Parses the `from`/`to` pair a reader route carries, each in
  /// [ParamAyahRef.key] form (`surah:ayah`). Null when either is missing or
  /// malformed, so a bad deep link degrades to a plain reader open.
  static ParamAyahRange? tryParse(String? from, String? to) {
    if (from == null || to == null) return null;
    final start = _tryKey(from);
    final end = _tryKey(to);
    if (start == null || end == null) return null;
    return ParamAyahRange(start: start, end: end);
  }

  static ParamAyahRef? _tryKey(String key) {
    final parts = key.split(':');
    if (parts.length != 2) return null;
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null) return null;
    return ParamAyahRef(surah: surah, ayah: ayah);
  }

  final ParamAyahRef start;
  final ParamAyahRef end;

  /// Whether [ref] is one of the two ayahs that bound the range.
  bool isBound(ParamAyahRef ref) => ref == start || ref == end;

  @override
  List<Object?> get props => [start, end];
}
