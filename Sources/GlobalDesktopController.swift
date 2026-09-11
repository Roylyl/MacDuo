import AppKit
import ScreenCaptureKit
import CoreMedia
import Combine

// Capture and rendering stay on this Mac. Nothing is recorded or uploaded.
@MainActor
final class GlobalDesktopController: NSObject, @preconcurrency SCStreamOutput, SCStreamDelegate {
    private let model: AppModel
    private weak var setupWindow: NSWindow?
    private var overlay: NSPanel?
    private var renderer: GlassMetalView?
    private var stream: SCStream?
    private var timer: Timer?
    private var statusItem: NSStatusItem!
    private var statusLine: NSMenuItem!
    private var angleSubscription: AnyCancellable?
    private var observers: [NSObjectProtocol] = []
    private var generation = 0
    private var starting = false
    private var resumeWanted = false
    private var sleepReasons = Set<String>()
    private var recoveryTimer: Timer?
    private var nextRecoveryAttempt = Date.distantPast
    private var recovery = CaptureRecoveryPolicy()
    private var motion = MotionVisibilityPolicy()
    private var captureGate = CaptureFrameGate()
    private var presentationGate = CaptureFrameGate()
    private var requestedVisible = false
    private var temporaryOriginalActive = false
    private var temporaryOriginalShown = false
    private var lastDelivery = Date.distantPast
    private var frameCount = 0
    private var uploadedFrameCount = 0
    private var statusTick = 0
    private var latestPixelBuffer: CVPixelBuffer?
    private var capturedDisplayID: CGDirectDisplayID?
    private var captureSize = CGSize.zero
    private var captureApplication: SCRunningApplication?
    private var appliedProfile: CaptureProfile?
    private var updatingProfile = false

    private struct CaptureProfile: Equatable {
        let width: Int
        let height: Int
        let fps: Int
    }

    init(model: AppModel, setupWindow: NSWindow) {
        self.model = model
        self.setupWindow = setupWindow
        super.init()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = nil
        statusItem.button?.imagePosition = .noImage
        statusItem.button?.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        statusItem.button?.toolTip = "MacDuo · 点击角度打开菜单"
        statusItem.button?.setAccessibilityLabel("MacDuo，当前铰链角度")
        angleSubscription = MenuBarAngle.titles(
            angle: model.sensor.$angle.eraseToAnyPublisher(),
            availability: model.sensor.$isAvailable.eraseToAnyPublisher()
        ).sink { [weak self] title in
            self?.statusItem.button?.title = title
            self?.statusItem.button?.setAccessibilityValue(title)
        }
        let menu = NSMenu()
        statusLine = NSMenuItem(title: "尚未启动", action: nil, keyEquivalent: "")
        menu.addItem(statusLine)
        menu.addItem(.separator())
        for (title, action) in [
            ("开启 / 停止实时效果", #selector(toggle)),
            ("保存当前展开终点", #selector(calibrate)),
            ("停止并打开主界面", #selector(showSetup)),
            ("退出 MacDuo", #selector(quit))
        ] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }
        statusItem.menu = menu
        for (name, key) in [(NSWorkspace.willSleepNotification, "system"),
                            (NSWorkspace.screensDidSleepNotification, "display"),
                            (NSWorkspace.sessionDidResignActiveNotification, "session")] {
            observers.append(NSWorkspace.shared.notificationCenter.addObserver(
                forName: name, object: nil, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated {
                        self?.sleepReasons.insert(key)
                        self?.suspend(reason: "已暂停并恢复原桌面，唤醒后自动继续")
                    }
                })
        }
        for (name, key) in [(NSWorkspace.didWakeNotification, "system"),
                            (NSWorkspace.screensDidWakeNotification, "display"),
                            (NSWorkspace.sessionDidBecomeActiveNotification, "session")] {
            observers.append(NSWorkspace.shared.notificationCenter.addObserver(
                forName: name, object: nil, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated {
                        self?.sleepReasons.remove(key)
                        self?.recoverIfReady()
                    }
                })
        }
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                // A Space change invalidates the old desktop, just like a wake.
                self?.nextRecoveryAttempt = Date().addingTimeInterval(0.2)
                self?.suspend(reason: "桌面空间已切换，正在获取新画面")
            }
        })
    }

