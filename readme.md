# EdgeClamp

EdgeClamp is a lightweight macOS utility that prevents the mouse cursor from reaching the top edge of the screen.

It is designed for kiosk setups, installations, exhibitions, and public-facing environments where triggering the macOS menu bar must be avoided.

When the cursor enters the top edge zone, EdgeClamp repositions it slightly downward, preventing the system UI from appearing.

Holding `SHIFT` temporarily disables the clamp.

---

## What It Does

- Monitors global mouse movement  
- Detects when the cursor enters the top screen edge  
- Repositions the cursor to prevent menu bar activation  
- Allows temporary bypass by holding `SHIFT`  
- Supports multi-monitor setups  

EdgeClamp does not modify system settings and does not disable system features.  
It only adjusts cursor position in real time.

---

## Requirements

- macOS  
- Swift (preinstalled on macOS)  
- Accessibility permission  
- Input Monitoring permission  

---

## Installation

Clone or download the repository, then compile:

```bash
swiftc EdgeClamp.swift -o EdgeClamp
```

---

## Permissions (Required)

Before running, grant permissions:

**System Settings → Privacy & Security**

Enable:

- Accessibility → Terminal (or the compiled binary)
- Input Monitoring → Terminal (or the compiled binary)

Then fully quit and reopen Terminal.

---

## Running

```bash
./EdgeClamp
```

You should see:

```
EdgeClamp is running. Top edge is clamped (40px). Hold SHIFT to temporarily allow access.
```

The process will remain active until interrupted.

To stop:

```
Ctrl + C
```

---

## Behavior

- The top edge is clamped within a fixed pixel zone (`topPadding`)  
- When the cursor enters this zone, it is repositioned downward  
- Holding `SHIFT` disables the clamp temporarily  
- Works across multiple screens  

---

## Use Cases

EdgeClamp is intended for:

- Kiosk environments  
- Interactive installations  
- Exhibitions  
- Museum setups  
- Dedicated single-app macOS systems  

It pairs well with Chrome `--kiosk` mode or other fullscreen applications.

---

## Notes

EdgeClamp operates using a global event tap and cursor repositioning.  
It does not alter system configuration.  
It must remain running to function.