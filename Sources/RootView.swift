import SwiftUI
import AppKit
import CoreGraphics

struct RootView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Group {
            switch model.page {
            case .setup:
                SetupView(model: model)
            case .test:
                TestView(model: model, sensor: model.sensor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.065, green: 0.075, blue: 0.10))
        .tint(Color(red: 0.59, green: 0.72, blue: 1))
        .preferredColorScheme(.dark)
    }
}

@MainActor
private final class SetupPresentation: ObservableObject {
    @Published var screenRecordingAllowed = false
    @Published var showAdvanced = false
    @Published var showDiagnostics = false
}

private struct SetupView: View {
    @ObservedObject var model: AppModel
    @ObservedObject private var sensor: LidAngleSensor
    @StateObject private var presentation = SetupPresentation()

    init(model: AppModel) {
        self.model = model
        self.sensor = model.sensor
    }

    private var readyToStart: Bool {
        sensor.isAvailable && !model.permissionsPreparing
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                heading
                launchCard
                HStack(alignment: .top, spacing: 16) {
                    sensorCard
                    permissionCard
                }
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Label("效果设置", systemImage: "slider.horizontal.3")
                                .font(.headline)
                            Spacer()
                            Text("自动保存 · 实时与演示共用")
                                .font(.caption).foregroundStyle(.secondary)
                            Button("恢复默认", action: model.resetSettings)
                                .controlSize(.small)
                        }
                        EffectControls(model: model, showMode: true)
                    }
                }
                SurfaceCard {
                    ShortcutSettingsView(model: model)
                }
                advancedTools
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                    Text("图像在本机处理。关闭窗口后继续在后台运行，可从菜单栏打开设置或退出。")
                    Spacer()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 1120)
            .padding(28)
            .frame(maxWidth: .infinity)
        }
        .onAppear { refreshPermission() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermission()
        }
        .onChange(of: model.globalStatus) { _, _ in refreshPermission() }
        .onChange(of: model.permissionsPreparing) { _, _ in refreshPermission() }
    }

    private var heading: some View {
        HStack(spacing: 14) {
            Image(nsImage: AppBrand.applicationIcon)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 58, height: 58)
                .accessibilityLabel("MacDuo")
            VStack(alignment: .leading, spacing: 4) {
                Text("MacDuo")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                Text("让桌面随屏幕展开，停下来继续专注。")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Label(model.globalRunning ? "实时效果已启用" : "准备就绪后即可开始",
                  systemImage: model.globalRunning ? "waveform.path" : "circle.dotted")
                .font(.caption)
                .foregroundStyle(model.globalRunning ? Color.green : Color.secondary)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.white.opacity(0.05), in: Capsule())
        }
    }

    private var launchCard: some View {
        SurfaceCard(accented: true) {
            VStack(alignment: .leading, spacing: 16) {
                Text("开合之间，桌面有了深度。")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text("实时捕获内建屏幕，让界面在玻璃后方轻轻展开。先将屏幕放在舒适的位置，保存展开终点，再慢慢开合体验。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    if model.globalRunning {
                        Button { model.stopGlobal?() } label: {
                            Label("停止实时效果", systemImage: "stop.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button { model.startGlobal?() } label: {
                            Label("启用实时桌面", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!readyToStart)
                    }
                    Spacer()
                    Text("快捷键可在下方自行设置")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .controlSize(.large)
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: model.permissionsPreparing ? "hourglass" : "info.circle")
                        .padding(.top, 1)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.globalStatus)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .font(.caption)
            }
        }
    }

    private var sensorCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("铰链与展开终点", systemImage: "angle")
                        .font(.headline)
                    Spacer()
                    Circle().fill(sensor.isAvailable ? Color.green : Color.orange)
                        .frame(width: 7, height: 7)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(sensor.isAvailable ? "\(Int(sensor.angle.rounded()))°" : "—")
                        .font(.system(size: 30, weight: .medium, design: .rounded))
                        .monospacedDigit()
                    Text("当前角度 · 终点 \(Int(model.openAngle.rounded()))°")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text(sensor.statusText)
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Text("展开终点").font(.subheadline)
                    Spacer()
                    TextField("角度", value: $model.openAngle,
                              format: .number.precision(.fractionLength(0)))
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 58)
                        .accessibilityLabel("展开终点角度")
                    Text("°").foregroundStyle(.secondary)
                    Stepper("展开终点", value: $model.openAngle, in: 1...180, step: 1)
                        .labelsHidden()
                        .fixedSize()
                }
                Button("将当前真实角度设为终点", action: model.saveRealOpenAngle)
                    .disabled(!sensor.isAvailable)
                if !model.calibrationMessage.isEmpty {
                    Text(model.calibrationMessage)
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !sensor.isAvailable {
                    Button("使用内置演示体验效果", action: model.startDemo)
                        .buttonStyle(.link)
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var permissionCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("屏幕录制权限", systemImage: "display")
                        .font(.headline)
                    Spacer()
                    Image(systemName: model.permissionsPreparing ? "hourglass" :
                            (presentation.screenRecordingAllowed ? "checkmark.circle.fill" : "lock.circle"))
                        .foregroundStyle(presentation.screenRecordingAllowed ? Color.green : Color.orange)
                }
                Text(model.permissionsPreparing ? "正在检查权限" :
                        (presentation.screenRecordingAllowed ? "已允许捕获桌面" : "等待允许屏幕录制"))
                    .font(.subheadline.weight(.medium))
                Text(presentation.screenRecordingAllowed
                     ? "只捕获内建屏幕的画面，用于实时玻璃效果。无需录制声音。"
                     : "点击上方启用时，系统会请求此权限。内置演示与截图测试无需屏幕录制权限。")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("打开系统权限设置", action: model.openScreenRecordingSettings)
                    .disabled(model.permissionsPreparing)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var advancedTools: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                DisclosureGroup("演示与截图测试", isExpanded: $presentation.showAdvanced) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("无需权限也能调试玻璃效果。使用手动角度滑杆，或在支持的 MacBook 上切换真实铰链。")
                            .font(.caption).foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            Button("打开内置演示", action: model.startDemo)
                            Button("导入截图…", action: model.importScreenshot)
                            Button("测试已导入截图", action: model.startTest)
                                .disabled(model.desktopImage == nil)
                        }
                        if !model.importedFileName.isEmpty {
                            Label(model.importedFileName, systemImage: "photo")
                                .font(.caption).foregroundStyle(.secondary)
                                .lineLimit(1).truncationMode(.middle)
                        }
                    }
                    .padding(.top, 12)
                }
                Divider()
                DisclosureGroup("运行诊断", isExpanded: $presentation.showDiagnostics) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(model.diagnostics)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Button("复制诊断信息", action: model.copyDiagnostics)
                    }
                    .padding(.top, 12)
                }
            }
            .font(.subheadline.weight(.medium))
        }
    }

    private func refreshPermission() {
        presentation.screenRecordingAllowed = CGPreflightScreenCaptureAccess()
    }
}

