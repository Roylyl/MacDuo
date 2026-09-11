import AppKit
import Carbon

/// App actions deliberately have no preset keys. Recording is always explicit.
enum ShortcutAction: String, CaseIterable, Identifiable, Codable {
    case toggleGlobal, stopAndShowSettings, calibrate, temporaryOriginal
    case toggleControls, toggleOriginal, quit
    var id: String { rawValue }
    var title: String {
        switch self {
        case .toggleGlobal: return "开启 / 停止实时效果"
        case .stopAndShowSettings: return "停止并打开主界面"
        case .calibrate: return "保存真实展开终点"
        case .temporaryOriginal: return "按住显示原桌面"
        case .toggleControls: return "显示 / 隐藏演示控制"
        case .toggleOriginal: return "演示原图对比"
        case .quit: return "退出 MacDuo"
        }
    }
    var detail: String {
        switch self {
        case .temporaryOriginal: return "按下显示原桌面，松开后按当前模式继续。"
        case .toggleControls, .toggleOriginal: return "仅在演示与截图测试页生效。"
        case .calibrate: return "使用真实传感器角度，不使用模拟滑杆。"
        default: return "自定义后可在其他应用中使用。"
        }
    }
    var eventID: UInt32 { UInt32(Self.allCases.firstIndex(of: self)! + 1) }
    static func from(eventID: UInt32) -> Self? { allCases.first { $0.eventID == eventID } }
}

struct ShortcutBinding: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    var keyLabel: String
    static let allowedModifiers = UInt32(cmdKey | controlKey | optionKey | shiftKey)
    static let functionCodes: Set<UInt32> = [122,120,99,118,96,97,98,100,101,109,103,111,105,107,113,106,64,79,80,90]
    static let modifierCodes: Set<UInt32> = [54,55,56,57,58,59,60,61,62,63]

    var isValid: Bool {
        guard keyCode <= 127, !Self.modifierCodes.contains(keyCode), !keyLabel.isEmpty,
              keyLabel.count <= 24, modifiers & ~Self.allowedModifiers == 0 else { return false }
        return modifiers & UInt32(cmdKey | controlKey | optionKey) != 0 || Self.functionCodes.contains(keyCode)
    }
    func conflicts(with other: Self) -> Bool { keyCode == other.keyCode && modifiers == other.modifiers }
    var displayText: String {
        var prefix = ""
        for (flag, symbol) in [(controlKey,"⌃"), (optionKey,"⌥"), (shiftKey,"⇧"), (cmdKey,"⌘")] {
            if modifiers & UInt32(flag) != 0 { prefix += symbol }
        }
        return prefix + keyLabel
    }

    static func from(event: NSEvent) -> Self? {
        var modifiers: UInt32 = 0
        for (flag, value) in [(NSEvent.ModifierFlags.command,cmdKey), (.control,controlKey), (.option,optionKey), (.shift,shiftKey)] {
            if event.modifierFlags.contains(flag) { modifiers |= UInt32(value) }
        }
        let keyCode = UInt32(event.keyCode)
        let special: [UInt32:String] = [36:"↩",48:"Tab",49:"Space",51:"⌫",53:"Esc",76:"⌤",117:"⌦",123:"←",124:"→",125:"↓",126:"↑",115:"Home",119:"End",116:"Page Up",121:"Page Down"]
        let functionCodes: [UInt32] = [122,120,99,118,96,97,98,100,101,109,103,111,105,107,113,106,64,79,80,90]
        let label: String
        if let name = special[keyCode] { label = name }
        else if let i = functionCodes.firstIndex(of: keyCode) { label = "F\(i + 1)" }
        else { label = (event.charactersIgnoringModifiers ?? "").uppercased() }
        let result = Self(keyCode: keyCode, modifiers: modifiers, keyLabel: label)
        return result.isValid ? result : nil
    }
}

struct ShortcutPreferences: Codable, Equatable {
    var bindings: [String:ShortcutBinding] = [:]
    func binding(for action: ShortcutAction) -> ShortcutBinding? { bindings[action.rawValue] }
    func conflictingAction(for binding: ShortcutBinding, excluding action: ShortcutAction) -> ShortcutAction? {
        ShortcutAction.allCases.first { $0 != action && self.binding(for: $0)?.conflicts(with: binding) == true }
    }
    var validated: Self {
        var result = Self()
        for action in ShortcutAction.allCases {
            if let binding = binding(for: action), binding.isValid,
               result.conflictingAction(for: binding, excluding: action) == nil {
                result.bindings[action.rawValue] = binding
            }
        }
        return result
    }
    static let storageKey = "macduo.shortcuts.v1"
    static func load(from defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
        return decoded.validated
    }
    func save(to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(validated) { defaults.set(data,forKey:Self.storageKey) }
    }
}
