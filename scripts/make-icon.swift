// Draws the app icon into an .iconset directory for `iconutil`.
// Usage: swiftc scripts/make-icon.swift -o make-icon && ./make-icon AppIcon.iconset
import AppKit

/// Renders the icon at exactly `px` x `px` pixels, whatever the screen's scale factor.
func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    defer { NSGraphicsContext.restoreGraphicsState() }

    let s = CGFloat(px)
    let inset = s * 0.06
    let rect = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let bg = NSBezierPath(roundedRect: rect, xRadius: s * 0.22, yRadius: s * 0.22)
    NSGradient(starting: NSColor(red: 0.20, green: 0.55, blue: 1.0, alpha: 1),
               ending: NSColor(red: 0.30, green: 0.15, blue: 0.80, alpha: 1))!.draw(in: bg, angle: -60)

    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: s * 0.52, weight: .heavy),
        .foregroundColor: NSColor.white]
    let str = NSAttributedString(string: "v6", attributes: attrs)
    let sz = str.size()
    str.draw(at: NSPoint(x: (s - sz.width) / 2, y: s * 0.40))

    // toggle switch
    let tw = s * 0.46, th = s * 0.17
    let track = NSRect(x: (s - tw) / 2, y: s * 0.20, width: tw, height: th)
    NSColor.white.withAlphaComponent(0.35).setFill()
    NSBezierPath(roundedRect: track, xRadius: th / 2, yRadius: th / 2).fill()
    let k = th * 0.78
    let knob = NSRect(x: track.maxX - k - th * 0.11, y: track.minY + (th - k) / 2, width: k, height: k)
    NSColor.white.setFill()
    NSBezierPath(ovalIn: knob).fill()

    NSGraphicsContext.current?.flushGraphics()
    return rep.representation(using: .png, properties: [:])!
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("usage: make-icon <output.iconset>\n".data(using: .utf8)!)
    exit(64)
}
let dir = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
// iconutil expects icon_<size>x<size>.png and icon_<size>x<size>@2x.png for each size.
for size in [16, 32, 128, 256, 512] {
    try render(size).write(to: dir.appendingPathComponent("icon_\(size)x\(size).png"))
    try render(size * 2).write(to: dir.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
