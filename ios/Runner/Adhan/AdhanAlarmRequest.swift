import Foundation

/// One scheduled adhan, normalized from the Dart method-channel arguments so
/// both iOS delivery paths consume the same shape.
struct AdhanAlarmRequest {
    let id: Int
    let fireDate: Date
    /// Base name of the bundled sound, WITHOUT extension (e.g. `adhan_makkah`).
    /// The matching `.caf` lives in `ios/Runner/Sounds/`.
    let soundName: String
    let title: String
    let body: String
    let stopLabel: String
    let openLabel: String
    let prayerKey: String

    /// Notification-request identifier, namespaced so cancelling adhan alarms
    /// never touches `flutter_local_notifications`' own requests.
    var requestIdentifier: String { "adhan_alarm_\(id)" }

    /// Deterministic UUID for AlarmKit, derived from [id] so a cancel can find
    /// the same alarm without persisting a mapping. The prefix bytes namespace
    /// it to this feature.
    var alarmUUID: UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        let prefix: [UInt8] = [0xAD, 0x4A, 0x4E, 0x00, 0x5A, 0x49, 0x4B, 0x52]
        for (i, b) in prefix.enumerated() { bytes[i] = b }
        var value = UInt64(bitPattern: Int64(id))
        for i in 0..<8 {
            bytes[15 - i] = UInt8(value & 0xFF)
            value >>= 8
        }
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    /// Filename iOS expects for the notification sound.
    var soundFileName: String { "\(soundName).caf" }
}