    @objc func toggle() {
        if stream != nil || starting || resumeWanted { stop(reason: "实时效果已停止") }
        else { start() }
    }

    @objc func calibrate() {
        model.saveRealOpenAngle()
    }

    /// Called only by a shortcut explicitly assigned by the user. No modifier key
    /// or key combination has built-in meaning in the desktop runtime.
    func setTemporaryOriginal(active: Bool) {
        guard temporaryOriginalActive != active else { return }
        temporaryOriginalActive = active
        update()
    }

    @objc func showSetup() {
        stop(reason: "实时效果已停止")
        restoreSetupWindow()
    }

    private func restoreSetupWindow() {
        model.returnToSetup()
        NSApp.presentationOptions = []
        if NSApp.isHidden { NSApp.unhide(nil) }
        if let window = setupWindow {
            // Screenshot testing may have expanded the same normal window.
            if let screen = window.screen ?? NSScreen.main {
                let available = screen.visibleFrame
                let size = NSSize(width: min(1040, available.width), height: min(800, available.height))
                window.setFrame(NSRect(x: available.midX - size.width / 2,
                                       y: available.midY - size.height / 2,
                                       width: size.width, height: size.height), display: true)
            }
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        stop(reason: "已停止")
        NSApp.terminate(nil)
    }

    func start(automatically: Bool = false) {
        guard !model.permissionsPreparing, !starting, stream == nil else { return }
        guard model.sensor.isAvailable else {
            setStatus("没有可用的铰链传感器；可导入截图手动调整效果")
            return
        }
        // Only an explicit click/shortcut may enter the permission request path.
        if automatically && !CGPreflightScreenCaptureAccess() {
            stop(reason: "屏幕录制权限不可用，请在设置中手动重新启用")
            return
        }
        if !automatically {
            recovery.reset()
            nextRecoveryAttempt = .distantPast
        }
        resumeWanted = true
        guard sleepReasons.isEmpty else {
            suspend(reason: "等待屏幕唤醒后自动恢复")
            return
        }
        starting = true
        generation += 1
        let token = generation
        model.globalRunning = true
        setStatus(CGPreflightScreenCaptureAccess() ? "正在准备实时桌面…" : "请允许屏幕录制，以便在本机显示实时桌面")
        Task { @MainActor in
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                guard token == generation else { return }
                guard let display = content.displays.first(where: { CGDisplayIsBuiltin($0.displayID) != 0 }),
                      let screen = NSScreen.screens.first(where: {
                          ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == display.displayID
                      }) else { throw GlobalError.noInternalDisplay }
                let ownPID = ProcessInfo.processInfo.processIdentifier
                if let application = content.applications.first(where: { $0.processID == ownPID }) {
                    captureApplication = application
                }
                guard let application = captureApplication, application.processID == ownPID else {
                    throw GlobalError.cannotExcludeSelf
                }
                let filter = SCContentFilter(display: display, excludingApplications: [application], exceptingWindows: [])
                captureSize = screen.frame.size
                let profile = desiredProfile(active: model.settings.mode == .continuous)
                let renderer = self.renderer ?? GlassMetalView()
                guard renderer.isOperational else { throw GlobalError.noGPU }
                renderer.renderingEnabled = false
                renderer.resetLiveFrame()
                let overlay = self.overlay ?? NSPanel(contentRect: screen.frame,
                    styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
                overlay.hidesOnDeactivate = false
                overlay.becomesKeyOnlyIfNeeded = true
                overlay.isReleasedWhenClosed = false
                overlay.backgroundColor = .black
                overlay.hasShadow = false
                overlay.ignoresMouseEvents = true
                overlay.level = NSWindow.Level(rawValue: NSWindow.Level.popUpMenu.rawValue + 1)
                overlay.collectionBehavior = [.canJoinAllSpaces, .canJoinAllApplications,
                                              .fullScreenAuxiliary, .stationary, .ignoresCycle]
                overlay.contentView = renderer
                overlay.setFrame(screen.frame, display: false)
                overlay.alphaValue = 0
                overlay.orderOut(nil)
                self.renderer = renderer
                self.overlay = overlay
                capturedDisplayID = display.displayID
                let stream = SCStream(filter: filter, configuration: configuration(for: profile), delegate: self)
                try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
                self.stream = stream
                appliedProfile = profile
                updatingProfile = false
                latestPixelBuffer = nil
                frameCount = 0
                uploadedFrameCount = 0
                requestedVisible = false
                temporaryOriginalShown = false
                motion.reset()
                captureGate.begin(generation: token, now: Date().timeIntervalSinceReferenceDate)
                presentationGate.invalidate()
                lastDelivery = Date()
                setupWindow?.orderOut(nil)
                NSApp.presentationOptions = []
                startUpdateTimer()
                try await stream.startCapture()
                guard token == generation else {
                    try? await stream.stopCapture()
                    return
                }
                starting = false
                guard sleepReasons.isEmpty else {
                    suspend(reason: "等待屏幕唤醒后重新获取画面")
                    return
                }
                recoveryTimer?.invalidate()
                recoveryTimer = nil
                setStatus("实时桌面已启用 · 可从菜单栏停止效果或打开主界面")
                update()
            } catch {
                guard token == generation else { return }
                if automatically {
                    retryCapture(reason: "桌面捕获重连失败：\(error.localizedDescription)")
                } else {
                    let permissionHint = !(error is GlobalError) && !CGPreflightScreenCaptureAccess()
                        ? "。请检查屏幕录制权限后重试。" : ""
                    stop(reason: "无法启动：\(error.localizedDescription)\(permissionHint)")
                    restoreSetupWindow()
                }
            }
        }
    }

    /// All suspension paths reveal the real desktop before releasing the stream.
    /// Rebuilding after wake avoids reusing a texture from a different Space/session.
    private func suspend(reason: String) {
        guard resumeWanted || stream != nil || starting else { return }
        tearDownCapture()
        recovery.suspend()
        model.globalRunning = true
        setStatus(reason)
        if recoveryTimer == nil {
            let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.recoverIfReady() }
            }
            recoveryTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func retryCapture(reason: String) {
        guard let delay = recovery.nextDelay() else {
            stop(reason: "\(reason)；已恢复原桌面，请手动重新启用")
            return
        }
        nextRecoveryAttempt = Date().addingTimeInterval(delay)
        suspend(reason: "\(reason) · 正在重试 \(recovery.failureCount)/\(recovery.maxRetries)")
    }

    private func recoverIfReady() {
        guard resumeWanted, sleepReasons.isEmpty, !starting, Date() >= nextRecoveryAttempt else { return }
        let sensorIsFresh = model.sensor.isAvailable && Date().timeIntervalSince(model.sensor.lastSuccessfulUpdate) < 0.5
        guard !model.permissionsPreparing, sensorIsFresh,
              NSScreen.screens.contains(where: {
                  guard let id = ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value else { return false }
                  return CGDisplayIsBuiltin(id) != 0 && CGDisplayIsActive(id) != 0
              }) else { return }
        start(automatically: true)
    }

    private func startUpdateTimer() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func tearDownCapture() {
        overlay?.alphaValue = 0
        overlay?.orderOut(nil)
        renderer?.renderingEnabled = false
        renderer?.resetLiveFrame()
        generation += 1
        starting = false
        timer?.invalidate()
        timer = nil
        let oldStream = stream
        stream = nil
        if let oldStream { Task { try? await oldStream.stopCapture() } }
        captureGate.invalidate()
        presentationGate.invalidate()
        latestPixelBuffer = nil
        requestedVisible = false
        temporaryOriginalShown = false
        capturedDisplayID = nil
        appliedProfile = nil
        updatingProfile = false
        motion.reset()
    }

    func stop(reason: String, preserveIntent: Bool = false) {
        if preserveIntent {
            suspend(reason: reason)
            return
        }
        resumeWanted = false
        recoveryTimer?.invalidate()
        recoveryTimer = nil
        tearDownCapture()
        overlay = nil
        renderer = nil
        temporaryOriginalActive = false
        model.globalRunning = false
        setStatus(reason)
    }

    func screenConfigurationChanged() {
        guard let id = capturedDisplayID, let overlay else { return }
        let screen = NSScreen.screens.first {
            ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == id
        }
        // Menu/Dock visibility alone changes visibleFrame, not the captured full frame.
        if screen == nil || screen!.frame != overlay.frame {
            nextRecoveryAttempt = Date().addingTimeInterval(0.3)
            suspend(reason: "内建显示器已变化，正在重新连接")
        }
    }

    private func update() {
        guard sleepReasons.isEmpty, stream != nil, let renderer, let overlay else { return }
        let date = Date()
        let now = date.timeIntervalSinceReferenceDate
        if renderer.hasRenderingError {
            retryCapture(reason: "GPU 渲染中断，已恢复原桌面")
            return
        }
        if !model.sensor.isAvailable || date.timeIntervalSince(model.sensor.lastSuccessfulUpdate) > 2 {
            suspend(reason: "铰链数据已中断，恢复原桌面并等待传感器")
            return
        }
        if temporaryOriginalActive {
            if !temporaryOriginalShown {
                temporaryOriginalShown = true
                requestedVisible = false
                overlay.alphaValue = 0
                overlay.orderOut(nil)
                renderer.renderingEnabled = false
                renderer.resetLiveFrame()
                presentationGate.invalidate()
                setStatus("正在临时显示原桌面，松开自定快捷键后继续")
            }
            updateCaptureProfile(active: false)
            return
        } else if temporaryOriginalShown {
            temporaryOriginalShown = false
            motion.reset()
            setStatus("实时桌面已启用 · 可从菜单栏停止效果或打开主界面")
        }
        if captureGate.didTimeOut(now: now) || (requestedVisible && presentationGate.didTimeOut(now: now)) {
            // This must replace the failed stream; resuming the same stream can loop forever.
            retryCapture(reason: "等待新桌面画面超时")
            return
        }
        if captureGate.isReady { recovery.noteHealthy(now: now) }
        let settings = model.settings.validated
        let wantsMotion = motion.shouldShow(angle: model.sensor.angle, velocity: model.sensor.velocity,
            now: now, daily: settings.mode == .daily)
        let tilt = wantsMotion ? settings.tilt(for: model.sensor.angle, openAngle: model.openAngle) : 0
        if tilt > 0.05, !requestedVisible {
            requestedVisible = true
            renderer.resetLiveFrame()
            presentationGate.begin(generation: generation, now: now)
            if let latestPixelBuffer { upload(latestPixelBuffer) }
            // Give MTKView a drawable while remaining fully transparent to the user.
            overlay.alphaValue = 0
            overlay.orderFrontRegardless()
        }
        renderer.configureLive(tilt: tilt, frost: settings.frost, distance: settings.distance)
        if renderer.preferredFramesPerSecond != settings.quality.captureFPS {
            renderer.preferredFramesPerSecond = settings.quality.captureFPS
        }
        if tilt <= 0.05, renderer.settled {
            requestedVisible = false
            overlay.alphaValue = 0
            overlay.orderOut(nil)
            presentationGate.invalidate()
        }
        renderer.renderingEnabled = requestedVisible
        if requestedVisible, !renderer.readyForDisplay {
            // Texture-size changes or a failed GPU command also invalidate what
            // is safe to show, even if this stream already rendered earlier.
            overlay.alphaValue = 0
            if presentationGate.isReady {
                presentationGate.begin(generation: generation, now: now)
            }
        }
        if requestedVisible, renderer.readyForDisplay {
            presentationGate.markReady(generation: generation)
            overlay.alphaValue = 1
            if !overlay.isVisible { overlay.orderFrontRegardless() }
        }
        updateCaptureProfile(active: requestedVisible)
        statusTick += 1
        if statusTick % 30 == 0 {
            let state = overlay.isVisible && overlay.alphaValue > 0 ? "效果显示中" : "原桌面"
            let line = "\(state) · \(settings.mode.title) · 终点 \(Int(model.openAngle))°"
            statusLine.title = line
            model.diagnostics = "\(line)\n捕获：\(appliedProfile?.fps ?? 0) fps · \(appliedProfile?.width ?? 0) × \(appliedProfile?.height ?? 0)\n捕获帧：\(frameCount) · GPU 上传：\(uploadedFrameCount) · 渲染帧：\(renderer.renderedFrameCount)\n捕获代次：\(generation) · 最近回调：\(String(format: "%.1f", date.timeIntervalSince(lastDelivery))) 秒前\n恢复重试：\(recovery.failureCount)/\(recovery.maxRetries)"
        }
    }

    private func desiredProfile(active: Bool) -> CaptureProfile {
        let quality = model.settings.quality
        return CaptureProfile(width: max(64, Int(captureSize.width * quality.captureScale)),
                              height: max(64, Int(captureSize.height * quality.captureScale)),
                              fps: active ? quality.captureFPS : 2)
    }

    private func configuration(for profile: CaptureProfile) -> SCStreamConfiguration {
        let config = SCStreamConfiguration()
        config.width = profile.width
        config.height = profile.height
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.minimumFrameInterval = CMTime(value: 1, timescale: Int32(profile.fps))
        config.queueDepth = 3
        config.showsCursor = false
        config.capturesAudio = false
        return config
    }

    private func updateCaptureProfile(active: Bool) {
        guard !starting, !updatingProfile, let stream else { return }
        let profile = desiredProfile(active: active)
        guard profile != appliedProfile else { return }
        let token = generation
        updatingProfile = true
        Task { @MainActor in
            do {
                try await stream.updateConfiguration(configuration(for: profile))
                guard self.stream === stream, token == generation else { return }
                appliedProfile = profile
                updatingProfile = false
            } catch {
                guard self.stream === stream, token == generation else { return }
                updatingProfile = false
                retryCapture(reason: "无法更新桌面捕获：\(error.localizedDescription)")
            }
        }
    }

    private func upload(_ buffer: CVPixelBuffer) {
        if renderer?.receive(buffer) == true {
            uploadedFrameCount += 1
            captureGate.markReady(generation: generation)
        }
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard self.stream === stream, type == .screen, sampleBuffer.isValid, sleepReasons.isEmpty else { return }
        lastDelivery = Date()
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let raw = attachments.first?[.status] as? Int,
              let status = SCFrameStatus(rawValue: raw) else { return }
        if status == .blank || status == .suspended || status == .stopped {
            retryCapture(reason: "桌面捕获已暂停，正在等待有效画面")
            return
        }
        // Idle frames are legitimate for an unchanged desktop. Keep the latest CPU
        // buffer so resuming after idle is fresh without uploading every hidden frame.
        guard status == .complete || status == .started,
              let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        latestPixelBuffer = buffer
        frameCount += 1
        if requestedVisible || !captureGate.isReady { upload(buffer) }
    }

    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor in
            guard self.stream === stream else { return }
            retryCapture(reason: "捕获暂时中断：\(error.localizedDescription)")
        }
    }

    private func setStatus(_ message: String) {
        model.globalStatus = message
        statusLine?.title = message
        statusItem?.button?.toolTip = message
        model.diagnostics = "\(message)\n捕获代次：\(generation) · 恢复重试：\(recovery.failureCount)/\(recovery.maxRetries)"
    }

    enum GlobalError: LocalizedError {
        case noInternalDisplay, cannotExcludeSelf, noGPU
        var errorDescription: String? {
            switch self {
            case .noInternalDisplay: return "未找到内建显示屏"
            case .cannotExcludeSelf: return "无法排除自身窗口，为避免重复捕获已取消"
            case .noGPU: return "Metal 渲染器不可用"
            }
        }
    }
}
