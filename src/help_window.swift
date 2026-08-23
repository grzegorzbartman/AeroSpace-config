// Floating liquid-glass panel that renders an HTML file (argv[1]).
// Used by bin/makaron-help to show the keyboard shortcut overlay.
// NSPanel + .nonactivatingPanel: receives keys without stealing app focus,
// and tiling window managers (AeroSpace) ignore non-standard panels.
// Closes on Esc, cmd-w, or clicking outside. One process = one panel;
// bin/makaron-help kills a running instance to implement toggle behavior.
import AppKit
import WebKit

final class HelpPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

// macOS traffic-light close button (red circle, x on hover)
final class CloseButton: NSView {
    var onClick: (() -> Void)?
    private var hovered = false { didSet { needsDisplay = true } }

    override init(frame: NSRect) {
        super.init(frame: frame)
        addTrackingArea(NSTrackingArea(rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self))
    }
    required init?(coder: NSCoder) { fatalError() }

    override func mouseEntered(with event: NSEvent) { hovered = true }
    override func mouseExited(with event: NSEvent) { hovered = false }
    override func mouseDown(with event: NSEvent) { onClick?() }

    override func draw(_ dirtyRect: NSRect) {
        let circle = NSBezierPath(ovalIn: bounds.insetBy(dx: 0.5, dy: 0.5))
        NSColor(srgbRed: 1.0, green: 0.373, blue: 0.341, alpha: 1).setFill() // #FF5F57
        circle.fill()
        NSColor.black.withAlphaComponent(0.2).setStroke()
        circle.lineWidth = 0.5
        circle.stroke()
        if hovered {
            let inset: CGFloat = bounds.width * 0.3
            let x = NSBezierPath()
            x.move(to: NSPoint(x: inset, y: inset))
            x.line(to: NSPoint(x: bounds.width - inset, y: bounds.height - inset))
            x.move(to: NSPoint(x: inset, y: bounds.height - inset))
            x.line(to: NSPoint(x: bounds.width - inset, y: inset))
            NSColor(white: 0.2, alpha: 0.85).setStroke()
            x.lineWidth = 1.1
            x.stroke()
        }
    }
}

final class Delegate: NSObject, NSApplicationDelegate {
    var panel: HelpPanel!
    var closing = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard CommandLine.arguments.count > 1 else { NSApp.terminate(nil); return }
        let url = URL(fileURLWithPath: CommandLine.arguments[1])

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let vf = screen.visibleFrame
        let w = min(CGFloat(920), vf.width - 60)
        let h = min(CGFloat(600), vf.height - 60)
        let rect = NSRect(x: vf.midX - w / 2, y: vf.midY - h / 2, width: w, height: h)

        panel = HelpPanel(contentRect: rect,
                          styleMask: [.borderless, .nonactivatingPanel],
                          backing: .buffered, defer: false)
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.transient, .ignoresCycle, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false

        let glass = NSVisualEffectView(frame: NSRect(origin: .zero, size: rect.size))
        glass.material = .hudWindow
        glass.state = .active
        glass.blendingMode = .behindWindow
        glass.wantsLayer = true
        glass.layer?.cornerRadius = 16
        glass.layer?.cornerCurve = .continuous
        glass.layer?.masksToBounds = true
        glass.layer?.borderWidth = 1
        glass.layer?.borderColor = NSColor.white.withAlphaComponent(0.22).cgColor
        glass.autoresizingMask = [.width, .height]
        // The behind-window blur is composited by the window server; a CALayer
        // mask does not clip it, so square corners peek out without maskImage.
        let radius: CGFloat = 16
        let maskEdge = radius * 2 + 1
        let mask = NSImage(size: NSSize(width: maskEdge, height: maskEdge), flipped: false) { r in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius).fill()
            return true
        }
        mask.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        mask.resizingMode = .stretch
        glass.maskImage = mask

        let web = WKWebView(frame: glass.bounds)
        web.setValue(false, forKey: "drawsBackground")
        web.autoresizingMask = [.width, .height]
        web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        glass.addSubview(web)

        let closeSize: CGFloat = 13
        let close = CloseButton(frame: NSRect(x: 13, y: rect.height - closeSize - 13,
                                              width: closeSize, height: closeSize))
        close.autoresizingMask = [.minYMargin]
        close.onClick = { [weak self] in self?.dismiss() }
        glass.addSubview(close)

        panel.contentView = glass

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            if e.keyCode == 53 { self?.dismiss(); return nil } // Esc
            if e.modifierFlags.contains(.command),
               e.charactersIgnoringModifiers == "w" { self?.dismiss(); return nil }
            return e
        }
        NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification,
                                               object: panel, queue: .main) { [weak self] _ in
            self?.dismiss()
        }

        // Fade + subtle rise in
        let start = rect.offsetBy(dx: 0, dy: -8)
        panel.setFrame(start, display: false)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.16
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
            panel.animator().setFrame(rect, display: true)
        }
    }

    func dismiss() {
        if closing { return }
        closing = true
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            panel.animator().alphaValue = 0
        }, completionHandler: { NSApp.terminate(nil) })
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = Delegate()
app.delegate = delegate
app.run()
