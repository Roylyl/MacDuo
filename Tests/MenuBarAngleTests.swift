import Combine
import Foundation

@main
struct MenuBarAngleTests {
    static func main() {
        let angle = CurrentValueSubject<Double, Never>(105)
        let available = CurrentValueSubject<Bool, Never>(false)
        var received: [String] = []
        let subscription = MenuBarAngle.titles(angle: angle.eraseToAnyPublisher(),
                                               availability: available.eraseToAnyPublisher())
            .sink { received.append($0) }

        expect(received == ["—°"], "An unavailable sensor must initially show a placeholder")
        available.send(true)
        expect(received == ["—°", "105°"], "Connecting must immediately show the current default angle")

        angle.send(105.1)
        angle.send(105.49)
        available.send(true)
        expect(received == ["—°", "105°"], "Equivalent visible values must not publish repeatedly")
        angle.send(105.5)
        angle.send(106.4)
        angle.send(112)
        expect(received == ["—°", "105°", "106°", "112°"],
               "New rounded angles must publish once when their displayed value changes")

        available.send(false)
        expect(received.last == "—°", "Disconnecting must replace the old angle immediately")
        let disconnectedCount = received.count
        angle.send(120)
        angle.send(121.2)
        available.send(false)
        expect(received.count == disconnectedCount && received.last == "—°",
               "Angle updates while disconnected must keep one placeholder")
        available.send(true)
        expect(received.last == "121°" && received.count == disconnectedCount + 1,
               "Reconnecting must recover the latest angle, not the last angle seen before disconnection")

        let invalidAngles: [Double] = [.nan, .infinity, -.infinity, .greatestFiniteMagnitude,
                                      -.greatestFiniteMagnitude, -Double.leastNonzeroMagnitude,
                                      -1, 180.0001, 360]
        let beforeInvalid = received.count
        for value in invalidAngles { angle.send(value) }
        expect(received.count == beforeInvalid + 1 && received.last == "—°",
               "Non-finite and out-of-range inputs must safely produce one placeholder without integer conversion")

        angle.send(0)
        angle.send(-0.0)
        angle.send(0.49)
        expect(received.last == "0°" && received.count == beforeInvalid + 2,
               "The lower boundary and equivalent rounded values must remain valid and deduplicated")
        angle.send(0.5)
        angle.send(180)
        angle.send(179.99)
        expect(Array(received.suffix(2)) == ["1°", "180°"],
               "Half-degree rounding and the upper supported boundary must render safely")
        angle.send(180.1)
        expect(received.last == "—°", "Bounds must be checked before an invalid value can round into range")
        angle.send(105)
        expect(received.last == "105°", "A valid reading after invalid data must restore the angle")

        expect(received == ["—°", "105°", "106°", "112°", "—°", "121°", "—°", "0°", "1°", "180°", "—°", "105°"],
               "The complete publisher history must contain only actual changes to visible menu titles")
        let finalCount = received.count
        subscription.cancel()
        angle.send(90)
        available.send(false)
        expect(received.count == finalCount, "Cancellation must stop further title delivery")

        let alreadyConnectedAngle = CurrentValueSubject<Double, Never>(72)
        let alreadyConnected = CurrentValueSubject<Bool, Never>(true)
        var initialConnected: [String] = []
        let connectedSubscription = MenuBarAngle.titles(angle: alreadyConnectedAngle.eraseToAnyPublisher(),
                                                        availability: alreadyConnected.eraseToAnyPublisher())
            .sink { initialConnected.append($0) }
        expect(initialConnected == ["72°"], "A subscriber attaching after connection must immediately receive the current angle")
        connectedSubscription.cancel()

        print("PASS: menu angle publisher initial state, rounding, deduplication, disconnect/reconnect, invalid input, and cancellation")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        precondition(condition(), message)
    }
}
