import 'package:equatable/equatable.dart';

/// One calculation authority as Aladhan describes it.
///
/// The live `/v1/methods` response is the source of truth — the list is
/// fetched, cached, and re-read, never compiled in. [fallback] exists only so
/// a first run with no network still has something to show in the picker.
class ECalculationMethod extends Equatable {
  const ECalculationMethod({
    required this.id,
    required this.name,
    this.params,
  });

  /// Aladhan's `method` id. Sent verbatim; never interpreted above the data
  /// layer.
  final int id;

  /// The authority's own name, e.g. `Egyptian General Authority of Survey`.
  /// Shown as-is: these are proper nouns and are not translated.
  final String name;

  /// The published angles/intervals behind the method (`{"Fajr": 19.5,
  /// "Isha": 17.5}`). Displayed as a hint under the name where present.
  final Map<String, dynamic>? params;

  /// Aladhan's "roll your own angles" pseudo-method. Never offered in the
  /// picker — it means nothing without the custom angles that go with it.
  static const int customId = 99;

  factory ECalculationMethod.fromJson(Map<String, dynamic> json) {
    final rawParams = json['params'];
    return ECalculationMethod(
      id: (json['id'] as num?)?.toInt() ?? -1,
      name: json['name']?.toString() ?? '',
      params: rawParams is Map ? rawParams.cast<String, dynamic>() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (params != null) 'params': params,
  };

  /// A short one-line summary of [params] for the picker subtitle, e.g.
  /// `Fajr 19.5° · Isha 17.5°`. Empty when the method publishes none.
  String get paramsSummary {
    final p = params;
    if (p == null || p.isEmpty) return '';
    return p.entries
        .where((e) => e.key == 'Fajr' || e.key == 'Isha' || e.key == 'Maghrib')
        .map((e) {
          final value = e.value;
          // Angles arrive as numbers, intervals as strings ("90 min").
          return value is num ? '${e.key} $value°' : '${e.key} $value';
        })
        .join(' · ');
  }

  /// Last-resort list for a first launch with no network and an empty cache.
  ///
  /// Deliberately NOT the app's idea of what methods exist — it is a stopgap
  /// so the picker is never blank, replaced by the live list the first time
  /// `/v1/methods` answers.
  static const List<ECalculationMethod> fallback = [
    ECalculationMethod(id: 3, name: 'Muslim World League'),
    ECalculationMethod(id: 2, name: 'Islamic Society of North America (ISNA)'),
    ECalculationMethod(id: 5, name: 'Egyptian General Authority of Survey'),
    ECalculationMethod(id: 4, name: 'Umm Al-Qura University, Makkah'),
    ECalculationMethod(id: 1, name: 'University of Islamic Sciences, Karachi'),
    ECalculationMethod(id: 8, name: 'Gulf Region'),
    ECalculationMethod(id: 9, name: 'Kuwait'),
    ECalculationMethod(id: 10, name: 'Qatar'),
    ECalculationMethod(id: 11, name: 'Majlis Ugama Islam Singapura, Singapore'),
    ECalculationMethod(id: 12, name: 'Union Organization Islamic de France'),
    ECalculationMethod(id: 13, name: 'Diyanet İşleri Başkanlığı, Turkey'),
    ECalculationMethod(id: 14, name: 'Spiritual Administration of Muslims of Russia'),
    ECalculationMethod(id: 15, name: 'Moonsighting Committee Worldwide'),
    ECalculationMethod(id: 16, name: 'Dubai'),
    ECalculationMethod(id: 17, name: 'Jabatan Kemajuan Islam Malaysia (JAKIM)'),
    ECalculationMethod(id: 18, name: 'Tunisia'),
    ECalculationMethod(id: 19, name: 'Algeria'),
    ECalculationMethod(id: 20, name: 'Kementerian Agama Republik Indonesia'),
    ECalculationMethod(id: 21, name: 'Morocco'),
    ECalculationMethod(id: 22, name: 'Comunidade Islamica de Lisboa'),
    ECalculationMethod(id: 23, name: 'Ministry of Awqaf, Jordan'),
    ECalculationMethod(id: 7, name: 'Institute of Geophysics, University of Tehran'),
    ECalculationMethod(id: 0, name: 'Shia Ithna-Ashari, Leva Institute, Qum'),
  ];

  @override
  List<Object?> get props => [id, name];
}
