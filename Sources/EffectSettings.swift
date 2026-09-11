import Foundation

enum EffectMode: String, Codable, CaseIterable, Identifiable {
    case daily, continuous
    var id: String { rawValue }
    var title: String { self == .daily ? "日常" : "持续展示" }
    var detail: String {
        self == .daily ? "开合时出现空间效果，停稳后回到清晰桌面。" : "持续跟随铰链角度；精确点击前请恢复原桌面。"
    }
}

enum RenderQuality: String, Codable, CaseIterable, Identifiable {
    case economy, balanced, high
    var id: String { rawValue }
    var title: String {
        switch self { case .economy: return "省电"; case .balanced: return "均衡"; case .high: return "清晰" }
    }
    var captureFPS: Int {
        switch self { case .economy: return 24; case .balanced: return 30; case .high: return 60 }
    }
    var captureScale: Double {
        switch self { case .economy: return 1; case .balanced: return 1.5; case .high: return 2 }
    }
}

struct EffectSettings: Codable, Equatable {
    var mode: EffectMode = .daily
    var quality: RenderQuality = .balanced
    var strength: Double = 1
    var frost: Double = 0.027
    var distance: Double = 2.0

    var validated: EffectSettings {
        var result = self
        result.strength = strength.isFinite ? min(2, max(0.5, strength)) : 1
        result.frost = frost.isFinite ? min(0.18, max(0, frost)) : 0.027
        result.distance = distance.isFinite ? min(4, max(1.4, distance)) : 2.0
        return result
    }

    func tilt(for angle: Double, openAngle: Double) -> Double {
        guard angle.isFinite, openAngle.isFinite, openAngle >= 1 else { return 0 }
        let progress = min(1, max(0, angle / openAngle))
        return 80 * (1 - pow(progress, 1 / validated.strength))
    }

    static let storageKey = "macduo.effectSettings.v1"
    static func load(from defaults: UserDefaults = .standard) -> EffectSettings {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
        return decoded.validated
    }
    func save(to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(validated) { defaults.set(data, forKey: Self.storageKey) }
    }
}
