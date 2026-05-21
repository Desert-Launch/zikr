import 'package:equatable/equatable.dart';

enum ReciterStyle { murattal, mujawwad }

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
        style: (json['style'] as String? ?? 'murattal') == 'mujawwad'
            ? ReciterStyle.mujawwad
            : ReciterStyle.murattal,
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
