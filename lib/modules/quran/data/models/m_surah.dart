import 'package:equatable/equatable.dart';

/// Surah metadata, loaded from assets/data/surahs.json.
class MSurah extends Equatable {
  const MSurah({
    required this.number,
    required this.name,
    required this.arabic,
    required this.arabicLong,
    required this.translation,
    required this.revelationPlace,
    required this.totalAyah,
    required this.pageStart,
    required this.juzStart,
    required this.revelationOrder,
  });

  factory MSurah.fromJson(Map<String, dynamic> json) => MSurah(
        number: json['number'] as int,
        name: json['name'] as String? ?? '',
        arabic: json['arabic'] as String? ?? '',
        arabicLong: json['arabicLong'] as String? ?? '',
        translation: json['translation'] as String? ?? '',
        revelationPlace: json['revelationPlace'] as String? ?? '',
        totalAyah: json['totalAyah'] as int? ?? 0,
        pageStart: json['pageStart'] as int? ?? 0,
        juzStart: json['juzStart'] as int? ?? 0,
        revelationOrder: json['revelationOrder'] as int? ?? 0,
      );

  final int number;
  final String name;
  final String arabic;
  final String arabicLong;
  final String translation;
  final String revelationPlace; // "Mecca" | "Madina"
  final int totalAyah;
  final int pageStart;
  final int juzStart;
  final int revelationOrder;

  bool get isMakki => revelationPlace == 'Mecca';
  bool get isMadani => revelationPlace == 'Madina';

  @override
  List<Object?> get props => [number, totalAyah, pageStart];
}
