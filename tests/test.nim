import std/[unittest, options]
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

  test "Forced captures":
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
    var
      moves: seq[Move]
      assertion: bool

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

    ## set the grid to the scenario
    boardSix.grid = grid
    ## get moves for black player
    moves = boardSix.getPlayerMoves(PieceColor.black, boardSix.grid)
    ## move black player, should make capture
    boardSix.move(moves[0], boardSix.grid)
    boardSix.changeTurn()
    ## check assertion that generated move is correct and turn is set correctly
    assertion = moves == @[newMove(0, 3, 2, 1, jump = true)] and boardSix.turn == boardSix.ai
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

  test "Has player lost (false)":
    check board.hasPlayerLost(board.human, board.grid) == false

  test "Has player lost (false)":
    check board.hasPlayerLost(board.ai, board.grid) == false

  test "Has player lost (human wins, ai loses)":
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
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black, @[Direction.northEast, Direction.northWest, Direction.southEast, Direction.southWest], king = true)),
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
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light)
        ]
      ]
    check board.hasPlayerLost(board.ai, grid) == true
    check board.hasPlayerLost(board.human, grid) == false

  test "Has player lost (ai wins, human loses)":
    let
      grid = @[
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white, @[Direction.southEast, Direction.southWest])),
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
          newGridSquare(GridColor.dark)],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light)
        ]
      ]
    check board.hasPlayerLost(board.ai, grid) == false
    check board.hasPlayerLost(board.human, grid) == true

  test "Game Over (false, no winner)":
    let (gameOver, winner) = board.isGameOver(board.grid)
    check gameOver == false and winner == none PieceColor

  test "Game Over (true, human winner)":
    board.move(board.nextSquare(0, 1, Direction.southEast), board.grid)
    board.move(board.getMove(0, 3, Direction.southWest, board.grid)[0], board.grid)
    let (gameOver, winner) = board.isGameOver(board.grid)
    check gameOver == true and winner == some board.human

  test "Game over (not over)":
    let
      grid = @[
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white, @[Direction.southEast, Direction.southWest])),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark)
        ],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black, @[Direction.northEast, Direction.northWest, Direction.southEast, Direction.southWest], king = true)),
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
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light)
        ]
      ]
      (gameOver, winner) = board.isGameOver(grid)
    check gameOver == false and winner == none PieceColor

  test "Minimax - game ending capture":
    let
      grid = @[
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.white, @[Direction.southEast, Direction.southWest])),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark)
        ],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some newPiece(PieceColor.black, @[Direction.northEast, Direction.northWest, Direction.southEast, Direction.southWest], king = true)),
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
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light)
        ]
      ]
    board.turn = board.ai
    let move = board.minimax(board.ai, grid, depth = 0, maximising = true, alpha = low(BiggestInt), beta = high(BiggestInt))
    check move == newMove(0, 1, 2, 3, jump = true)
