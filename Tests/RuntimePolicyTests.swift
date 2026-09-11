import Foundation

@main
struct RuntimePolicyTests {
    static func main() {
        var motion = MotionVisibilityPolicy()
        assert(!motion.shouldShow(angle: 90, velocity: 0, now: 0, daily: true))
        // Quantized sensor noise should leave a stationary screen clear.
        assert(!motion.shouldShow(angle: 90.08, velocity: 0.2, now: 0.1, daily: true))
        assert(motion.shouldShow(angle: 91, velocity: 10, now: 0.2, daily: true))
        assert(motion.shouldShow(angle: 91, velocity: 0, now: 0.5, daily: true))
        assert(!motion.shouldShow(angle: 91, velocity: 0, now: 0.6, daily: true))
        assert(motion.shouldShow(angle: 91, velocity: 0, now: 1, daily: false))
        assert(motion.shouldShow(angle: 91, velocity: 0, now: 60, daily: false),
               "Continuous mode has no timed-demo cutoff")
        motion.reset()
        // Slowly accumulating movement still triggers, even below the speed threshold.
        assert(!motion.shouldShow(angle: 100, velocity: 0, now: 3, daily: true))
        assert(!motion.shouldShow(angle: 100.1, velocity: 0.3, now: 3.3, daily: true))
        assert(motion.shouldShow(angle: 100.3, velocity: 0.3, now: 4, daily: true))
        assert(!motion.shouldShow(angle: .nan, velocity: 0, now: 5, daily: true))

        var gate = CaptureFrameGate()
        gate.begin(generation: 1, now: 10)
        assert(!gate.didTimeOut(now: 15.9))
        assert(gate.didTimeOut(now: 16))
        gate.begin(generation: 2, now: 20)
        assert(!gate.markReady(generation: 1))
        assert(!gate.isReady)
        assert(gate.markReady(generation: 2))
        assert(!gate.didTimeOut(now: 100))
        gate.invalidate()
        assert(!gate.isReady)
        assert(!gate.markReady(generation: 2))
        gate.begin(generation: 3, now: 30)
        assert(!gate.isReady, "Wake must never inherit the previous stream's ready frame")

        var recovery = CaptureRecoveryPolicy()
        assert(recovery.nextDelay() == 0.5)
        recovery.noteHealthy(now: 1)
        recovery.noteHealthy(now: 2)
        assert(recovery.nextDelay() == 1, "A single frame must not reset repeated failure limits")
        assert(recovery.nextDelay() == 2)
        assert(recovery.nextDelay() == nil)
        recovery.reset()
        assert(recovery.nextDelay() == 0.5)
        recovery.noteHealthy(now: 10)
        recovery.noteHealthy(now: 25)
        assert(recovery.failureCount == 0)
        assert(recovery.nextDelay() == 0.5)
        recovery.noteHealthy(now: 30)
        recovery.suspend()
        recovery.noteHealthy(now: 100)
        assert(recovery.failureCount == 1, "Sleep does not count as a healthy capture interval")
        print("PASS: daily motion hold, slow movement, fresh-frame generations, timeout, bounded recovery")
    }
}
