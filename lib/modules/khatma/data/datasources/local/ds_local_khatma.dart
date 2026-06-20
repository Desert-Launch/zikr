import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';

class DSLocalKhatma {
  List<MKhatmaMetadata>? _metadataCache;
  final Map<int, List<MKhatmaWird>> _wirdsCache = {};

  /// Arabic surah name -> surah number (1-114), from the canonical surah list.
  /// Used to attach surah numbers to wirds so a range row can open the mushaf
  /// at the exact ayah.
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
      if (arabic.isNotEmpty) map[arabic] = number;
    }
    _surahNumberByArabic = map;
    return map;
  }

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
          ..sort((a, b) {
            if (a.isSuggested != b.isSuggested) return a.isSuggested ? -1 : 1;
            return a.days.compareTo(b.days);
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
      return wird.withSurahNumbers(
        start: surahNumbers[wird.startSurahAr] ?? 0,
        end: surahNumbers[wird.endSurahAr] ?? 0,
      );
    }).toList()..sort((a, b) => a.index.compareTo(b.index));
    _wirdsCache[plan.id] = wirds;
    return wirds;
  }
}
