import Foundation

@main
struct ShortcutLifecycleTests {
    static func main() {
        var registry = ShortcutEventRegistry()
        let oldID = registry.reserveEventID()
        registry.activate(.temporaryOriginal, eventID: oldID)
        assert(registry.consume(eventID: oldID, pressed: true) == .temporaryOriginal)
        assert(registry.consume(eventID: oldID, pressed: true) == nil,
               "Holding a key must not repeatedly invoke its action")

        // Beginning recording or changing preferences must reject queued events
        // immediately, while still producing the release needed to restore capture.
        registry.invalidateRegistrations()
        assert(registry.consume(eventID: oldID, pressed: true) == nil)
        assert(registry.consume(eventID: oldID, pressed: false) == nil)
        assert(registry.releaseHeldActions() == [.temporaryOriginal])
        assert(registry.releaseHeldActions().isEmpty)

        let newID = registry.reserveEventID()
        registry.activate(.temporaryOriginal, eventID: newID)
        assert(registry.consume(eventID: oldID, pressed: true) == nil,
               "Reassigning the same action must not revive its old event ID")
        assert(registry.consume(eventID: newID, pressed: true) == .temporaryOriginal)
        assert(registry.consume(eventID: oldID, pressed: false) == nil,
               "An old key release must not release the newly assigned key")
        assert(registry.consume(eventID: newID, pressed: false) == .temporaryOriginal)
        assert(registry.consume(eventID: newID, pressed: false) == nil)

        // Failed Carbon registration reserves an ID but never activates it.
        let failedID = registry.reserveEventID()
        assert(registry.consume(eventID: failedID, pressed: true) == nil)
        assert(registry.releaseHeldActions().isEmpty)

        // Sleep releases a held action even when the physical key-up is lost.
        assert(registry.consume(eventID: newID, pressed: true) == .temporaryOriginal)
        assert(registry.releaseHeldActions() == [.temporaryOriginal])
        assert(registry.consume(eventID: newID, pressed: false) == nil)
        assert(registry.consume(eventID: newID, pressed: true) == .temporaryOriginal,
               "The next press after wake must remain usable")
        assert(registry.consume(eventID: newID, pressed: false) == .temporaryOriginal)
        print("PASS: stale shortcut events, re-registration, failed registration, sleep release")
    }
}
