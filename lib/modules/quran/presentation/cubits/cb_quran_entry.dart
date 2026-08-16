import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_last_read.dart';
import 'package:quran/modules/quran/presentation/cubits/s_quran_entry.dart';

/// Decides which screen the Quran module opens on when it is entered from
/// Home: the reader on the last page the user actually read, or the index the
/// first time round.
///
/// The reader saves its page as the user reads (see `CBMushafReader`), so this
/// only has to read that record back — a single Hive get, which is why the gate
/// resolves within a frame or two and never really shows its spinner.
class CBQuranEntry extends Cubit<SQuranEntry> {
  CBQuranEntry(this._lastRead) : super(const SQuranEntry());

  final UCSaveLastRead _lastRead;

  /// A stored page outside 1–604 is treated as no record at all rather than
  /// bounced off the reader's own range check into a blank screen.
  static const int _firstPage = 1;
  static const int _lastPage = 604;

  Future<void> resolve() async {
    final result = await _lastRead.getLastRead();
    if (isClosed) return;
    final page = result.fold((_) => null, (record) => record?.page);
    if (page == null || page < _firstPage || page > _lastPage) {
      emit(const SQuranEntry(target: QuranEntryTarget.indexScreen));
      return;
    }
    emit(SQuranEntry(target: QuranEntryTarget.reader, page: page));
  }
}
