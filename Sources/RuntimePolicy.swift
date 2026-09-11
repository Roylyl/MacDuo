import Foundation

/// A small, deterministic policy, independent of AppKit and the capture service.
/// Hysteresis and a short hold prevent sensor quantization from flashing the overlay.
struct MotionVisibilityPolicy {
    var holdDuration: TimeInterval = 0.35
    var movementThreshold: Double = 0.25
    var velocityThreshold: Double = 1.4
    private var referenceAngle: Double?
    private var lastMotion: TimeInterval?

    mutating func reset() {
        referenceAngle = nil
        lastMotion = nil
    }

    mutating func shouldShow(angle: Double, velocity: Double, now: TimeInterval,
                             daily: Bool) -> Bool {
        guard angle.isFinite, velocity.isFinite, now.isFinite else { return false }
        if let referenceAngle {
            if abs(angle - referenceAngle) >= movementThreshold || abs(velocity) >= velocityThreshold {
                lastMotion = now
                self.referenceAngle = angle
            }
        } else {
            // Merely enabling daily mode must not be interpreted as an opening motion.
            referenceAngle = angle
        }
        if !daily { return true }
        guard let lastMotion else { return false }
        return now - lastMotion <= holdDuration
    }
}

/// Every restarted stream must supply a fresh, GPU-ready frame before presentation.
/// Old asynchronous callbacks cannot make a newer generation ready.
struct CaptureFrameGate {
    var timeout: TimeInterval = 6
    private(set) var generation = 0
    private(set) var isReady = false
    private var beganAt: TimeInterval?

    mutating func begin(generation: Int, now: TimeInterval) {
        self.generation = generation
        beganAt = now
        isReady = false
    }

    mutating func invalidate() {
        beganAt = nil
        isReady = false
        generation += 1
    }

    @discardableResult
    mutating func markReady(generation: Int) -> Bool {
        guard beganAt != nil, self.generation == generation else { return false }
        isReady = true
        return true
    }

    func didTimeOut(now: TimeInterval) -> Bool {
        guard let beganAt, !isReady else { return false }
        return now - beganAt >= timeout
    }
}

/// Do not reset retry limits on a single successful frame: a stream that repeatedly
/// delivers one frame and fails must eventually stop, rather than retry forever.
struct CaptureRecoveryPolicy {
    private(set) var failureCount = 0
    private var healthySince: TimeInterval?
    let maxRetries = 3
    var healthyResetInterval: TimeInterval = 15

    mutating func reset() {
        failureCount = 0
        healthySince = nil
    }

    mutating func nextDelay() -> TimeInterval? {
        healthySince = nil
        guard failureCount < maxRetries else { return nil }
        let delay = 0.5 * pow(2, Double(failureCount))
        failureCount += 1
        return delay
    }

    mutating func noteHealthy(now: TimeInterval) {
        guard let healthySince else {
            self.healthySince = now
            return
        }
        if now - healthySince >= healthyResetInterval {
            failureCount = 0
        }
    }

    mutating func suspend() {
        healthySince = nil
    }
}
