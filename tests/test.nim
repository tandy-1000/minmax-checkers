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
    check board.nextSquare(3, 0, Direction.northEast) == newMove(3, 0, 2, 1)

  test "Get next North West square":
    check board.nextSquare(2, 3, Direction.northWest) == newMove(2, 3, 1, 2)

  test "Get next South East square":
    check board.nextSquare(1, 0, Direction.southEast) == newMove(1, 0, 2, 1)

  test "Get next South West square":
    check board.nextSquare(0, 1, Direction.southWest) == newMove(0, 1, 1, 0)

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
    discard board.move board.nextSquare(3, 0, Direction.northEast)
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
    discard board.move board.nextSquare(0, 3, Direction.southWest)
    let capture = board.getCapture(newMove(2, 1, 1, 2)).get()
    discard board.move capture
    check board.grid == grid and capture == newMove(2, 1, 0, 3)

  test "Get moves (king)":
    check board.getMoves(0, 3) == @[newMove(0, 3, 1, 2)]

  test "Get moves (top, white)":
    check board.getMoves(0, 1) == @[newMove(0, 1, 1, 2), newMove(0, 1, 1, 0)]

  test "Get moves (bottom, black":
    check board.getMoves(3, 2) == @[newMove(3, 2, 2, 3), newMove(3, 2, 2, 1)]

  test "Get player pieces (ai & human)":
    let
      humanPieces = board.getPlayerPieces(board.human)
      aiPieces = board.getPlayerPieces(board.ai)
    check humanPieces == @[(0, 3), (3, 2)] and aiPieces == @[(0, 1)]

  test "Get player moves (ai)":
    check board.getPlayerMoves(board.ai) == @[newMove(0, 1, 1, 2), newMove(0, 1, 1, 0)]

  test "Get player moves (human)":
    let assertion = board.getPlayerMoves(board.human) == @[newMove(0, 3, 1, 2), newMove(3, 2, 2, 3), newMove(3, 2, 2, 1)]
    check assertion
