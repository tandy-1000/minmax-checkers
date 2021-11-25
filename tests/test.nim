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
    board.move(board.nextSquare(3, 0, Direction.northEast), board.grid)
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
    board.move(board.nextSquare(0, 3, Direction.southWest), board.grid)
    let capture = board.getCapture(newMove(2, 1, 1, 2), board.grid).get()
    board.move(capture, board.grid)
    check board.grid == grid and capture == newMove(2, 1, 0, 3)

  test "Regicide":
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
    board.move(board.nextSquare(0, 3, Direction.southWest), grid)
    board.move(board.getCapture(newMove(0, 1, 1, 2), grid).get(), grid)
    check grid[2][3].piece.get().king == true

  test "Get moves (king)":
    check board.getMoves(0, 3, board.grid) == @[newMove(0, 3, 1, 2)]

  test "Get moves (top, white)":
    check board.getMoves(0, 1, board.grid) == @[newMove(0, 1, 1, 2), newMove(0, 1, 1, 0)]

  test "Get moves (bottom, black":
    check board.getMoves(3, 2, board.grid) == @[newMove(3, 2, 2, 3), newMove(3, 2, 2, 1)]

  test "Get player pieces (ai & human)":
    let
      humanPieces = board.getPlayerPieces(board.human, board.grid)
      aiPieces = board.getPlayerPieces(board.ai, board.grid)
    check humanPieces == @[(0, 3), (3, 2)] and aiPieces == @[(0, 1)]

  test "Get player moves (ai)":
    check board.getPlayerMoves(board.ai, board.grid) == @[newMove(0, 1, 1, 2), newMove(0, 1, 1, 0)]

  test "Get player moves (human)":
    let assertion = board.getPlayerMoves(board.human, board.grid) == @[newMove(0, 3, 1, 2), newMove(3, 2, 2, 3), newMove(3, 2, 2, 1)]
    check assertion

  test "Has player lost (human)":
    check board.hasPlayerLost(board.getPlayerPieces(board.human, board.grid)) == false

  test "Has player lost (ai)":
    check board.hasPlayerLost(board.getPlayerPieces(board.ai, board.grid)) == false

  test "Game Over (false, no winner)":
    let (gameOver, winner) = board.isGameOver(board.grid)
    check gameOver == false and winner == none PieceColor

  test "Game Over (true, human winner)":
    board.move(board.nextSquare(0, 1, Direction.southEast), board.grid)
    board.move(board.getMove(0, 3, Direction.southWest, board.grid).get(), board.grid)
    let (gameOver, winner) = board.isGameOver(board.grid)
    check gameOver == true and winner == some board.human

  test "Game Over (no pieces)":
    let
      grid = @[
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark)
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
          newGridSquare(GridColor.dark)
        ],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light)
        ]
      ]
      (gameOver, winner) = board.isGameOver(grid)
    check gameOver == true and winner == none PieceColor
