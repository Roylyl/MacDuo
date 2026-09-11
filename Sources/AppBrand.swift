import AppKit

/// Shared identity for the application assets and main window.
@MainActor
enum AppBrand {
    static let applicationIcon: NSImage = {
        if let url = Bundle.main.url(forResource: "MacDuo", withExtension: "png"),
           let image = NSImage(contentsOf: url) { return image }
        return fallbackIcon
    }()

    /// Used only when the packaged application artwork is unavailable.
    private static let fallbackIcon: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.saveGState()
            defer { context.restoreGState() }
            NSColor.black.setFill()
            let rear = NSBezierPath(roundedRect: NSRect(x: 1, y: 6, width: 11.5, height: 9),
                                    xRadius: 2, yRadius: 2)
            rear.append(NSBezierPath(roundedRect: NSRect(x: 2.5, y: 7.5, width: 8.5, height: 6),
                                     xRadius: 0.5, yRadius: 0.5))
            rear.windingRule = .evenOdd
            rear.fill()

            let front = NSBezierPath(roundedRect: NSRect(x: 4.5, y: 2.5, width: 12, height: 9),
                                     xRadius: 2, yRadius: 2)
            // Occlude the rear frame without baking a background into the template.
            context.setBlendMode(.clear)
            front.fill()
            context.setBlendMode(.normal)
            front.append(NSBezierPath(roundedRect: NSRect(x: 6, y: 4, width: 9, height: 6),
                                      xRadius: 0.5, yRadius: 0.5))
            front.windingRule = .evenOdd
            front.fill()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "MacDuo"
        return image
    }()
}
