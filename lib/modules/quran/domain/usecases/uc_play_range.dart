import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

class ParamPlayRange extends Equatable {
  const ParamPlayRange({required this.from, required this.to});
  final ParamAyahRef from;
  final ParamAyahRef to;
  @override
  List<Object?> get props => [from, to];
}

class UCPlayRange {
  const UCPlayRange();
  ParamPlayRange call(ParamAyahRef from, ParamAyahRef to) =>
      ParamPlayRange(from: from, to: to);
}
