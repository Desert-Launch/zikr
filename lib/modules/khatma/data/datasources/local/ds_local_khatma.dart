import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';

class DSLocalKhatma {
  List<MKhatmaMetadata>? _metadataCache;
  final Map<int, List<MKhatmaWird>> _wirdsCache = {};

  /// Arabic surah name -> surah number (1-114), from the canonical surah list.
  /// Used to attach surah numbers to hand-made wirds (those carrying none in
  /// their JSON) so a range row can open the mushaf at the exact ayah.
  ///
  /// Keyed by [_surahKey], because the hand-made plans spell a few names with
  /// a hamza the surah list writes without (إبراهيم / ابراهيم, سبأ / سبإ).
  Map<String, int>? _surahNumberByArabic;

  Future<Map<String, int>> _surahNumbers() async {
    if (_surahNumberByArabic != null) return _surahNumberByArabic!;
    final raw = await rootBundle.loadString('assets/data/surahs.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    final map = <String, int>{};
    for (final item in decoded) {
      final surah = Map<String, dynamic>.from(item as Map);
      final arabic = surah['arabic'] as String? ?? '';
      final number = surah['number'] as int? ?? 0;
      if (arabic.isNotEmpty) map[_surahKey(arabic)] = number;
    }
    _surahNumberByArabic = map;
    return map;
  }

  /// Collapses the alef and hamza spellings that vary between sources onto a
  /// bare alef, so the same surah spelt two ways lands on one key.
  static String _surahKey(String name) => name
      .replaceAll(RegExp('[\u0622\u0623\u0625\u0671]'), '\u0627')
      .replaceAll('\u0624', '\u0648')
      .replaceAll('\u0626', '\u064A')
      .replaceAll('\u0621', '')
      .trim();

  Future<List<MKhatmaMetadata>> metadata() async {
    if (_metadataCache != null) return _metadataCache!;
    final raw = await rootBundle.loadString(
      'assets/data/khatma/khatma_metadata.json',
    );
    final decoded = jsonDecode(raw) as List<dynamic>;
    final plans =
        decoded
            .map(
              (item) => MKhatmaMetadata.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList()
          // Suggested first, then longest (gentlest) plan to shortest.
          ..sort((a, b) {
            if (a.isSuggested != b.isSuggested) return a.isSuggested ? -1 : 1;
            return b.days.compareTo(a.days);
          });
    _metadataCache = plans;
    return plans;
  }

  Future<MKhatmaMetadata?> plan(int id) async {
    final plans = await metadata();
    final matches = plans.where((plan) => plan.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  Future<MKhatmaMetadata?> planForDays(int days) async {
    final plans = await metadata();
    final matches = plans.where((plan) => plan.days == days);
    return matches.isEmpty ? null : matches.first;
  }

  Future<List<MKhatmaWird>> wirds(MKhatmaMetadata plan) async {
    if (_wirdsCache.containsKey(plan.id)) return _wirdsCache[plan.id]!;
    final raw = await rootBundle.loadString(plan.path);
    final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final surahNumbers = await _surahNumbers();
    final wirds = decoded.entries.map((entry) {
      final index = int.tryParse(entry.key.replaceFirst('day_', '')) ?? 0;
      final wird = MKhatmaWird.fromJson(
        index,
        Map<String, dynamic>.from(entry.value as Map),
      );
      if (wird.hasSurahNumbers) return wird;
      return wird.withSurahNumbers(
        start: surahNumbers[_surahKey(wird.startSurahAr)] ?? 0,
        end: surahNumbers[_surahKey(wird.endSurahAr)] ?? 0,
      );
    }).toList()..sort((a, b) => a.index.compareTo(b.index));
    _wirdsCache[plan.id] = wirds;
    return wirds;
  }
}
