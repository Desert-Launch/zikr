import 'dart:io';

import 'package:flutter/services.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/services/logging/app_logger.dart';

/// Gets the native Google Maps SDK its key and says whether a map may be shown.
///
/// The key is compiled into Dart ([AppConfig.googleMapsApiKey]) but the SDK
/// reads it natively, and the two can disagree: the Codemagic build swaps the
/// key into the Dart source without handing it to the native build. A map
/// created while the SDK has no key is not an error the app can catch — iOS
/// aborts on the spot — so no map is built until this says yes.
///
/// - iOS: hands the key over (`GMSServices.provideAPIKey`), so Dart is the one
///   source of the key there.
/// - Android: the SDK only reads the manifest, so this reports whether the
///   build put a key in it.
class MapsSdk {
  static const MethodChannel _channel = MethodChannel('com.zikr.mapp/maps_sdk');

  /// False when there is no key, on other platforms, or when the native side
  /// can't be reached — the screen then keeps its photo.
  Future<bool> ensureReady() async {
    const key = AppConfig.googleMapsApiKey;
    if (key.isEmpty || !(Platform.isIOS || Platform.isAndroid)) return false;
    try {
      final ready = await _channel.invokeMethod<bool>('ensureReady', {
        'apiKey': key,
      });
      return ready ?? false;
    } catch (e) {
      AppLogger.warning('Maps SDK not ready: $e', tag: 'MapsSdk');
      return false;
    }
  }
}
