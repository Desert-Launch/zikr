import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_entry.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

/// State for the per-ayah tafsir screen.
class STafsir extends Equatable {
  const STafsir({
    this.status = LoadStatus.idle,
    this.ref,
    this.entries = const [],
    this.hasBooks = true,
    this.selectedBookId,
    this.error,
  });

  final LoadStatus status;
  final ParamAyahRef? ref;
  final List<ETafsirEntry> entries;

  /// Whether the user has any tafsir book downloaded at all. When false the
  /// screen invites them to the library instead of showing an empty result.
  final bool hasBooks;

  /// Book the viewer opens on — the one picked in the library. Null falls back
  /// to [TafsirCatalog.defaultBookId].
  final String? selectedBookId;
  final String? error;

  STafsir copyWith({
    LoadStatus? status,
    ParamAyahRef? ref,
    List<ETafsirEntry>? entries,
    bool? hasBooks,
    String? selectedBookId,
    bool clearSelectedBook = false,
    String? error,
    bool clearError = false,
  }) {
    return STafsir(
      status: status ?? this.status,
      ref: ref ?? this.ref,
      entries: entries ?? this.entries,
      hasBooks: hasBooks ?? this.hasBooks,
      selectedBookId:
          clearSelectedBook ? null : (selectedBookId ?? this.selectedBookId),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [status, ref, entries, hasBooks, selectedBookId, error];
}
