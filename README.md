# minmax-checkers [![CI](https://github.com/tandy-1000/minmax-checkers/actions/workflows/ci.yml/badge.svg)](https://github.com/tandy-1000/minmax-checkers/actions/workflows/ci.yml) [![Windows build](https://github.com/tandy-1000/minmax-checkers/actions/workflows/window.yml/badge.svg)](https://github.com/tandy-1000/minmax-checkers/actions/workflows/window.yml) [![Emscripten deployment](https://github.com/tandy-1000/minmax-checkers/actions/workflows/emscripten.yml/badge.svg)](https://github.com/tandy-1000/minmax-checkers/actions/workflows/emscripten.yml)
A simple minmax checkers game in Nim with [nico](https://github.com/ftsf/nico).

[Click here to play!](https://tandy-1000.github.io/minmax-checkers/checkers.html)

## Features
- [x] Selectable player color
- [ ] Varying difficulty (varying minimax depth)
- [x] Click and drop
- [x] Only allows legal moves with error messaging
- [x] King conversion at baseline
- [x] Regicide
- [x] Forced capture
- [x] Multi-leg captures on same piece
- [x] Hint feature
- [ ] Minimax AI with Alpha-Beta pruning
- [x] Human-like AI move making
- [ ] Rules page

## Compilation
Get SDL2 dll: `nimble deps`

Install dependencies: `nimble build`

Compile a release executable: `nimble release`

