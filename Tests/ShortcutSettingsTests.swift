import AppKit
import Carbon
import Foundation

@main
struct ShortcutSettingsTests {
    @MainActor static func main() throws {
        let domain = "studio.macduo.tests.shortcuts.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defaults.removePersistentDomain(forName: domain)
        defer { defaults.removePersistentDomain(forName: domain) }

        let empty = ShortcutPreferences()
        expect(empty.bindings.isEmpty, "New installations must not enable any app shortcut")
        expect(ShortcutAction.allCases.allSatisfy { empty.binding(for: $0) == nil },
               "Every advertised action must begin unset")
        expect(ShortcutPreferences.load(from: defaults) == empty,
               "Missing stored preferences must load an empty configuration")

        expect(ShortcutBinding.from(event: key(0, characters: "a")) == nil,
               "A bare letter must remain available for normal typing")
        expect(ShortcutBinding.from(event: key(0, flags: .shift, characters: "A")) == nil,
               "Shift alone must not turn normal typing into a shortcut")
        expect(ShortcutBinding.from(event: key(49, characters: " ")) == nil,
               "Bare Space must not be accepted")
        expect(ShortcutBinding.from(event: key(53, characters: "\u{1b}")) == nil,
               "Bare Escape must not become a default or configured app action")
        expect(ShortcutBinding.from(event: key(55, flags: .command)) == nil,
               "A modifier key itself must not be recorded as the trigger key")

        let commandA = ShortcutBinding.from(event: key(0, flags: .command, characters: "a"))!
        expect(commandA.keyCode == 0 && commandA.modifiers == UInt32(cmdKey),
               "Recording must preserve the physical key and Carbon modifier mask")
        expect(commandA.displayText == "⌘A", "Recorded letters should have readable uppercase labels")
        for flag in [NSEvent.ModifierFlags.command, .control, .option] {
            expect(ShortcutBinding.from(event: key(0, flags: flag, characters: "a")) != nil,
                   "Each supported primary modifier must allow an ordinary key")
        }
        let allModifiers: NSEvent.ModifierFlags = [.command, .control, .option, .shift, .capsLock, .numericPad, .function]
        let combined = ShortcutBinding.from(event: key(0, flags: allModifiers, characters: "a"))!
        expect(combined.modifiers == UInt32(cmdKey | controlKey | optionKey | shiftKey),
               "Caps Lock and device flags must not leak into global registration modifiers")
        expect(combined.displayText == "⌃⌥⇧⌘A", "Modifier symbols should use a consistent display order")
        let commandSpace = ShortcutBinding.from(event: key(49, flags: .command, characters: " "))!
        expect(commandSpace.keyLabel == "Space", "Special keys need readable labels")

        let f1 = ShortcutBinding.from(event: key(122))!
        let f20 = ShortcutBinding.from(event: key(90))!
        expect(f1.isValid && f1.modifiers == 0 && f1.keyLabel == "F1",
               "F1 must be recordable without a modifier")
        expect(f20.isValid && f20.keyLabel == "F20", "The upper supported function key must decode correctly")
        expect(ShortcutBinding.from(event: key(122, flags: .shift))?.isValid == true,
               "Modified function keys must remain valid")

        let invalidBindings = [
            ShortcutBinding(keyCode: 0, modifiers: 0, keyLabel: "A"),
            ShortcutBinding(keyCode: 0, modifiers: UInt32(shiftKey), keyLabel: "A"),
            ShortcutBinding(keyCode: 128, modifiers: UInt32(cmdKey), keyLabel: "A"),
            ShortcutBinding(keyCode: 55, modifiers: UInt32(cmdKey), keyLabel: "Command"),
            ShortcutBinding(keyCode: 0, modifiers: UInt32(cmdKey) | (1 << 31), keyLabel: "A"),
            ShortcutBinding(keyCode: 0, modifiers: UInt32(cmdKey), keyLabel: ""),
            ShortcutBinding(keyCode: 0, modifiers: UInt32(cmdKey), keyLabel: String(repeating: "A", count: 25))
        ]
        expect(invalidBindings.allSatisfy { !$0.isValid },
               "Invalid persisted key codes, modifiers, and labels must be rejected")

        let relabeledA = ShortcutBinding(keyCode: commandA.keyCode, modifiers: commandA.modifiers, keyLabel: "Different label")
        expect(commandA.conflicts(with: relabeledA),
               "Conflicts must use the physical combination, independent of display text")
        let shiftedA = ShortcutBinding.from(event: key(0, flags: [.command, .shift], characters: "A"))!
        let commandB = ShortcutBinding.from(event: key(11, flags: .command, characters: "b"))!
        expect(!commandA.conflicts(with: shiftedA) && !commandA.conflicts(with: commandB),
               "A different modifier set or physical key must remain assignable")

        var preferences = ShortcutPreferences(bindings: [ShortcutAction.toggleGlobal.rawValue: commandA])
        expect(preferences.conflictingAction(for: commandA, excluding: .toggleGlobal) == nil,
               "Editing an action must allow keeping its current combination")
        expect(preferences.conflictingAction(for: relabeledA, excluding: .quit) == .toggleGlobal,
               "Assigning an existing combination to a different action must identify the conflict")
        preferences.bindings[ShortcutAction.toggleControls.rawValue] = f1
        preferences.save(to: defaults)
        let reloadedDefaults = UserDefaults(suiteName: domain)!
        expect(ShortcutPreferences.load(from: reloadedDefaults) == preferences,
               "Saved combinations must survive loading through a fresh defaults instance")
        preferences.bindings.removeValue(forKey: ShortcutAction.toggleGlobal.rawValue)
        preferences.save(to: defaults)
        let afterSingleClear = ShortcutPreferences.load(from: reloadedDefaults)
        expect(afterSingleClear.binding(for: .toggleGlobal) == nil && afterSingleClear.binding(for: .toggleControls) == f1,
               "Clearing one action must persist without erasing other actions")
        ShortcutPreferences().save(to: defaults)
        expect(ShortcutPreferences.load(from: reloadedDefaults).bindings.isEmpty,
               "Clearing every action must persist an empty configuration")

        let dirty = ShortcutPreferences(bindings: [
            ShortcutAction.toggleGlobal.rawValue: commandA,
            ShortcutAction.stopAndShowSettings.rawValue: relabeledA,
            ShortcutAction.calibrate.rawValue: invalidBindings[0],
            ShortcutAction.toggleControls.rawValue: f1,
            "removedOrUnknownAction": commandB
        ])
        let cleaned = dirty.validated
        expect(cleaned.binding(for: .toggleGlobal) == commandA && cleaned.binding(for: .toggleControls) == f1,
               "Validation must preserve the independent valid actions")
        expect(cleaned.binding(for: .stopAndShowSettings) == nil,
               "Duplicate combinations in saved data must never register twice")
        expect(cleaned.binding(for: .calibrate) == nil && cleaned.bindings["removedOrUnknownAction"] == nil,
               "Invalid combinations and unknown action names must be discarded")
        expect(cleaned.bindings.count == 2 && cleaned.validated == cleaned,
               "Repeated validation must be stable and preserve only valid known actions")
        defaults.set(try JSONEncoder().encode(dirty), forKey: ShortcutPreferences.storageKey)
        expect(ShortcutPreferences.load(from: defaults) == cleaned,
               "Loading externally changed preferences must apply the same validation")
        dirty.save(to: defaults)
        let stored = try JSONDecoder().decode(ShortcutPreferences.self,
                                             from: defaults.data(forKey: ShortcutPreferences.storageKey)!)
        expect(stored == cleaned, "Saving must not persist unknown, duplicate, or invalid bindings")
        defaults.set(Data("broken JSON".utf8), forKey: ShortcutPreferences.storageKey)
        expect(ShortcutPreferences.load(from: defaults) == empty,
               "Corrupt saved data must fall back to no active shortcuts")

        expect(Set(ShortcutAction.allCases.map(\.eventID)).count == ShortcutAction.allCases.count,
               "Registered actions must have distinct dispatch IDs")
        expect(ShortcutAction.allCases.allSatisfy { ShortcutAction.from(eventID: $0.eventID) == $0 },
               "Each registered ID must dispatch back to its original action")
        expect(ShortcutAction.from(eventID: 0) == nil && ShortcutAction.from(eventID: .max) == nil,
               "Unknown event IDs must never dispatch an action")

        print("PASS: shortcut defaults, recording conversion, validation, conflicts, isolated persistence, clearing, and dispatch IDs")
    }

    @MainActor private static func key(_ code: UInt16, flags: NSEvent.ModifierFlags = [], characters: String = "") -> NSEvent {
        NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0,
                        windowNumber: 0, context: nil, characters: characters,
                        charactersIgnoringModifiers: characters, isARepeat: false, keyCode: code)!
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        precondition(condition(), message)
    }
}
