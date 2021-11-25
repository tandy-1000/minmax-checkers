# minmax-checkers [![CI](https://github.com/tandy-1000/minmax-checkers/actions/workflows/ci.yml/badge.svg)](https://github.com/tandy-1000/minmax-checkers/actions/workflows/ci.yml) [![Windows build](https://github.com/tandy-1000/minmax-checkers/actions/workflows/window.yml/badge.svg)](https://github.com/tandy-1000/minmax-checkers/actions/workflows/window.yml)
A simple minmax checkers game in Nim with [nico](https://github.com/ftsf/nico).

## Compilation
Get SDL2 dll: `nimble deps`

Install dependencies: `nimble build`

Compile a release executable: `nimble release`

## TODO
 - [ ] Refactor tictactoe code to checkers
    - [x] Implement new grid in GUI
    - [x] Implement `getMoves` for coordinate including captures
    - [ ] Implement scoring / game result functions
    - [ ] Update rules page
 - [ ] Write new tests
 - [ ] Implement difficulty by throwing in random moves every now and then
