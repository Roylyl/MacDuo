import CoreGraphics

/// A read-only check. Requesting access is reserved for an explicit capture action.
/// In particular, application startup never runs tccutil or revokes an existing grant.
enum ScreenCapturePermissionPreparation {
    static func statusMessage(authorized: Bool) -> String {
        authorized ? "屏幕录制已允许，可以启用实时效果" : "首次启用时，请允许屏幕录制；画面仅在本机处理"
    }

    @MainActor static func prepare() async -> String? {
        statusMessage(authorized: CGPreflightScreenCaptureAccess())
    }
}
