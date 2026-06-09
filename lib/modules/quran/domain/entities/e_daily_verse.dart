import 'package:equatable/equatable.dart';

/// A single "verse of the day": the Uthmani text plus enough surah/ayah
/// metadata to render a caption and deep-link into the reader.
class EDailyVerse extends Equatable {
  const EDailyVerse({
    required this.surahNumber,
    required this.surahArabicName,
    required this.surahName,
    required this.ayah,
    required this.text,
  });

  final int surahNumber;
  final String surahArabicName;
  final String surahName;
  final int ayah;
  final String text;

  @override
  List<Object?> get props => [surahNumber, ayah, text];
}
