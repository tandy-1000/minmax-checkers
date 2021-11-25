# minmax-checkers [![CI](https://github.com/tandy-1000/minmax-checkers/actions/workflows/ci.yml/badge.svg)](https://github.com/tandy-1000/minmax-checkers/actions/workflows/ci.yml) [![Windows build](https://github.com/tandy-1000/minmax-checkers/actions/workflows/window.yml/badge.svg)](https://github.com/tandy-1000/minmax-checkers/actions/workflows/window.yml)
A simple minmax checkers game in Nim with [nico](https://github.com/ftsf/nico).

## Features
- [ ] Selectable player color
- [ ] Varying difficulty
- [ ] Click and drop
- [x] King conversion at baseline
- [x] Regicide
- [ ] Forced capture
- [ ] Multi-leg captures
- [ ] Hint feature
- [ ] Rules page
- [ ] Minimax AI with Alpha-Beta pruning
- [ ] Only allows legal moves
   - [ ] with error messaging

## Compilation
Get SDL2 dll: `nimble deps`

Install dependencies: `nimble build`

Compile a release executable: `nimble release`

