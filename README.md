# xemu

NES emulator for Apple platforms. A SwiftUI app for iOS, macOS, and tvOS
renders the emulator output through Metal, while the emulation itself lives
in reusable Swift packages so the core runs anywhere Swift does.

![xemu showcase](https://github.com/user-attachments/assets/b0b7aa8b-6afd-4a35-bb7d-b773d70a4f1d)

## Layout

- `xemu` — the app: a game collection with artwork and metadata from a
  bundled OpenVGDB database, ROM import from files or over the network
  through an embedded Vapor upload server, Metal rendering, audio output,
  game controller support, haptics, and save data management.
- `xemu-lib` — the `XemuLib` package:
  - `XemuNES`: the NES core — MOS 6502 CPU with unofficial opcodes, PPU,
    APU, and the NROM, MMC1, UNROM, CNROM, AXROM, CPROM, and GxROM mappers.
  - `XemuAsm`: 6502 assembler and disassembler.
  - `XemuDebugger`: breakpoints and register introspection for debuggable
    systems.
  - `XemuCore`: the `Emulator` protocol — load a program, step a frame,
    read the frame, audio, and save buffers.
  - `XemuFoundation`: shared utilities.
- `xemu-cli` — a libedit-based interactive debugger for macOS built on
  `XemuDebugger`.

## Development

The app builds through Xcode: open `xemu.xcodeproj`. The packages build with
Swift Package Manager:

```sh
cd xemu-lib
swift build
swift test
```

Linting and formatting run through [mise](https://mise.jdx.dev):

```sh
mise run lint
mise run format
```
