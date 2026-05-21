import 'package:equatable/equatable.dart';

enum DownloadKind { surah, juz }

class ParamDownloadRequest extends Equatable {
  const ParamDownloadRequest({
    required this.kind,
    required this.reciterId,
    required this.number,
  });

  const ParamDownloadRequest.surah({required this.reciterId, required int surah})
      : kind = DownloadKind.surah, number = surah;

  const ParamDownloadRequest.juz({required this.reciterId, required int juz})
      : kind = DownloadKind.juz, number = juz;

  final DownloadKind kind;
  final String reciterId;
  final int number;

  String get taskId => '${reciterId}_${kind.name}_$number';

  @override
  List<Object?> get props => [kind, reciterId, number];
}
