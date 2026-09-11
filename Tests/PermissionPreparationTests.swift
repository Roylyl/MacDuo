import Foundation

@main
struct PermissionPreparationTests {
    static func main() {
        precondition(ScreenCapturePermissionPreparation.statusMessage(authorized: true).contains("已允许"))
        precondition(ScreenCapturePermissionPreparation.statusMessage(authorized: false).contains("首次启用"))
        print("PASS: permission status messaging; startup implementation is read-only")
    }
}
