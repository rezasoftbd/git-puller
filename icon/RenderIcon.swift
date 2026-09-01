// Renders the Git Puller icon to PNGs at every size macOS wants.
// Run: swift icon/RenderIcon.swift <output-dir>
import AppKit
import CoreGraphics

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon/GitPuller.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func drawIcon(size S: CGFloat, into ctx: CGContext) {
    let k = S / 1024.0                 // scale factor from the 1024pt design
    func s(_ v: CGFloat) -> CGFloat { v * k }

    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high

    let margin = s(100)
    let box = S - 2 * margin
    let radius = box * 0.2237
    let rect = CGRect(x: margin, y: margin, width: box, height: box)
    let squircle = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

    // Drop shadow under the tile.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s(12)), blur: s(30),
                  color: NSColor.black.withAlphaComponent(0.28).cgColor)
    ctx.addPath(squircle)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Base gradient (top -> bottom). Core Graphics y is flipped, so the
    // "top" colour sits at the higher y value.
    ctx.saveGState()
    ctx.addPath(squircle)
    ctx.clip()

    let space = CGColorSpaceCreateDeviceRGB()
    let base = CGGradient(colorsSpace: space, colors: [
        NSColor(srgbRed: 0.976, green: 0.451, blue: 0.384, alpha: 1).cgColor,  // #F97362
        NSColor(srgbRed: 0.941, green: 0.318, blue: 0.200, alpha: 1).cgColor,  // #F05133
        NSColor(srgbRed: 0.824, green: 0.216, blue: 0.102, alpha: 1).cgColor,  // #D2371A
    ] as CFArray, locations: [0.0, 0.52, 1.0])!
    ctx.drawLinearGradient(base,
                           start: CGPoint(x: 0, y: rect.maxY),
                           end: CGPoint(x: 0, y: rect.minY),
                           options: [])

    // Glossy sheen across the top half.
    let sheen = CGGradient(colorsSpace: space, colors: [
        NSColor.white.withAlphaComponent(0.26).cgColor,
        NSColor.white.withAlphaComponent(0.05).cgColor,
        NSColor.white.withAlphaComponent(0.0).cgColor,
    ] as CFArray, locations: [0.0, 0.46, 1.0])!
    ctx.drawLinearGradient(sheen,
                           start: CGPoint(x: 0, y: rect.maxY),
                           end: CGPoint(x: 0, y: rect.minY),
                           options: [])
    ctx.restoreGState()

    // Inner hairline for definition.
    ctx.saveGState()
    let inner = rect.insetBy(dx: s(2), dy: s(2))
    ctx.addPath(CGPath(roundedRect: inner, cornerWidth: radius - s(2), cornerHeight: radius - s(2), transform: nil))
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.30).cgColor)
    ctx.setLineWidth(max(s(3), 0.5))
    ctx.strokePath()
    ctx.restoreGState()

    // --- Glyph. Designed in a top-left origin space, so flip y here. ---
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: s(x), y: S - s(y)) }

    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(s(46))

    // Branch trunk, left side, with two commits.
    ctx.move(to: p(336, 318))
    ctx.addLine(to: p(336, 706))
    ctx.strokePath()

    // Branch peeling off the trunk and rising into a second line on the right.
    ctx.move(to: p(336, 500))
    ctx.addCurve(to: p(672, 372), control1: p(510, 500), control2: p(672, 486))
    ctx.strokePath()

    // Commit nodes: white disc with a gradient-toned centre punched out.
    let nodeFill = NSColor(srgbRed: 0.941, green: 0.318, blue: 0.200, alpha: 1).cgColor
    func node(_ x: CGFloat, _ y: CGFloat) {
        let c = p(x, y)
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: c.x - s(56), y: c.y - s(56), width: s(112), height: s(112)))
        ctx.setFillColor(nodeFill)
        ctx.fillEllipse(in: CGRect(x: c.x - s(26), y: c.y - s(26), width: s(52), height: s(52)))
    }
    node(336, 318)
    node(336, 706)

    // Pull arrow: the branch line continues down and lands in an arrowhead.
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.move(to: p(672, 372))
    ctx.addLine(to: p(672, 664))
    ctx.strokePath()

    ctx.move(to: p(578, 570))
    ctx.addLine(to: p(672, 678))
    ctx.addLine(to: p(766, 570))
    ctx.strokePath()
}

func writePNG(size: Int, name: String) {
    let S = CGFloat(size)
    guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                              bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        fatalError("could not create context at \(size)")
    }
    drawIcon(size: S, into: ctx)
    guard let image = ctx.makeImage() else { fatalError("no image at \(size)") }
    let rep = NSBitmapImageRep(cgImage: image)
    rep.size = NSSize(width: size, height: size)
    guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("no png data") }
    let url = URL(fileURLWithPath: outDir).appendingPathComponent(name)
    try! data.write(to: url)
    print("  \(name)  (\(size)px)")
}

// The exact set `iconutil` expects.
let sizes: [(Int, String)] = [
    (16,   "icon_16x16.png"),
    (32,   "icon_16x16@2x.png"),
    (32,   "icon_32x32.png"),
    (64,   "icon_32x32@2x.png"),
    (128,  "icon_128x128.png"),
    (256,  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png"),
    (512,  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

print("Rendering iconset -> \(outDir)")
for (size, name) in sizes { writePNG(size: size, name: name) }
print("Done.")
