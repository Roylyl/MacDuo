import AppKit
import Carbon

/// Integration test for the real Carbon registration and installed event handler.
/// Events are dispatched only to this test process; no keyboard input or UI events
/// are synthesized, and no preferences are read or changed.
@main
struct ShortcutCarbonTests {
    @MainActor
    static func main() {
        _ = NSApplication.shared
        var delivered: [(ShortcutAction, Bool)] = []
        let controller = ShortcutController { action, pressed in
            delivered.append((action, pressed))
        }
        defer { controller.stop() }

        var preferences = ShortcutPreferences()
        preferences.bindings[ShortcutAction.temporaryOriginal.rawValue] = ShortcutBinding(
            keyCode: 90, modifiers: UInt32(cmdKey | controlKey | optionKey | shiftKey), keyLabel: "F20")
        let registrationErrors = controller.configure(preferences, suspended: false)
        require(registrationErrors.isEmpty, "Could not register the test-only four-modifier F20: \(registrationErrors)")

        // This isolated controller's first successful registration reserves ID 1.
        send(eventID: 1, pressed: true)
        expect(delivered, count: 1, lastPressed: true)
        send(eventID: 1, pressed: true)
        require(delivered.count == 1, "The actual handler must suppress repeated presses")
        send(eventID: 1, pressed: false)
        expect(delivered, count: 2, lastPressed: false)

        send(eventID: 1, pressed: true)
        expect(delivered, count: 3, lastPressed: true)
        require(controller.configure(preferences, suspended: true).isEmpty, "Recording should suspend registration")
        expect(delivered, count: 4, lastPressed: false)
        send(eventID: 1, pressed: true)
        send(eventID: 1, pressed: false)
        require(delivered.count == 4, "Queued old events must not invoke actions while recording")

        require(controller.configure(preferences, suspended: false).isEmpty, "Registration after recording should succeed")
        // Re-registering creates ID 2, so late events from ID 1 remain invalid.
        send(eventID: 1, pressed: true)
        require(delivered.count == 4, "Re-registering must not reactivate an old event ID")
        send(eventID: 2, pressed: true)
        expect(delivered, count: 5, lastPressed: true)
        send(eventID: 1, pressed: false)
        require(delivered.count == 5, "An old release must not release a newly registered shortcut")
        send(eventID: 2, pressed: false)
        expect(delivered, count: 6, lastPressed: false)

        require(controller.configure(ShortcutPreferences(), suspended: false).isEmpty, "Empty preferences should be valid")
        send(eventID: 2, pressed: true)
        send(eventID: 2, pressed: false)
        require(delivered.count == 6, "Clearing every binding must leave no active shortcuts")
        print("PASS: real Carbon registration → handler → pressed/released closure; recording, old IDs, clearing")
    }

    @MainActor
    private static func send(eventID: UInt32, pressed: Bool) {
        var event: EventRef?
        let kind = UInt32(pressed ? kEventHotKeyPressed : kEventHotKeyReleased)
        let createStatus = CreateEvent(nil, OSType(kEventClassKeyboard), kind,
                                      GetCurrentEventTime(), EventAttributes(kEventAttributeUserEvent), &event)
        require(createStatus == noErr && event != nil, "CreateEvent failed: \(createStatus)")
        guard let event else { return }
        defer { ReleaseEvent(event) }
        var identifier = EventHotKeyID(signature: 0x4D44554F, id: eventID)
        let parameterStatus = SetEventParameter(event, EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID), MemoryLayout<EventHotKeyID>.size, &identifier)
        require(parameterStatus == noErr, "SetEventParameter failed: \(parameterStatus)")
        let deliveryStatus = SendEventToEventTarget(event, GetApplicationEventTarget())
        require(deliveryStatus == noErr, "SendEventToEventTarget failed: \(deliveryStatus)")
    }

    private static func expect(_ events: [(ShortcutAction, Bool)], count: Int, lastPressed: Bool) {
        require(events.count == count, "Expected \(count) callbacks, got \(events.count)")
        require(events.last?.0 == .temporaryOriginal && events.last?.1 == lastPressed,
                "The callback had the wrong action or pressed/released value")
    }

    private static func require(_ condition: Bool, _ message: String) {
        guard condition else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(1)
        }
    }
}