private struct EffectControls: View {
    @ObservedObject var model: AppModel
    var showMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if showMode {
                HStack(spacing: 16) {
                    Text("使用方式").frame(width: 76, alignment: .leading)
                    Picker("使用方式", selection: $model.settings.mode) {
                        Text(EffectMode.daily.title).tag(EffectMode.daily)
                        Text(EffectMode.continuous.title).tag(EffectMode.continuous)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                Text(model.settings.mode == .daily
                     ? "日常模式：只在真实开合动作期间显示效果；屏幕停稳后恢复清晰桌面。"
                     : "持续模式：倾斜时保留玻璃效果。画面中的按钮位置可能与鼠标实际点击位置不同，精确操作前请通过菜单栏或自行设置的快捷键恢复原桌面。")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ParameterSlider(title: "深度强度", value: $model.settings.strength,
                            range: 0.5...2, formatted: String(format: "%.1f×", model.settings.strength))
            ParameterSlider(title: "磨砂程度", value: $model.settings.frost,
                            range: 0...0.18, formatted: "\(Int((model.settings.frost / 0.18 * 100).rounded()))%")
            ParameterSlider(title: "观察距离", value: $model.settings.distance,
                            range: 1.4...4, formatted: String(format: "%.1f×", model.settings.distance))
            HStack(spacing: 16) {
                Text("画质").frame(width: 76, alignment: .leading)
                Picker("画质", selection: $model.settings.quality) {
                    Text(RenderQuality.economy.title).tag(RenderQuality.economy)
                    Text(RenderQuality.balanced.title).tag(RenderQuality.balanced)
                    Text(RenderQuality.high.title).tag(RenderQuality.high)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            if showMode {
                Text("观察距离以屏幕高度为单位。先正对屏幕、保持头部大致不动，再微调距离；更高画质会增加图形处理开销。")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .font(.subheadline)
    }
}

private struct ParameterSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let formatted: String

    var body: some View {
        HStack(spacing: 16) {
            Text(title).frame(width: 76, alignment: .leading)
            Slider(value: $value, in: range)
                .accessibilityLabel(title)
            Text(formatted)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 46, alignment: .trailing)
        }
    }
}

private struct TestView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var sensor: LidAngleSensor

    private var angle: Double {
        model.useSensor && sensor.isAvailable ? sensor.angle : model.simulatedAngle
    }

    var body: some View {
        VStack(spacing: 0) {
            if !model.controlsHidden {
                HStack {
                    Button(action: model.returnToSetup) {
                        Label("返回设置", systemImage: "chevron.left")
                    }
                    Spacer()
                    Text("截图与内置演示")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Button("隐藏控制") { model.controlsHidden = true }
                }
                .padding(16)
            }
            if let image = model.desktopImage {
                GeometryReader { geometry in
                    let aspect = image.size.width > 0 && image.size.height > 0
                        ? image.size.width / image.size.height : 1.6
                    let width = min(max(1, geometry.size.width), max(1, geometry.size.height) * aspect)
                    GlassSurface(image: image,
                                 tilt: model.showOriginal ? 0 : model.settings.tilt(for: angle, openAngle: model.openAngle),
                                 frost: model.settings.frost, distance: model.settings.distance)
                        .frame(width: width, height: width / aspect)
                        .clipped()
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black)
                .clipped()
                .overlay(alignment: .topTrailing) {
                    if model.controlsHidden {
                        Button {
                            model.controlsHidden = false
                        } label: {
                            Label("恢复控制", systemImage: "slider.horizontal.3")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(16)
                    }
                }
            }
            if !model.controlsHidden {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Circle().fill(model.useSensor && sensor.isAvailable ? Color.green : Color.orange)
                                .frame(width: 7, height: 7)
                            Text("\(Int(angle.rounded()))° / \(Int(model.openAngle.rounded()))°")
                                .monospacedDigit()
                            Spacer()
                            if sensor.isAvailable {
                                Toggle("真实铰链", isOn: $model.useSensor)
                                    .toggleStyle(.switch).controlSize(.small)
                            }
                            Toggle("原图对比", isOn: $model.showOriginal)
                                .toggleStyle(.checkbox)
                            Button("保存终点", action: model.saveOpenAngle)
                        }
                        if !model.useSensor || !sensor.isAvailable {
                            ParameterSlider(title: "模拟角度", value: $model.simulatedAngle,
                                            range: 0...180, formatted: "\(Int(model.simulatedAngle.rounded()))°")
                        }
                        EffectControls(model: model, showMode: false)
                        HStack {
                            Text(model.calibrationMessage.isEmpty
                                 ? "演示使用持续预览，方便比较效果；设置会同步用于实时桌面。"
                                 : model.calibrationMessage)
                        }
                        .font(.caption).foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    .padding(18)
                    .frame(maxWidth: 960)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: model.useSensor && sensor.isAvailable ? 258 : 292)
                .background(.white.opacity(0.025))
            }
        }
    }
}

private struct SurfaceCard<Content: View>: View {
    var accented = false
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(accented
                          ? Color(red: 0.12, green: 0.16, blue: 0.25)
                          : Color.white.opacity(0.035))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(accented ? 0.13 : 0.07), lineWidth: 1)
            }
    }
}
