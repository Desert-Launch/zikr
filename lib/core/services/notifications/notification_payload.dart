import 'dart:convert';

/// Structured payload attached to every scheduled notification. Encoded as
/// JSON in `NotificationDetails.payload` so the tap handler can route the
/// user to the right screen.
///
/// The `type` discriminates the handler:
///   - `prayer`   → opens prayer times screen
///   - `adhan`    → opens currently-playing adhan
///   - `azkar`    → opens azkar group identified by `data['group']`
///   - `hourly`   → opens tasbih
///   - `reminder` → opens reminder identified by `data['id']`
///   - `quran`    → opens reader at `data['surah']`:`data['ayah']`
class NotificationPayload {
  const NotificationPayload({required this.type, this.data = const {}});

  factory NotificationPayload.fromJson(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationPayload(
        type: m['type'] as String? ?? 'unknown',
        data: Map<String, dynamic>.from(m['data'] as Map? ?? const {}),
      );
    } catch (_) {
      return const NotificationPayload(type: 'unknown');
    }
  }

  final String type;
  final Map<String, dynamic> data;

  String encode() => jsonEncode({'type': type, 'data': data});
}
