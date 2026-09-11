import Combine
import Foundation

/// The menu remains discoverable even before capture starts or a sensor connects.
enum MenuBarAngle {
    static func title(angle: Double, isAvailable: Bool) -> String {
        guard isAvailable, angle.isFinite, (0...180).contains(angle) else { return "—°" }
        return "\(Int(angle.rounded()))°"
    }

    static func titles(angle: AnyPublisher<Double, Never>,
                       availability: AnyPublisher<Bool, Never>) -> AnyPublisher<String, Never> {
        angle.combineLatest(availability)
            .map { title(angle: $0, isAvailable: $1) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
