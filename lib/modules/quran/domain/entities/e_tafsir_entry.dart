import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';

/// One book's resolved commentary for a single ayah.
///
/// [html] is ready-to-render markup (the raw QUL `text` field). When the source
/// entry was a range pointer (e.g. `2:255` points at `2:253`), [linkedFromKey]
/// holds the ayah key the text was actually pulled from so the UI can note that
/// the commentary covers a group of ayat.
class ETafsirEntry extends Equatable {
  const ETafsirEntry({
    required this.book,
    required this.html,
    this.linkedFromKey,
  });

  final ETafsirBook book;
  final String html;
  final String? linkedFromKey;

  bool get isLinked => linkedFromKey != null;

  @override
  List<Object?> get props => [book.id, html, linkedFromKey];
}
