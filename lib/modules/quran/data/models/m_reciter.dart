import 'package:equatable/equatable.dart';

/// How the recitation is delivered. `muallim` is the slow "teacher" style
/// (a pause after every word/phrase) recorded for memorisation.
enum ReciterStyle {
  murattal,
  mujawwad,
  muallim;

  /// Parses the catalogue's `style` string; unknown values fall back to
  /// [murattal] so a typo in `reciters.json` never breaks the picker.
  static ReciterStyle fromKey(String? key) =>
      ReciterStyle.values.firstWhere((s) => s.name == key, orElse: () => ReciterStyle.murattal);

  /// Flat i18n key for the style label (`reciter_style_*`).
  String get labelKey => 'reciter_style_$name';
}

class MReciter extends Equatable {
  const MReciter({
    required this.id,
    required this.name,
    required this.arabic,
    required this.style,
    required this.folder,
    required this.bitrate,
    required this.estimatedSizeMb,
    this.isDefault = false,
  });

  factory MReciter.fromJson(Map<String, dynamic> json) => MReciter(
        id: json['id'] as String,
        name: json['name'] as String,
        arabic: json['arabic'] as String? ?? '',
        style: ReciterStyle.fromKey(json['style'] as String?),
        folder: json['folder'] as String,
        bitrate: json['bitrate'] as int? ?? 128,
        estimatedSizeMb: json['estimatedSizeMb'] as int? ?? 0,
        isDefault: json['isDefault'] as bool? ?? false,
      );

  final String id;
  final String name;
  final String arabic;
  final ReciterStyle style;
  final String folder;
  final int bitrate;
  final int estimatedSizeMb;
  final bool isDefault;

  @override
  List<Object?> get props => [id];
}
