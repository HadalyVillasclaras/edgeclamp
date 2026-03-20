import Cocoa
import CoreGraphics

let topPadding: CGFloat = 40
let bottomPadding: CGFloat = 40
let warpOffset: CGFloat = 18
let allowShiftBypass = true

final class EdgeClamp {
  private var eventTap: CFMachPort?
  private var lastWarpTime: CFAbsoluteTime = 0
  private let warpCooldown: CFAbsoluteTime = 0.006

  func start() {
    if !AXIsProcessTrusted() {
      print("EdgeClamp: Accessibility permission is required.")
      exit(1)
    }

    let mask: CGEventMask =
      (1 << CGEventType.mouseMoved.rawValue) |
      (1 << CGEventType.leftMouseDragged.rawValue) |
      (1 << CGEventType.rightMouseDragged.rawValue) |
      (1 << CGEventType.otherMouseDragged.rawValue)

    let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
      let instance = Unmanaged<EdgeClamp>.fromOpaque(userInfo!).takeUnretainedValue()
      return instance.handleEvent(proxy: proxy, type: type, event: event)
    }

    eventTap = CGEvent.tapCreate(
      tap: .cghidEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: mask,
      callback: callback,
      userInfo: UnsafeMutableRawPointer(Unmanaged<EdgeClamp>.passUnretained(self).toOpaque())
    )

    guard let tap = eventTap else {
      print("EdgeClamp: Failed to create event tap.")
      exit(2)
    }

    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)

    signal(SIGINT) { _ in
      if let tap = EdgeClamp.shared.eventTap {
        CGEvent.tapEnable(tap: tap, enable: false)
      }
      exit(0)
    }

    print("EdgeClamp is running. Top and bottom edges are clamped (\(Int(topPadding))px / \(Int(bottomPadding))px). Hold SHIFT to temporarily allow access.")
    CFRunLoopRun()
  }

  private func screenFrame(for point: CGPoint) -> CGRect {
    for screen in NSScreen.screens {
      if screen.frame.insetBy(dx: -2, dy: -2).contains(point) { return screen.frame }
    }
    return NSScreen.main?.frame ?? .zero
  }

  private func shouldProcessEventType(_ type: CGEventType) -> Bool {
    type == .mouseMoved ||
    type == .leftMouseDragged ||
    type == .rightMouseDragged ||
    type == .otherMouseDragged
  }

  private func handleEvent(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent
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

    let p = event.location
    let frame = screenFrame(for: p)
    if frame.height <= 0 {
      return Unmanaged.passUnretained(event)
    }

    let topZoneMaxY = frame.minY + topPadding
    let bottomZoneMinY = frame.maxY - bottomPadding

    let now = CFAbsoluteTimeGetCurrent()
    if now - lastWarpTime < warpCooldown {
      return Unmanaged.passUnretained(event)
    }

    if p.y <= topZoneMaxY {
      lastWarpTime = now
      let targetY = topZoneMaxY + warpOffset
      CGAssociateMouseAndMouseCursorPosition(0)
      CGWarpMouseCursorPosition(CGPoint(x: p.x, y: targetY))
      CGAssociateMouseAndMouseCursorPosition(1)
      return Unmanaged.passUnretained(event)
    }

    if p.y >= bottomZoneMinY {
      lastWarpTime = now
      let targetY = bottomZoneMinY - warpOffset
      CGAssociateMouseAndMouseCursorPosition(0)
      CGWarpMouseCursorPosition(CGPoint(x: p.x, y: targetY))
      CGAssociateMouseAndMouseCursorPosition(1)
      return Unmanaged.passUnretained(event)
    }

    return Unmanaged.passUnretained(event)
  }

  static let shared = EdgeClamp()
}

EdgeClamp.shared.start()