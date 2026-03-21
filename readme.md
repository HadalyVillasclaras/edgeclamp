# EdgeClamp

EdgeClamp is a small macOS utility that prevents the mouse cursor from reaching the top and bottom edges of the screen. It was created as a lightweight workaround to simulate a **kiosk-like environment** where the menu bar or Dock should not be accessible during interaction.

This tool runs in the background and clamps the cursor position when it approaches restricted screen edges.

---

## What it does

- Blocks cursor access to the top screen edge
- Blocks cursor access to the bottom screen edge
- Allows temporary bypass while holding **Shift**
- Runs as a minimal background executable
- Designed for kiosk-style setups or controlled installations

---

## Running the app

An executable file is already included in the repository:

`EdgeClamp`

Double-click it to start the utility.

---

## Updating after editing the code

If you modify the source files, rebuild the executable with:

`./build.sh`

This regenerates the `EdgeClamp` executable using the latest code.

---

## Configuration

Basic behavior can be adjusted inside:

`Sources/EdgeClamp/Constants.swift`

Available settings include:

- top edge padding
- bottom edge padding
- warp offset
- Shift-key bypass toggle

---

## Why this exists

macOS does not provide a simple built-in kiosk mode for custom web or installation environments without additional tooling or system configuration.

EdgeClamp provides a minimal workaround by preventing the cursor from reaching system UI edges, allowing controlled fullscreen interaction setups without modifying the operating system.