import Foundation
import Combine
import IOKit.hid
import QuartzCore

/// Public UI state. Blocking HID feature reports run on a dedicated serial queue.
@MainActor
final class LidAngleSensor: ObservableObject {
    @Published private(set) var angle = 105.0
    private(set) var lastSuccessfulUpdate = Date.distantPast
    @Published private(set) var velocity = 0.0
    @Published private(set) var isAvailable = false
    @Published private(set) var statusText = "正在查找铰链传感器…"
    private var reader: HingeHIDReader?
    private var lastTime = 0.0
    private var lastAngle = 105.0

    func start() {
        guard reader == nil else { return }
        let reader = HingeHIDReader { [weak self] sample in
            Task { @MainActor in self?.apply(sample) }
        }
        self.reader = reader
        reader.start()
    }

    private func apply(_ sample: HingeSample) {
        switch sample {
        case let .angle(measured, timestamp):
            let now = timestamp.timeIntervalSinceReferenceDate
            let delta = now - lastTime
            let instantaneous = delta > 0 && delta < 0.5 ? (measured - lastAngle) / delta : 0
            velocity = delta < 0.5 ? velocity * 0.72 + instantaneous * 0.28 : 0
            if abs(angle - measured) >= 0.001 { angle = measured }
            lastSuccessfulUpdate = timestamp
            lastAngle = measured
            lastTime = now
            if !isAvailable {
                isAvailable = true
                statusText = "铰链传感器已连接"
            }
        case let .unavailable(message):
            isAvailable = false
            velocity = 0
            if statusText != message { statusText = message }
        }
    }

    deinit { reader?.stop() }
}

private enum HingeSample: Sendable {
    case angle(Double, Date)
    case unavailable(String)
}

/// Undocumented Apple HID sensor. Only observed whole-degree feature reports are
/// accepted; inferring units from each individual value can turn 1° into 100°.
struct HingeReportDecoder {
    static func decode(_ report: [UInt8], length: Int) -> Double? {
        guard length >= 3, report.count >= 3 else { return nil }
        let value = Double(UInt16(report[2]) << 8 | UInt16(report[1]))
        return (0...180).contains(value) ? value : nil
    }
}

/// All IOKit handles and mutable state are confined to queue.
private final class HingeHIDReader: @unchecked Sendable {
    private let queue = DispatchQueue(label: "studio.macduo.hinge", qos: .userInitiated)
    private let deliver: @Sendable (HingeSample) -> Void
    private var timer: DispatchSourceTimer?
    private var manager: IOHIDManager?
    private var device: IOHIDDevice?
    private var lastSuccess = Date.distantPast
    private var nextDiscovery = Date.distantPast
    private var report = [UInt8](repeating: 0, count: 8)
    private var announcedUnavailable = false
    private let options = IOOptionBits(kIOHIDOptionsTypeNone)

    init(deliver: @escaping @Sendable (HingeSample) -> Void) { self.deliver = deliver }

    func start() {
        queue.async { [self] in
            guard self.timer == nil else { return }
            let timer = DispatchSource.makeTimerSource(queue: self.queue)
            timer.schedule(deadline: .now(), repeating: 1.0 / 30, leeway: .milliseconds(3))
            timer.setEventHandler { [weak self] in self?.poll() }
            self.timer = timer
            timer.resume()
        }
    }

    func stop() {
        queue.async {
            self.timer?.cancel()
            self.timer = nil
            self.closeDevice()
            if let manager = self.manager {
                IOHIDManagerClose(manager, self.options)
                self.manager = nil
            }
        }
    }

    private func closeDevice() {
        if let device { IOHIDDeviceClose(device, options) }
        device = nil
    }

    private func discover() {
        nextDiscovery = Date().addingTimeInterval(3)
        if manager == nil {
            let candidate = IOHIDManagerCreate(kCFAllocatorDefault, options)
            guard IOHIDManagerOpen(candidate, options) == kIOReturnSuccess else { return }
            manager = candidate
        }
        guard let manager else { return }
        let matching: [String: Any] = [
            kIOHIDVendorIDKey as String: 0x05AC,
            kIOHIDDeviceUsagePageKey as String: 0x0020,
            kIOHIDDeviceUsageKey as String: 0x008A
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else { return }
        for candidate in devices {
            guard IOHIDDeviceOpen(candidate, options) == kIOReturnSuccess else { continue }
            var probe = [UInt8](repeating: 0, count: 8)
            var length = CFIndex(probe.count)
            let result = IOHIDDeviceGetReport(candidate, kIOHIDReportTypeFeature, 1, &probe, &length)
            guard result == kIOReturnSuccess, HingeReportDecoder.decode(probe, length: length) != nil else {
                IOHIDDeviceClose(candidate, options)
                continue
            }
            device = candidate
            lastSuccess = Date()
            announcedUnavailable = false
            return
        }
    }

    private func poll() {
        let now = Date()
        if device == nil && now >= nextDiscovery { discover() }
        guard let device else {
            if !announcedUnavailable {
                deliver(.unavailable("未检测到可读铰链 · 可用内置演示，后台会重试"))
                announcedUnavailable = true
            }
            return
        }
        var length = CFIndex(report.count)
        let result = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, 1, &report, &length)
        if result == kIOReturnSuccess, let measured = HingeReportDecoder.decode(report, length: length) {
            lastSuccess = Date()
            deliver(.angle(measured, lastSuccess))
        } else if now.timeIntervalSince(lastSuccess) > 1.5 {
            closeDevice()
            nextDiscovery = now.addingTimeInterval(1)
            deliver(.unavailable("铰链数据中断，正在重新连接…"))
            announcedUnavailable = true
        }
    }
}
