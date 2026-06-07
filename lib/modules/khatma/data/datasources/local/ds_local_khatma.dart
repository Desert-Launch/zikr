import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';

class DSLocalKhatma {
  List<MKhatmaMetadata>? _metadataCache;
  final Map<int, List<MKhatmaWird>> _wirdsCache = {};

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
    final wirds = decoded.entries.map((entry) {
      final index = int.tryParse(entry.key.replaceFirst('day_', '')) ?? 0;
      return MKhatmaWird.fromJson(
        index,
        Map<String, dynamic>.from(entry.value as Map),
      );
    }).toList()..sort((a, b) => a.index.compareTo(b.index));
    _wirdsCache[plan.id] = wirds;
    return wirds;
  }
}
