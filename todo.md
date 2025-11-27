# NES Roadmap

# v0.1.0
- [x] base mapper rewrite
- [x] nrom mapper
- [x] cnrom mapper
- [x] Encode / Decode save data
- [ ] mapper mapCPU and mapPPU refactor
- [ ] mmc1 mapper
- [ ] mmc3 mapper

# v0.1.1
- [x] unrom mapper
- [x] axrom mapper
- [ ] mmc5 mapper
- [ ] mmc2 mapper
- [ ] mmc4 mapper

# v0.2.0
- [ ] make sure proper font is used across the app
- [ ] iNes Debug View
- [ ] nes settings view
- [ ] macOS UI Fix (settings + other sheet are very rough)
- [ ] tvOS UI Fix 
- [ ] iPad UI Fix
- [ ] UI controller Overlay (big screen)

# v0.3.0
- [ ] apu rewrite
- [ ] dmc dma
- [ ] audio buffer clicks fix, low framerate fix

# v0.4.0
- [ ] make sure all tests are passing
- [ ] try to fix some AccuracyCoin edge cases
- [ ] find a way to setup more automated tests (snapshots tests ?, debug where they write their output ?) sprite hit tests / overflow tests
- [ ] clear up TODOs in the codebase

# v1.0.0
- [ ] app store screenshots ui tests
- [ ] make sure swift data is being backed up on iCloud
- [ ] firebase / aws implementation (flags, crash logs, analytics)
- [ ] proper readme.md
- [ ] setup CI

# v1.1.0
- [ ] save state
- [ ] save state managment view
- [ ] save state buttons + hot reload
- [ ] import / export save state to file
- [ ] share button (save file, save state)

# v1.2.0
- [ ] keyboard input mapping
- [ ] controller support
- [ ] controller input remapping

# v1.3.0
- [ ] pal / dandy timming support
- [ ] grayscale / color emphasis support
- [ ] performance optimizations (data alignment, go back to switch case for opcode decoding, etc.)
- [ ] memory access optimization
- [ ] zero page optimization
- [ ] other optimizations ?

# beyond
- [ ] more mappers
- [ ] chr tables debugger
- [ ] visual debugger
- [ ] command line debugger
- [ ] prism replacement

