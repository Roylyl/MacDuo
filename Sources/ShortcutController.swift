import AppKit
import Carbon

/// Event IDs belong to individual registrations, not permanent actions. Keeping
/// this state independent of Carbon makes delayed-event handling deterministic.
struct ShortcutEventRegistry {
    private var nextEventID: UInt32 = 0
    private var actionsByEventID: [UInt32: ShortcutAction] = [:]
    private var heldActions = Set<ShortcutAction>()

    mutating func reserveEventID() -> UInt32 {
        repeat { nextEventID &+= 1 } while nextEventID == 0 || actionsByEventID[nextEventID] != nil
        return nextEventID
    }

    mutating func activate(_ action: ShortcutAction, eventID: UInt32) {
        actionsByEventID[eventID] = action
    }

    mutating func consume(eventID: UInt32, pressed: Bool) -> ShortcutAction? {
        guard let action = actionsByEventID[eventID] else { return nil }
        if pressed {
            guard heldActions.insert(action).inserted else { return nil }
        } else {
            guard heldActions.remove(action) != nil else { return nil }
        }
        return action
    }

    mutating func invalidateRegistrations() {
        actionsByEventID.removeAll()
    }

    mutating func releaseHeldActions() -> Set<ShortcutAction> {
        let held = heldActions
        heldActions.removeAll()
        return held
    }
}

/// Registers only user-assigned keys. Carbon reports only registered combinations;
/// no global keyboard monitor or accessibility permission is used.
@MainActor
final class ShortcutController {
    private var eventHandler: EventHandlerRef?
    private var registrations: [EventHotKeyRef] = []
    private var eventRegistry = ShortcutEventRegistry()
    private let perform: (ShortcutAction, Bool) -> Void
    private var observers: [NSObjectProtocol] = []

    init(perform: @escaping (ShortcutAction, Bool) -> Void) {
        self.perform = perform
        var events = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        let result = InstallEventHandler(GetApplicationEventTarget(), { _, event, pointer in
            guard let event, let pointer else { return OSStatus(eventNotHandledErr) }
            var id = EventHotKeyID()
            guard GetEventParameter(event, EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size,
                nil, &id) == noErr, id.signature == 0x4D44554F else { return OSStatus(eventNotHandledErr) }
            let controller = Unmanaged<ShortcutController>.fromOpaque(pointer).takeUnretainedValue()
            let pressed = GetEventKind(event) == UInt32(kEventHotKeyPressed)
            MainActor.assumeIsolated { controller.handle(eventID: id.id, pressed: pressed) }
            return noErr
        }, events.count, &events, pointer, &eventHandler)
        if result != noErr { eventHandler = nil }
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification,
                     NSWorkspace.sessionDidResignActiveNotification] {
            observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.releaseHeldActions() }
            })
        }
    }

    func configure(_ preferences: ShortcutPreferences, suspended: Bool) -> [String:String] {
        unregister()
        guard !suspended else { return [:] }
        var errors: [String:String] = [:]
        for action in ShortcutAction.allCases {
            guard let binding = preferences.binding(for: action) else { continue }
            guard eventHandler != nil, binding.isValid else {
                errors[action.rawValue] = "快捷键服务不可用；仍可使用窗口和菜单按钮。"
                continue
            }
            var reference: EventHotKeyRef?
            let eventID = eventRegistry.reserveEventID()
            let result = RegisterEventHotKey(binding.keyCode, binding.modifiers,
                EventHotKeyID(signature: 0x4D44554F, id: eventID),
                GetApplicationEventTarget(), 0, &reference)
            if result == noErr, let reference {
                registrations.append(reference)
                eventRegistry.activate(action, eventID: eventID)
            }
            else { errors[action.rawValue] = "此组合被系统或其他应用占用，请换一组。" }
        }
        return errors
    }

    private func handle(eventID: UInt32, pressed: Bool) {
        guard let action = eventRegistry.consume(eventID: eventID, pressed: pressed) else { return }
        perform(action, pressed)
    }

    private func releaseHeldActions() {
        let held = eventRegistry.releaseHeldActions()
        for action in held { perform(action, false) }
    }

    private func unregister() {
        // Invalidate before unregistering or invoking callbacks. Already queued
        // Carbon events cannot act during recording or after a binding changes.
        eventRegistry.invalidateRegistrations()
        let previousRegistrations = registrations
        registrations.removeAll()
        for reference in previousRegistrations { UnregisterEventHotKey(reference) }
        releaseHeldActions()
    }

    func stop() {
        unregister()
        if let eventHandler { RemoveEventHandler(eventHandler) }
        eventHandler = nil
        for observer in observers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        observers.removeAll()
    }
}
