import std/[unittest, options, enumerate]
import ../src/classes

suite "Board":
  let board = newBoard(dimension = 4, difficulty = Difficulty.easy)
  # echo debugGrid board.grid

  test "Populated board":
    let
      grid = @[
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white)),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white))
        ],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light)
        ],
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark)],
        @[
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black)),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black)),
          newGridSquare(GridColor.light)
        ]
      ]
    check board.grid == grid

  test "Get next North East square":
    let nextSquare = board.nextSquare(3, 0, Direction.northEast)
    check nextSquare == newMove(3, 0, 2, 1)

  test "Get next North West square":
    let nextSquare = board.nextSquare(2, 3, Direction.northWest)
    check nextSquare == newMove(2, 3, 1, 2)

  test "Get next South East square":
    let nextSquare = board.nextSquare(1, 0, Direction.southEast)
    check nextSquare == newMove(1, 0, 2, 1)

  test "Get next South West square":
    let nextSquare = board.nextSquare(0, 1, Direction.southWest)
    check nextSquare == newMove(0, 1, 1, 0)

  test "Make move":
    let
      grid = @[
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white)),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white))
        ],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light)
        ],
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black)),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark)],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black)),
          newGridSquare(GridColor.light)
        ]
      ]
    board.move board.nextSquare(3, 0, Direction.northEast)
    check board.grid == grid

  test "Make capture":
    let
      grid = @[
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white)),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black, king = true))
        ],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light)
        ],
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark)],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black)),
          newGridSquare(GridColor.light)
        ]
      ]
    board.move board.nextSquare(0, 3, Direction.southWest)
    let capture = board.getCapture(newMove(2, 1, 1, 2)).get()
    board.move capture
    check board.grid == grid and capture == newMove(2, 1, 0, 3)

  test "Get moves (king)":
    let moves = board.getMoves(0, 3)
    check moves == @[newMove(0, 3, 1, 2)]

  test "Get moves (top, white)":
    let moves = board.getMoves(0, 1)
    check moves == @[newMove(0, 1, 1, 2), newMove(0, 1, 1, 0)]

  test "Get moves (bottom, black":
    let moves = board.getMoves(3, 2)
    check moves == @[newMove(3, 2, 2, 3), newMove(3, 2, 2, 1)]