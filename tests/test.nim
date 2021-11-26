import std/[unittest, options, enumerate]
import ../src/classes

suite "Move":
  test "getDir - North East":
    check newMove(3, 0, 2, 1).getDir == some Direction.northEast

  test "getDir - North West":
    check newMove(2, 3, 1, 2).getDir == some Direction.northWest

  test "getDir - South East":
    check newMove(1, 0, 2, 1).getDir == some Direction.southEast

  test "getDir - South West":
    check newMove(0, 1, 1, 0).getDir == some Direction.southWest

  test "getDir - Non legal direction":
    check newMove(0, 0, 0, 1).getDir == none Direction

  test "midpoint - capture":
    check newMove(1, 0, 3, 2, jump = true).midpoint() == (2, 1)

  test "isCapture - capture":
    var move = newMove(1, 0, 3, 2)
    move.isCapture()
    check move.jump == true

  test "isCapture - non capture":
    var move = newMove(1, 0, 2, 1)
    move.isCapture()
    check move.jump == false

suite "Board":
  let board = newBoard(dimension = 4, difficulty = Difficulty.easy)
  # echo debugGrid board.grid

  test "Populated board":
    let
      grid = @[
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white, @[Direction.southEast, Direction.southWest])),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white, @[Direction.southEast, Direction.southWest]))
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
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black, @[Direction.northEast, Direction.northWest])),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black, @[Direction.northEast, Direction.northWest])),
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
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white, @[Direction.southEast, Direction.southWest])),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white, @[Direction.southEast, Direction.southWest]))
        ],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light)
        ],
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black, @[Direction.northEast, Direction.northWest])),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark)],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black, @[Direction.northEast, Direction.northWest])),
          newGridSquare(GridColor.light)
        ]
      ]
    board.move(board.nextSquare(3, 0, Direction.northEast), board.grid)
    check board.grid == grid

  test "Get jump - capture":
    check board.getJump(newMove(0, 0, 1, 1), Direction.southEast) == newMove(0, 0, 2, 2, jump = true)

  # test "Forced captures":

  test "Make capture":
    let
      grid = @[
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white, @[Direction.southEast, Direction.southWest])),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black, @[Direction.northEast, Direction.northWest, Direction.southEast, Direction.southWest], king = true))
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
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black, @[Direction.northEast, Direction.northWest])),
          newGridSquare(GridColor.light)
        ]
      ]
    board.move(board.nextSquare(0, 3, Direction.southWest), board.grid)
    let capture = board.getCapture(newMove(2, 1, 1, 2), Direction.northEast, board.grid).get()
    board.move(capture, board.grid)
    check board.grid == grid and capture == newMove(2, 1, 0, 3)

  test "Multi-leg capture with same piece":
    let
      boardSix = newBoard(dimension = 6, difficulty = Difficulty.easy)
      grid = @[
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black, @[Direction.northEast, Direction.northWest, Direction.southEast, Direction.southWest], king = true)),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark)
        ],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white, @[Direction.southEast, Direction.southWest])),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light)
        ],
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark)
        ],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white, @[Direction.southEast, Direction.southWest])),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light)
        ],
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark)
        ],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light)
        ]
      ]

    var moves = boardSix.getPlayerMoves(PieceColor.black, grid)
    boardSix.move(moves[0], grid)
    var assertion = moves == @[newMove(0, 3, 2, 1, jump = true)] and boardSix.turn == boardSix.human
    check assertion
    moves = boardSix.getPlayerMoves(PieceColor.black, grid)
    assertion = moves == @[newMove(2, 1, 4, 3, jump = true)]
    board.move(moves[0], grid)
    check assertion

  test "Forced capture and regicide":
    let
      grid = @[
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white, @[Direction.southEast, Direction.southWest])),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black, @[Direction.northEast, Direction.northWest, Direction.southEast, Direction.southWest], king = true))
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
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black, @[Direction.northEast, Direction.northWest])),
          newGridSquare(GridColor.light)
        ]
      ]
    board.move(board.nextSquare(0, 3, Direction.southWest), grid)
    let moves = board.getMoves(0, 1, grid)
    board.move(moves[0], grid)
    check grid[2][3].piece.get().king == true and moves.len == 1

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
    board.move(board.getMove(0, 3, Direction.southWest, board.grid)[0], board.grid)
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
