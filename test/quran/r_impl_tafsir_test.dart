import 'package:flutter_test/flutter_test.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_tafsir.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_remote_tafsir.dart';
import 'package:quran/modules/quran/data/repos/r_impl_tafsir.dart';
import 'package:quran/modules/quran/data/sources/local/box_tafsir.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

/// Serves one book from in-memory surah slices, the way [DSLocalTafsir] serves
/// them from per-surah files, and records which slices were read.
class _FakeLocal extends DSLocalTafsir {
  _FakeLocal(this.slices) : super(BoxTafsir());

  final Map<int, Map<String, dynamic>> slices;
  final List<int> reads = <int>[];

  @override
  List<String> downloadedIds() => [TafsirCatalog.defaultBookId];

  @override
  Future<Map<String, dynamic>?> surahEntries(String bookId, int surah) async {
    reads.add(surah);
    return slices[surah];
  }
}

void main() {
  Map<String, dynamic> entry(String text) => {'text': text};

  final local = _FakeLocal({
    1: {'1:1': entry('opening')},
    2: {
      '2:1': entry('alif lam mim'),
      '2:2': entry('2:1'), // range pointer within the surah
      '2:3': entry(''),
    },
    3: {'3:1': entry('2:1')}, // range pointer back into an earlier surah
  });
  final repo = RImplTafsir(local, DSRemoteTafsir());

  Future<List<String>> textsFor(int surah, int ayah) async {
    final res = await repo.getForAyah(ParamAyahRef(surah: surah, ayah: ayah));
    return res.fold((f) => fail(f.message), (entries) => [for (final e in entries) e.html]);
  }

  setUp(local.reads.clear);

  test('reads the entry from its own surah slice only', () async {
    expect(await textsFor(1, 1), ['opening']);
    expect(local.reads, [1]);
  });

  test('follows a range pointer within the surah', () async {
    final res = await repo.getForAyah(const ParamAyahRef(surah: 2, ayah: 2));
    final entries = res.getOrElse(() => const []);
    expect(entries.single.html, 'alif lam mim');
    expect(entries.single.linkedFromKey, '2:1');
  });

  test('follows a range pointer into an earlier surah', () async {
    expect(await textsFor(3, 1), ['alif lam mim']);
    expect(local.reads, [3, 2]);
  });

  test('skips an empty entry and an ayah the book does not cover', () async {
    expect(await textsFor(2, 3), isEmpty);
    expect(await textsFor(9, 1), isEmpty);
  });
}
