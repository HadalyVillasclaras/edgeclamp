import Cocoa
import CoreGraphics

final class EdgeClamp {
  private var eventTap: CFMachPort?
  private var lastWarpTime: CFAbsoluteTime = 0
  private let warpCooldown: CFAbsoluteTime = 0.006

  func start() {
    if !AXIsProcessTrusted() {
      print("EdgeClamp: Accessibility permission is required.")
      exit(1)
    }

    eventTap = makeEventTap()

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

  private func makeEventTap() -> CFMachPort? {
    let mask: CGEventMask =
      (1 << CGEventType.mouseMoved.rawValue) |
      (1 << CGEventType.leftMouseDragged.rawValue) |
      (1 << CGEventType.rightMouseDragged.rawValue) |
      (1 << CGEventType.otherMouseDragged.rawValue)

    let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
      let instance = Unmanaged<EdgeClamp>.fromOpaque(userInfo!).takeUnretainedValue()
      return instance.handleEvent(proxy: proxy, type: type, event: event)
    }

    return CGEvent.tapCreate(
      tap: .cghidEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: mask,
      callback: callback,
      userInfo: UnsafeMutableRawPointer(Unmanaged<EdgeClamp>.passUnretained(self).toOpaque())
    )
  }

  private func handleEvent(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent
  ) -> Unmanaged<CGEvent>? {

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
      if let tap = eventTap {
        CGEvent.tapEnable(tap: tap, enable: true)
      }
      return Unmanaged.passUnretained(event)
    }

    let shouldProcess =
      type == .mouseMoved ||
      type == .leftMouseDragged ||
      type == .rightMouseDragged ||
      type == .otherMouseDragged

    if !shouldProcess {
      return Unmanaged.passUnretained(event)
    }

    if allowShiftBypass && event.flags.contains(.maskShift) {
      return Unmanaged.passUnretained(event)
    }

    let point = event.location
    let frame = screenFrame(for: point)

    if frame.height <= 0 {
      return Unmanaged.passUnretained(event)
    }

    clampCursorIfNeeded(at: point, in: frame)

    return Unmanaged.passUnretained(event)
  }

  private func screenFrame(for point: CGPoint) -> CGRect {
    for screen in NSScreen.screens {
      if screen.frame.insetBy(dx: -2, dy: -2).contains(point) {
        return screen.frame
      }
    }
    return NSScreen.main?.frame ?? .zero
  }

  private func clampCursorIfNeeded(at point: CGPoint, in frame: CGRect) {
    let now = CFAbsoluteTimeGetCurrent()

    if now - lastWarpTime < warpCooldown {
      return
    }

    let topZoneMaxY = frame.minY + topPadding
    if point.y <= topZoneMaxY {
      lastWarpTime = now
      warpCursor(to: CGPoint(x: point.x, y: topZoneMaxY + warpOffset))
      return
    }

    let bottomZoneMinY = frame.maxY - bottomPadding
    if point.y >= bottomZoneMinY {
      lastWarpTime = now
      warpCursor(to: CGPoint(x: point.x, y: bottomZoneMinY - warpOffset))
    }
  }

  private func warpCursor(to point: CGPoint) {
    CGAssociateMouseAndMouseCursorPosition(0)
    CGWarpMouseCursorPosition(point)
    CGAssociateMouseAndMouseCursorPosition(1)
  }

  static let shared = EdgeClamp()
}