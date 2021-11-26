# minmax-checkers [![CI](https://github.com/tandy-1000/minmax-checkers/actions/workflows/ci.yml/badge.svg)](https://github.com/tandy-1000/minmax-checkers/actions/workflows/ci.yml) [![Windows build](https://github.com/tandy-1000/minmax-checkers/actions/workflows/window.yml/badge.svg)](https://github.com/tandy-1000/minmax-checkers/actions/workflows/window.yml)
A simple minmax checkers game in Nim with [nico](https://github.com/ftsf/nico).

## Features
- [x] Selectable player color
- [ ] Varying difficulty (varying minimax depth)
- [x] Click and drop
- [x] Human-like AI move making
- [x] King conversion at baseline
- [x] Regicide
- [x] Forced capture
- [x] Multi-leg captures
- [ ] Hint feature
- [ ] Rules page
- [ ] Minimax AI with Alpha-Beta pruning
- [x] Only allows legal moves with error messaging

## Compilation
Get SDL2 dll: `nimble deps`

Install dependencies: `nimble build`

Compile a release executable: `nimble release`

