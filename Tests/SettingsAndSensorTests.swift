import Foundation

@main
struct SettingsAndSensorTests {
    static func main() {
        let suiteName = "studio.macduo.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        precondition(EffectSettings.load(from: defaults) == EffectSettings())
        precondition(EffectSettings().frost == 0.027)
        precondition(EffectSettings().distance == 2.0)
        var settings = EffectSettings()
        settings.mode = .continuous
        settings.quality = .high
        settings.strength = 1.7
        settings.frost = 0.13
        settings.distance = 3.2
        settings.save(to: defaults)
        precondition(EffectSettings.load(from: defaults) == settings)
        defaults.set(Data("corrupt".utf8), forKey: EffectSettings.storageKey)
        precondition(EffectSettings.load(from: defaults) == EffectSettings())
        settings.strength = .nan
        settings.frost = .infinity
        settings.distance = -8
        precondition(settings.validated.strength == 1)
        precondition(settings.validated.frost == 0.027)
        precondition(settings.validated.distance == 1.4)
        for strength in [0.5, 1, 2] {
            settings.strength = strength
            precondition(settings.tilt(for: 0, openAngle: 120) == 80)
            precondition(settings.tilt(for: 120, openAngle: 120) == 0)
            precondition(settings.tilt(for: 180, openAngle: 120) == 0)
            var previous = 80.0
            for angle in 0...180 {
                let value = settings.tilt(for: Double(angle), openAngle: 120)
                precondition(value.isFinite && value >= 0 && value <= previous)
                previous = value
            }
        }
        precondition(settings.tilt(for: .nan, openAngle: 120) == 0)
        precondition(settings.tilt(for: 100, openAngle: 0) == 0)
        precondition(HingeReportDecoder.decode([1, 0, 0], length: 3) == 0)
        precondition(HingeReportDecoder.decode([1, 120, 0], length: 3) == 120)
        precondition(HingeReportDecoder.decode([1, 180, 0], length: 3) == 180)
        precondition(HingeReportDecoder.decode([1, 181, 0], length: 3) == nil)
        precondition(HingeReportDecoder.decode([1, 232, 3], length: 3) == nil)
        precondition(HingeReportDecoder.decode([1], length: 1) == nil)
        precondition(HingeReportDecoder.decode([1], length: 8) == nil)
        print("PASS: persisted settings, corrupt/invalid input, monotonic angle mapping, HID report boundaries")
    }
}
