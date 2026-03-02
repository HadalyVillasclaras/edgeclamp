import Cocoa
import CoreGraphics

let topPadding: CGFloat = 40
let allowShiftBypass = true

var eventTap: CFMachPort?
var isWarping = false

func screenFrame(for point: CGPoint) -> CGRect {
  for screen in NSScreen.screens {
    if screen.frame.contains(point) { return screen.frame }
  }
  return NSScreen.main?.frame ?? .zero
}

func shouldProcessEventType(_ type: CGEventType) -> Bool {
  type == .mouseMoved ||
  type == .leftMouseDragged ||
  type == .rightMouseDragged ||
  type == .otherMouseDragged
}

func eventCallback(
  proxy: CGEventTapProxy,
  type: CGEventType,
  event: CGEvent,
  refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

  if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
    if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
    return Unmanaged.passUnretained(event)
  }

  if !shouldProcessEventType(type) {
    return Unmanaged.passUnretained(event)
  }

  if allowShiftBypass && event.flags.contains(.maskShift) {
    return Unmanaged.passUnretained(event)
  }

  if isWarping {
    isWarping = false
    return Unmanaged.passUnretained(event)
  }

  let p = event.location
  let frame = screenFrame(for: p)
  if frame.height <= 0 {
    return Unmanaged.passUnretained(event)
  }

  let topZoneMaxY = frame.minY + topPadding

  if p.y <= topZoneMaxY {
    isWarping = true
    CGAssociateMouseAndMouseCursorPosition(0)
    CGWarpMouseCursorPosition(CGPoint(x: p.x, y: topZoneMaxY + 2))
    CGAssociateMouseAndMouseCursorPosition(1)
  }

  return Unmanaged.passUnretained(event)
}

func buildEventMask() -> CGEventMask {
  (1 << CGEventType.mouseMoved.rawValue) |
  (1 << CGEventType.leftMouseDragged.rawValue) |
  (1 << CGEventType.rightMouseDragged.rawValue) |
  (1 << CGEventType.otherMouseDragged.rawValue)
}

func main() {
  if !AXIsProcessTrusted() {
    print("EdgeClamp: falta permiso de Accesibilidad")
    exit(1)
  }

  eventTap = CGEvent.tapCreate(
    tap: .cghidEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: buildEventMask(),
    callback: eventCallback,
    userInfo: nil
  )

  guard let tap = eventTap else {
    print("EdgeClamp: no se pudo crear el event tap")
    exit(2)
  }

  let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
  CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
  CGEvent.tapEnable(tap: tap, enable: true)

  print("EdgeClamp corriendo. Bloqueo arriba \(Int(topPadding))px. SHIFT para permitir la barra.")
  CFRunLoopRun()
}

main()