import AppKit
import MetalKit
import CoreVideo

@main
struct RendererLifecycleTests {
    @MainActor static func main() {
        NSApplication.shared.setActivationPolicy(.prohibited)
        let view = GlassMetalView()
        precondition(view.isOperational)
        let window = NSWindow(contentRect: NSRect(x: 30, y: 30, width: 400, height: 300),
                              styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = view
        window.alphaValue = 0
        window.orderFrontRegardless()
        defer { window.orderOut(nil) }
        func pump(_ duration: TimeInterval) {
            let deadline = Date().addingTimeInterval(duration)
            while Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.01)) }
        }
        func waitForReady() {
            let deadline = Date().addingTimeInterval(3)
            while !view.readyForDisplay && Date() < deadline { pump(0.02) }
            precondition(view.readyForDisplay, "A transparent panel must render a first frame before being revealed")
        }
        let image = NSImage(size: NSSize(width: 320, height: 240), flipped: false) { rect in
            NSColor.systemBlue.setFill()
            rect.fill()
            return true
        }
        view.configure(image: image, tilt: 25, frost: 0.075, distance: 2.4)
        waitForReady()
        pump(0.5)
        precondition(view.isPaused)
        let stableCount = view.renderedFrameCount
        for _ in 0..<20 {
            view.configureLive(tilt: 25, frost: 0.075, distance: 2.4)
            pump(0.01)
        }
        precondition(view.renderedFrameCount == stableCount, "Unchanged angle/config must not wake settled drawing")
        func buffer(width: Int, height: Int) -> CVPixelBuffer {
            var result: CVPixelBuffer?
            let attributes = [kCVPixelBufferMetalCompatibilityKey: true,
                              kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary
            precondition(CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, attributes, &result) == kCVReturnSuccess)
            let resultBuffer = result!
            CVPixelBufferLockBaseAddress(resultBuffer, [])
            let bytes = CVPixelBufferGetBaseAddress(resultBuffer)!
            memset(bytes, 128, CVPixelBufferGetBytesPerRow(resultBuffer) * height)
            CVPixelBufferUnlockBaseAddress(resultBuffer, [])
            return resultBuffer
        }
        view.renderingEnabled = false
        view.resetLiveFrame()
        precondition(view.receive(buffer(width: 64, height: 48)))
        pump(0.2)
        precondition(!view.readyForDisplay && view.isPaused, "A hidden upload must not start rendering")
        view.configureLive(tilt: 20, frost: 0.075, distance: 2.4)
        view.renderingEnabled = true
        waitForReady()
        precondition(view.receive(buffer(width: 80, height: 60)))
        precondition(!view.readyForDisplay, "New texture dimensions require a fresh rendered frame")
        waitForReady()
        view.renderingEnabled = false
        precondition(view.receive(buffer(width: 80, height: 60)))
        view.resetLiveFrame()
        pump(0.2)
        precondition(!view.readyForDisplay, "Late GPU callbacks must not revive an invalidated frame")
        print("PASS: synthetic NSImage upload, transparent-panel first frame, settled draw suspension, hidden capture upload, resize and late GPU completion gating")
    }
}
