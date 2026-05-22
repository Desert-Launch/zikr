import 'package:equatable/equatable.dart';

class STasbih extends Equatable {
  const STasbih({
    this.zekrAr = 'سُبْحَانَ اللَّهِ',
    this.target = 33,
    this.count = 0,
    this.vibrate = true,
    this.hourlyEnabled = false,
  });

  final String zekrAr;
  final int target;
  final int count;
  final bool vibrate;
  final bool hourlyEnabled;

  bool get isComplete => count >= target;
  double get progress => target == 0 ? 0.0 : (count / target).clamp(0.0, 1.0);

  STasbih copyWith({
    String? zekrAr,
    int? target,
    int? count,
    bool? vibrate,
    bool? hourlyEnabled,
  }) {
    return STasbih(
      zekrAr: zekrAr ?? this.zekrAr,
      target: target ?? this.target,
      count: count ?? this.count,
      vibrate: vibrate ?? this.vibrate,
      hourlyEnabled: hourlyEnabled ?? this.hourlyEnabled,
    );
  }

  @override
  List<Object?> get props => [zekrAr, target, count, vibrate, hourlyEnabled];
}
