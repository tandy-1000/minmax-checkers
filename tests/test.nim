import std/unittest
import std/enumerate
import ../src/classes

suite "Position tests":
  setup:
    let
      pos = newPosition(0)
      pos1 = newPosition(0)
    pos.score = 1

  test "Position equality":
    check pos == pos1

  test "Position comparison":
    check pos1 < pos

suite "Board tests":
  setup:
    let
      board = newBoard(difficulty = Difficulty.impossible)
      player = GridValue.black
      positions = @[newPosition(0), newPosition(1)]

  test "Find position":
    let pos = newPosition(1)
    pos.score = 1
    let ind = board.find(pos, positions)
    board.availablePositions[ind] = pos
    check ind == 1 and board.availablePositions[ind] == pos

  test "Get available positions":
    let
      grid = @[GridValue.none, GridValue.none]
      availablePositions = board.getAvailablePositions(grid)
    for i, pos in enumerate(availablePositions):
      check pos == positions[i]

  test "Place piece":
    let
      move = board.placePiece(newPosition(0), player)
      grid = @[GridValue.black, GridValue.none, GridValue.none, GridValue.none, GridValue.none, GridValue.none, GridValue.none, GridValue.none, GridValue.none]
    check move == true and board.grid == grid

  test "Place piece in occupied position":
    discard board.placePiece(newPosition(0), player)
    let secondMove = board.placePiece(newPosition(0), player)
    check secondMove == false

  test "Vertical win: left column":
    let
      grid = @[
        GridValue.black, GridValue.none, GridValue.white,
        GridValue.black, GridValue.white, GridValue.none,
        GridValue.black, GridValue.none, GridValue.none
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Vertical win: middle column":
    let
      grid = @[
        GridValue.white, GridValue.black, GridValue.white,
        GridValue.white, GridValue.black, GridValue.black,
        GridValue.black, GridValue.black, GridValue.white
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Vertical win: right column":
    let
      grid = @[
        GridValue.white, GridValue.white, GridValue.black,
        GridValue.white, GridValue.white, GridValue.black,
        GridValue.black, GridValue.black, GridValue.black
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Horizontal win: top row":
    let
      grid = @[
        GridValue.black, GridValue.black, GridValue.black,
        GridValue.white, GridValue.black, GridValue.white,
        GridValue.none, GridValue.white, GridValue.white
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Horizontal win: middle row":
    let
      grid = @[
        GridValue.white, GridValue.none, GridValue.none,
        GridValue.black, GridValue.black, GridValue.black,
        GridValue.none, GridValue.white, GridValue.white
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Horizontal win: bottom row":
    let
      grid = @[
        GridValue.white, GridValue.none, GridValue.none,
        GridValue.black, GridValue.white, GridValue.white,
        GridValue.black, GridValue.black, GridValue.black
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Diagonal win: left":
    let
      grid = @[
        GridValue.black, GridValue.none, GridValue.white,
        GridValue.none, GridValue.black, GridValue.white,
        GridValue.none, GridValue.none, GridValue.black
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Diagonal win: right":
    let
      grid = @[
        GridValue.white, GridValue.none, GridValue.black,
        GridValue.none, GridValue.black, GridValue.white,
        GridValue.black, GridValue.none, GridValue.white
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Full board and no winner":
    let
      grid = @[
        GridValue.black, GridValue.black, GridValue.white,
        GridValue.white, GridValue.white, GridValue.black,
        GridValue.black, GridValue.white, GridValue.black
      ]
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check gameOver == true and winner == GridValue.none

  test "Game not over":
    let (gameOver, winner) = board.isGameOver(board.grid, board.getAvailablePositions(board.grid))

    check gameOver == false and winner == GridValue.none

  test "Minimax: minimise loss":
    let
      alpha = low(BiggestInt)
      beta = high(BiggestInt)
      depth = 0
      grid = @[
        GridValue.black, GridValue.none, GridValue.none,
        GridValue.black, GridValue.none, GridValue.none,
        GridValue.none, GridValue.none, GridValue.white
      ]
    board.grid = grid
    board.availablePositions = board.getAvailablePositions(grid)
    let position = board.minimax(GridValue.white, grid, depth, alpha, beta)
    check position.i == 6

  test "Get best move: minimise loss":
    let
      grid = @[
        GridValue.black, GridValue.none, GridValue.none,
        GridValue.black, GridValue.none, GridValue.none,
        GridValue.none, GridValue.none, GridValue.white
      ]
    board.grid = grid
    board.availablePositions = board.getAvailablePositions(grid)
    let position = board.getBestMove(GridValue.white)
    check position.i == 6

  test "Minimax: maximise win":
    let
      alpha = low(BiggestInt)
      beta = high(BiggestInt)
      depth = 0
      grid = @[
        GridValue.white, GridValue.black, GridValue.none,
        GridValue.white, GridValue.black, GridValue.none,
        GridValue.none, GridValue.none, GridValue.black
      ]
    board.grid = grid
    board.availablePositions = board.getAvailablePositions(grid)
    let position = board.minimax(GridValue.white, grid, depth, alpha, beta)
    check position.i == 6

  test "Get best move: maximise win":
    let
      grid = @[
        GridValue.white, GridValue.black, GridValue.none,
        GridValue.white, GridValue.black, GridValue.none,
        GridValue.none, GridValue.none, GridValue.black
      ]
    board.grid = grid
    board.availablePositions = board.getAvailablePositions(grid)
    let position = board.getBestMove(GridValue.white)
    check position.i == 6
