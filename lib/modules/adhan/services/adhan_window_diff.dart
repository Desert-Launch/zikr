/// Decides which adhan-window notifications a rebuild actually has to touch.
///
/// A rebuild used to cancel the whole window and schedule it again — about a
/// hundred cancels plus a hundred schedules per pass, several passes per cold
/// start, all on the UI thread. And flutter_local_notifications rewrites its
/// entire stored schedule on every single schedule and cancel, so each pass
/// was quadratic. Window ids are deterministic and scheduling an id that is
/// already queued replaces it, so a rebuild only ever needs:
///
///  * [toSchedule] — planned entries that are new, changed, or not provably
///    queued as planned;
///  * [toCancel] — ids still queued in the window's bands that the new plan no
///    longer contains.
///
/// Everything else is already exactly right and is left alone.
class AdhanWindowDiff {
  const AdhanWindowDiff({required this.toSchedule, required this.toCancel});

  /// Diffs [planned] (id → fingerprint of everything that decides how it
  /// rings) against [queued] (id → fingerprint recovered from what is actually
  /// pending; `null` when the entry carries none, e.g. it predates them).
  ///
  /// [trustQueued] is false for the first rebuild of a process: the pending
  /// list is the plugin's own cache, not AlarmManager, and a force-stop clears
  /// the alarms while leaving that cache intact. Only a run that has itself
  /// armed the window in this process may believe "queued" means "armed", so an
  /// untrusted run re-arms every planned entry — and still cancels nothing it
  /// is about to replace.
  factory AdhanWindowDiff.between({
    required Map<int, String> planned,
    required Map<int, String?> queued,
    required bool trustQueued,
  }) {
    return AdhanWindowDiff(
      toSchedule: {
        for (final entry in planned.entries)
          if (!trustQueued || queued[entry.key] != entry.value) entry.key,
      },
      toCancel: {
        for (final id in queued.keys)
          if (!planned.containsKey(id)) id,
      },
    );
  }

  final Set<int> toSchedule;
  final Set<int> toCancel;

  /// Payload `data` key the fingerprint travels under, so the next rebuild can
  /// read it back from the pending list without a store of its own — and what
  /// it reads is always what is really queued, whichever isolate queued it.
  static const String payloadKey = 'fp';

  /// Stable fingerprint of [parts] (FNV-1a, 32-bit, hex). Not
  /// `Object.hashCode`, which is free to differ between runs — this one is
  /// written into notifications that outlive the process that computed it.
  static String fingerprint(Iterable<Object?> parts) {
    var hash = 0x811c9dc5;
    for (final unit in parts.join('\u0001').codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
