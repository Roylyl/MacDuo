import SwiftUI
import AppKit

struct ShortcutSettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("快捷键", systemImage: "keyboard")
                    .font(.headline)
                Spacer()
                Button("全部清除") {
                    model.recordingShortcut = nil
                    model.clearAllShortcuts()
                }
                .controlSize(.small)
                .disabled(model.shortcuts.bindings.isEmpty)
            }
            Text("默认不设置快捷键。点击录制，再按下你要使用的组合键；每个操作都可以单独修改或清除。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(ShortcutAction.allCases) { action in
                shortcutRow(action)
                if action != ShortcutAction.allCases.last { Divider() }
            }
        }
        .onDisappear { model.recordingShortcut = nil }
    }

    private func shortcutRow(_ action: ShortcutAction) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(action.title)
                        .font(.subheadline.weight(.medium))
                    Text(action.detail)
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if model.recordingShortcut == action {
                    ShortcutRecorder(model: model, action: action)
                        .frame(width: 180, height: 30)
                        .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                        .overlay {
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(.tint, lineWidth: 1)
                                .allowsHitTesting(false)
                        }
                        .overlay {
                            Text("请按下组合键…")
                                .font(.subheadline)
                                .foregroundStyle(.tint)
                                .allowsHitTesting(false)
                        }
                    Button("取消") { model.recordingShortcut = nil }
                        .frame(width: 48)
                } else {
                    Text(model.shortcuts.binding(for: action)?.displayText ?? "未设置")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(model.shortcuts.binding(for: action) == nil ? Color.secondary : Color.primary)
                        .frame(width: 122, height: 30)
                        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 7))
                    Button(model.shortcuts.binding(for: action) == nil ? "录制" : "修改") {
                        model.shortcutErrors[action.rawValue] = nil
                        model.recordingShortcut = action
                    }
                    .frame(width: 48)
                    Button {
                        _ = model.setShortcut(nil, for: action)
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .help("清除\(action.title)快捷键")
                    .accessibilityLabel("清除\(action.title)快捷键")
                    .disabled(model.shortcuts.binding(for: action) == nil)
                }
            }
            if let error = model.shortcutErrors[action.rawValue], !error.isEmpty {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(.caption).foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if model.recordingShortcut == action {
                Text("组合键需包含 Command、Control 或 Option，也可使用功能键。按 Esc 取消本次录制。")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Receives keystrokes only as the focused recording control; no event monitor is installed.
private struct ShortcutRecorder: NSViewRepresentable {
    @ObservedObject var model: AppModel
    let action: ShortcutAction

    func makeNSView(context: Context) -> ShortcutRecordingView {
        let view = ShortcutRecordingView()
        configure(view)
        return view
    }

    func updateNSView(_ view: ShortcutRecordingView, context: Context) {
        configure(view)
        view.requestRecordingFocus()
    }

    private func configure(_ view: ShortcutRecordingView) {
        view.onKey = { event in
            guard model.recordingShortcut == action else { return }
            let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
            if event.keyCode == 53 && modifiers.isEmpty {
                model.recordingShortcut = nil
                return
            }
            guard let binding = ShortcutBinding.from(event: event) else {
                model.shortcutErrors[action.rawValue] = "请选择包含 Command、Control 或 Option 的组合键，或单独使用功能键。"
                return
            }
            if model.setShortcut(binding, for: action) {
                model.recordingShortcut = nil
            }
        }
        view.onCancel = {
            if model.recordingShortcut == action { model.recordingShortcut = nil }
        }
    }

    static func dismantleNSView(_ view: ShortcutRecordingView, coordinator: ()) {
        view.stopRecording()
    }
}

private final class ShortcutRecordingView: NSView {
    var onKey: ((NSEvent) -> Void)?
    var onCancel: (() -> Void)?
    private var windowObserver: NSObjectProtocol?
    private var recording = true
    private var focusRequested = false

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        removeWindowObserver()
        if let window {
            windowObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification, object: window, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.cancelRecording() }
            }
            requestRecordingFocus()
        } else if recording {
            cancelRecording()
        }
    }

    func requestRecordingFocus() {
        guard recording, !focusRequested else { return }
        focusRequested = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.focusRequested = false
            guard self.recording, let window = self.window, window.isKeyWindow else { return }
            if window.firstResponder !== self { window.makeFirstResponder(self) }
        }
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard recording, !event.isARepeat else { return }
        onKey?(event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard recording, window?.firstResponder === self else { return false }
        if !event.isARepeat { onKey?(event) }
        return true
    }

    override func resignFirstResponder() -> Bool {
        if recording {
            // Defer observable-state changes until AppKit has finished the focus transition.
            DispatchQueue.main.async { [weak self] in self?.cancelRecording() }
        }
        return super.resignFirstResponder()
    }

    func stopRecording() {
        recording = false
        removeWindowObserver()
        onKey = nil
        onCancel = nil
        if window?.firstResponder === self { window?.makeFirstResponder(nil) }
    }

    private func cancelRecording() {
        guard recording else { return }
        recording = false
        removeWindowObserver()
        let cancel = onCancel
        onKey = nil
        onCancel = nil
        cancel?()
    }

    private func removeWindowObserver() {
        if let windowObserver {
            NotificationCenter.default.removeObserver(windowObserver)
            self.windowObserver = nil
        }
    }

    deinit {
        if let windowObserver { NotificationCenter.default.removeObserver(windowObserver) }
    }
}
