import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor
final class AppModel: ObservableObject {
    enum Page {
        case setup
        case test
    }

    @Published var page: Page = .setup
    @Published var desktopImage: NSImage?
    @Published var importedFileName = ""
    @Published var useSensor = true
    @Published var simulatedAngle = 105.0
    @Published var controlsHidden = false
    @Published var showOriginal = false
    @Published var calibrationMessage = ""
    @Published var openAngle = 105.0 {
        didSet {
            let valid = openAngle.isFinite ? min(180, max(1, openAngle)) : 105
            if openAngle != valid { openAngle = valid }
            UserDefaults.standard.set(valid, forKey: "macduo.openAngle")
        }
    }
    @Published var globalStatus = "实时桌面模式需要屏幕录制权限"
    @Published var globalRunning = false
    @Published var permissionsPreparing = true
    @Published var settings = EffectSettings.load() {
        didSet { settings.save() }
    }
    @Published var diagnostics = "尚未启动捕获"
    @Published var shortcuts = ShortcutPreferences.load() {
        didSet { shortcuts.save() }
    }
    @Published var recordingShortcut: ShortcutAction?
    @Published var shortcutErrors: [String:String] = [:]
    var startGlobal: (() -> Void)?
    var stopGlobal: (() -> Void)?

    var currentAngle: Double { useSensor && sensor.isAvailable ? sensor.angle : simulatedAngle }

    func saveOpenAngle() {
        let value = currentAngle
        guard value.isFinite, value >= 1, value <= 180 else {
            calibrationMessage = "请先打开屏幕，再保存展开终点"
            controlsHidden = false
            return
        }
        openAngle = value
        UserDefaults.standard.set(value, forKey: "macduo.openAngle")
        calibrationMessage = "已保存展开终点"
    }

    func saveRealOpenAngle() {
        guard sensor.isAvailable, Date().timeIntervalSince(sensor.lastSuccessfulUpdate) < 1 else {
            calibrationMessage = "等待真实铰链数据后再校准"
            return
        }
        useSensor = true
        saveOpenAngle()
    }

    func resetSettings() {
        settings = EffectSettings()
        openAngle = 105
        simulatedAngle = 105
        calibrationMessage = "已恢复默认：105° · 观察距离 2.0× · 磨砂 15%"
    }

    @discardableResult func setShortcut(_ binding: ShortcutBinding?, for action: ShortcutAction) -> Bool {
        if let binding {
            guard binding.isValid else {
                shortcutErrors[action.rawValue] = "请使用包含 Command、Control 或 Option 的组合键，或功能键。"
                return false
            }
            if let conflict = shortcuts.conflictingAction(for: binding, excluding: action) {
                shortcutErrors[action.rawValue] = "此组合已用于“\(conflict.title)”，请换一组。"
                return false
            }
            shortcuts.bindings[action.rawValue] = binding
        } else { shortcuts.bindings.removeValue(forKey: action.rawValue) }
        shortcutErrors.removeValue(forKey: action.rawValue)
        recordingShortcut = nil
        return true
    }

    func clearAllShortcuts() {
        shortcuts = ShortcutPreferences()
        shortcutErrors = [:]
        recordingShortcut = nil
    }

    func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    func copyDiagnostics() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.1701"
        let text = "MacDuo \(version)\n\(ProcessInfo.processInfo.operatingSystemVersionString)\n传感器：\(sensor.statusText)\n角度：\(sensor.angle)° · 终点：\(openAngle)°\n模式：\(settings.mode.title) · 画质：\(settings.quality.title)\n\(diagnostics)\n\(globalStatus)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    let sensor = LidAngleSensor()

    init() {
        if let saved = UserDefaults.standard.object(forKey: "macduo.openAngle") as? Double,
           saved.isFinite, saved >= 1, saved <= 180 { openAngle = saved }
        sensor.start()
    }

    func importScreenshot() {
        let panel = NSOpenPanel()
        panel.title = "选择桌面截图"
        panel.message = "请选择一张完整的桌面截图，用作玻璃层下方的内容。"
        panel.prompt = "导入截图"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff]

