import 'package:equatable/equatable.dart';

/// Identifies a single ayah by surah + ayah number.
class ParamAyahRef extends Equatable {
  const ParamAyahRef({required this.surah, required this.ayah});

  factory ParamAyahRef.fromKey(String key) {
    final parts = key.split(':');
    return ParamAyahRef(surah: int.parse(parts[0]), ayah: int.parse(parts[1]));
  }

  final int surah;
  final int ayah;

  String get key => '$surah:$ayah';

  @override
  List<Object?> get props => [surah, ayah];

  @override
  String toString() => 'ParamAyahRef($key)';
}
