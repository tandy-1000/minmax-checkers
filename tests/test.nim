import std/[unittest, options]
import ../src/classes

suite "Board":
  let board = newBoard(dimension = 4, difficulty = Difficulty.easy)
  # echo debugGrid board.grid

  test "Populated board":
    let
      grid = @[
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some(newPiece(PieceColor.black))),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some(newPiece(PieceColor.black)))
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
          newGridSquare(GridColor.dark, some(newPiece(PieceColor.white))),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some(newPiece(PieceColor.white))),
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
          newGridSquare(GridColor.dark, some(newPiece(PieceColor.black))),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some(newPiece(PieceColor.black)))
        ],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light)
        ],
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some(newPiece(PieceColor.white))),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark)],
        @[
          newGridSquare(GridColor.dark),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some(newPiece(PieceColor.white))),
          newGridSquare(GridColor.light)
        ]
      ]
    board.move(board.nextSquare(3, 0, Direction.northEast))
    check board.grid == grid

  test "Make capture":
    let
      grid = @[
        @[
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some(newPiece(PieceColor.black))),
          newGridSquare(GridColor.light),
          newGridSquare(GridColor.dark, some(newPiece(PieceColor.white, king = true)))
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
          newGridSquare(GridColor.dark, some(newPiece(PieceColor.white))),
          newGridSquare(GridColor.light)
        ]
      ]
    board.move(board.nextSquare(0, 3, Direction.southWest))
    let capture = board.getCapture(newMove(2, 1, 1, 2)).get()
    board.move(capture)
    check board.grid == grid and capture == newMove(2, 1, 0, 3)

  # test "Get moves":
  #   let moves = board.getMoves(1, 0)
  #   echo debugGrid board.grid
  #   echo debugPiece board.grid[0][1].piece.get()
  #   for move in moves:
  #     echo debugMove move