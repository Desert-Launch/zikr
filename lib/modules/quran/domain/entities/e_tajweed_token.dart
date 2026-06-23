import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/e_tajweed_rule.dart';

/// One coloured run of ayah text: a substring that shares a single Tajweed
/// [rule] (or `null` for plain, uncoloured text). Boundaries are snapped to
/// grapheme clusters offline so a base letter never separates from its harakat.
class ETajweedToken extends Equatable {
  const ETajweedToken({required this.text, this.rule});

  final String text;
  final ETajweedRule? rule;

  @override
  List<Object?> get props => [text, rule];
}
