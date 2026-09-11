import SwiftUI
import AppKit
import Combine

@main
struct MacDuoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var body: some Scene {
        Settings { EmptyView() }
            .commands {
                CommandGroup(replacing: .appSettings) {
                    Button("MacDuo 设置…") {
                        NotificationCenter.default.post(name: .macDuoOpenSettings, object: nil)
                    }
                }
                CommandGroup(replacing: .appTermination) {
                    Button("退出 MacDuo") { NSApp.terminate(nil) }
                }
                CommandGroup(replacing: .appVisibility) {
                    Button("隐藏 MacDuo") { NSApp.hide(nil) }
                    Button("显示全部") { NSApp.unhideAllApplications(nil) }
                }
            }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: DesktopWindow?
    private var model: AppModel?
    private var screenObserver: NSObjectProtocol?
    private var shortcutController: ShortcutController?
    private var shortcutSubscription: AnyCancellable?
    private var settingsObserver: NSObjectProtocol?
    private var globalController: GlobalDesktopController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let model = AppModel()
        self.model = model
        model.globalStatus = "正在检查屏幕录制权限…"
        Task { @MainActor in
            let message = await ScreenCapturePermissionPreparation.prepare()
            model.globalStatus = message ?? "启用实时桌面效果时，系统会请求屏幕录制权限"
            model.permissionsPreparing = false
        }
        let availableFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = NSSize(width: min(1040, availableFrame.width - 40),
                          height: min(800, availableFrame.height - 60))
        let window = DesktopWindow(contentRect: NSRect(origin: .zero, size: size),
                                   styleMask: [.titled, .closable, .resizable],
                                   backing: .buffered, defer: false)
        window.title = "MacDuo"
        window.subtitle = "实时桌面与效果设置"
        NSApp.applicationIconImage = AppBrand.applicationIcon
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = .windowBackgroundColor
        window.isOpaque = true
        window.hasShadow = true
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: 760, height: 600)
        window.contentView = NSHostingView(rootView: RootView(model: model))
        if !window.setFrameUsingName("MacDuo.SettingsWindow") { window.center() }
        window.setFrameAutosaveName("MacDuo.SettingsWindow")
        self.window = window
        let globalController = GlobalDesktopController(model: model, setupWindow: window)
        self.globalController = globalController
        model.startGlobal = { [weak globalController] in globalController?.start() }
        model.stopGlobal = { [weak globalController] in globalController?.stop(reason: "已停止实时效果") }
        NSApp.presentationOptions = []
        // Keep settings interactive without adding a Dock or app-switcher entry.
        NSApp.setActivationPolicy(.accessory)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        let shortcuts = ShortcutController { [weak self] action, pressed in
            self?.performShortcut(action, pressed: pressed)
        }
        shortcutController = shortcuts
        shortcutSubscription = model.$shortcuts.combineLatest(model.$recordingShortcut).sink { [weak model, weak shortcuts] preferences, recording in
            guard let model, let shortcuts else { return }
            let errors = shortcuts.configure(preferences, suspended: recording != nil)
            model.shortcutErrors = errors
        }
        settingsObserver = NotificationCenter.default.addObserver(forName: .macDuoOpenSettings,
            object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.globalController?.showSetup() }
            }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.globalController?.screenConfigurationChanged() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        shortcutSubscription?.cancel()
        shortcutController?.stop()
        if let settingsObserver { NotificationCenter.default.removeObserver(settingsObserver) }
        globalController?.stop(reason: "已退出")
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
    }

    @MainActor private func performShortcut(_ action: ShortcutAction, pressed: Bool) {
        guard let model else { return }
        if action == .temporaryOriginal {
            globalController?.setTemporaryOriginal(active: pressed)
            return
        }
        guard pressed else { return }
        switch action {
        case .toggleGlobal: globalController?.toggle()
        case .stopAndShowSettings: globalController?.showSetup()
        case .calibrate: globalController?.calibrate()
        case .toggleControls:
            if model.page == .test { model.controlsHidden.toggle() }
        case .toggleOriginal:
            if model.page == .test { model.showOriginal.toggle() }
        case .quit: NSApp.terminate(nil)
        case .temporaryOriginal: break
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        globalController?.showSetup()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

final class DesktopWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

extension Notification.Name {
    static let macDuoOpenSettings = Notification.Name("MacDuo.openSettings")
}
