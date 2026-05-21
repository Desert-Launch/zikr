import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

/// Marker use case — actual orchestration lives in [CBAudioPlayer.playFrom].
/// Use cases that only call the cubit's exposed methods are kept as thin
/// indirection points so other layers don't depend on the cubit directly.
class UCPlayAyah {
  const UCPlayAyah();

  /// Returns the [ParamAyahRef] starting point unchanged. The audio cubit
  /// reads it and builds the queue.
  ParamAyahRef call(ParamAyahRef ref) => ref;
}