        guard panel.runModal() == .OK,
              let url = panel.url,
              let image = NSImage(contentsOf: url)
        else { return }

        desktopImage = image
        importedFileName = url.lastPathComponent
    }

    func startTest() {
        guard desktopImage != nil else { return }
        controlsHidden = false
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            page = .test
        }
    }

    /// Synthetic artwork drawn locally; no screen permission or third-party image required.
    func startDemo() {
        let size = NSSize(width: 1600, height: 1000)
        desktopImage = NSImage(size: size, flipped: false) { rect in
            NSGradient(colors: [NSColor(red: 0.06, green: 0.09, blue: 0.2, alpha: 1),
                                NSColor(red: 0.17, green: 0.25, blue: 0.42, alpha: 1)])?.draw(in: rect, angle: 40)
            func label(_ text: String, _ point: NSPoint, _ font: NSFont, _ color: NSColor) {
                (text as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
            }
            NSColor.white.withAlphaComponent(0.08).setFill()
            NSBezierPath(rect: NSRect(x: 0, y: 964, width: 1600, height: 36)).fill()
            label("MacDuo     文件     编辑     视图", NSPoint(x: 32, y: 974), .systemFont(ofSize: 14), .white)
            let cards: [(NSRect, String, String)] = [
                (NSRect(x: 95, y: 330, width: 870, height: 530), "让界面随屏幕一起展开。", "MACDUO  /  LOCAL DEMO"),
                (NSRect(x: 1010, y: 540, width: 475, height: 320), "空间，来自每一次开合。", "01  —  MOTION"),
                (NSRect(x: 1010, y: 165, width: 475, height: 335), "停稳，回到专注。", "02  —  EVERYDAY")
            ]
            for (frame, title, subtitle) in cards {
                NSColor.white.withAlphaComponent(0.09).setFill()
                let path = NSBezierPath(roundedRect: frame, xRadius: 22, yRadius: 22)
                path.fill()
                NSColor.white.withAlphaComponent(0.16).setStroke()
                path.lineWidth = 1
                path.stroke()
                label(subtitle, NSPoint(x: frame.minX + 30, y: frame.maxY - 60), .monospacedSystemFont(ofSize: 13, weight: .medium), .white.withAlphaComponent(0.55))
                label(title, NSPoint(x: frame.minX + 30, y: frame.maxY - 118), .systemFont(ofSize: frame.width > 500 ? 38 : 23, weight: .semibold), .white)
                for row in 0..<4 {
                    NSColor.white.withAlphaComponent(0.06).setFill()
                    NSBezierPath(roundedRect: NSRect(x: frame.minX + 30, y: frame.minY + 36 + CGFloat(row) * 29,
                                                     width: (frame.width - 60) * (row % 2 == 0 ? 0.8 : 0.55), height: 8), xRadius: 4, yRadius: 4).fill()
                }
            }
            label("这是本机绘制的演示图，不是你的桌面截图。", NSPoint(x: 100, y: 225), .systemFont(ofSize: 19), .white.withAlphaComponent(0.55))
            NSColor.white.withAlphaComponent(0.12).setFill()
            NSBezierPath(roundedRect: NSRect(x: 420, y: 22, width: 760, height: 78), xRadius: 22, yRadius: 22).fill()
            for index in 0..<10 {
                NSColor(calibratedHue: CGFloat(index) / 12, saturation: 0.48, brightness: 0.9, alpha: 0.9).setFill()
                NSBezierPath(roundedRect: NSRect(x: 443 + index * 72, y: 36, width: 50, height: 50), xRadius: 12, yRadius: 12).fill()
            }
            return true
        }
        importedFileName = "内置空间演示 · 本机生成"
        useSensor = false
        simulatedAngle = 105
        startTest()
    }

    func returnToSetup() {
        controlsHidden = false
        withAnimation(.easeInOut(duration: 0.3)) {
            page = .setup
        }
    }

    func toggleFullScreen() {
        guard let window = NSApp.keyWindow, let screen = window.screen else { return }
        window.setFrame(screen.frame, display: true)
    }
}
