# minmax-checkers [![CI](https://github.com/tandy-1000/minmax-checkers/actions/workflows/ci.yml/badge.svg)](https://github.com/tandy-1000/minmax-checkers/actions/workflows/ci.yml)
A simple minmax checkers game in Nim with [nico](https://github.com/ftsf/nico).

## Compilation
Get SDL2 dll: `nimble deps`

Install dependencies: `nimble build`

Compile a release executable: `nimble release`

## TODO
 - [ ] Refactor tictactoe code to checkers
    - [x] Implement new grid in GUI
    - [ ] Fix hover on potential moves
       - [x] Only on black squares
       - [ ] Correctly get available moves
    - [ ] Implement checkers rules
    - [ ] Update rules page
 - [ ] Write new tests
