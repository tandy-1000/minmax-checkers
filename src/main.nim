import std/enumerate
import pkg/[oolib, nico]

const
  orgName* = "org"
  appName* = "Checkers"

type
  GridValue* = enum
    none = " ", naught = "O", cross = "X"


class pub Square:
  var
    x*, y*, x1*, y1*: int


class pub Board:
  var
    dimension: int
    grid*: seq[seq[GridValue]]
    availablePositions*: seq[(int, int)]
    successorEvaluations*: seq[int]
  
  proc `new`(dimension: int = 3): Board =
    self.dimension = dimension
    var column: seq[GridValue]
    for y in 0 ..< self.dimension:
      column = @[]
      for x in 0 ..< self.dimension:
        column.add(GridValue.none)
        self.availablePositions.add((x, y))
        self.successorEvaluations.add(0)
      self.grid.add(column)

  proc getAvailablePositions*(grid: seq[seq[GridValue]]): seq[(int, int)] = 
    for y in 0 ..< self.dimension:
      for x in 0 ..< self.dimension:
        if grid[y][x] == GridValue.none:
          result.add((x, y))

  proc placePiece*(pos: (int, int), player: GridValue): bool =
    if self.grid[pos[1]][pos[0]] == GridValue.none:
      self.grid[pos[1]][pos[0]] = player
      self.availablePositions.del(self.availablePositions.find(pos))
      result = true
    else:
      result = false

  proc hasPlayerWon*(player: GridValue): bool =
    # assertions for diagonal wins
    let
      diagonalWinLeft = self.grid[0][0] == player and self.grid[1][1] == player and self.grid[2][2] == player
      diagonalWinRight = self.grid[0][2] == player and self.grid[1][1] == player and self.grid[0][2] == player and self.grid[2][0] == player
    if diagonalWinLeft or diagonalWinRight:
      result = true

    var rowWin, columnWin: bool
    for i in 0 ..< self.dimension:
      # assertions for each row / column win
      rowWin = self.grid[i][0] == player and self.grid[i][1] == player and self.grid[i][2] == player
      columnWin = self.grid[0][i] == player and self.grid[1][i] == player and self.grid[2][i] == player
      if rowWin or columnWin:
        result = true

  proc isGameOver*: (bool, GridValue) =
    # checks whether the board is full
    var
      winner = GridValue.none
      boardFull = false

    if self.availablePositions.len == 0:
      boardFull = true

    for player in {GridValue.cross, GridValue.naught}:
      if self.hasPlayerWon(player):
        winner = player
    result = (boardFull, winner)

  proc getBestMove*: (int, int) =
    # add randomisation in cases where multiple moves exist
    var max, best: int
    max = -1
    for i, score in enumerate(self.successorEvaluations):
      if max < score:
        max = score
        best = i
    return self.availablePositions[best]

  proc minimax*(depth: int, player: GridValue, grid: seq[seq[GridValue]]): int =
    if player == GridValue.cross:
      result = -1
    elif player == GridValue.naught:
      result = 1

      var
        currentScore: int
        grid = grid
        availablePositions = self.getAvailablePositions(self.grid)

      if self.hasPlayerWon(GridValue.cross):
        result = 1
      elif self.hasPlayerWon(GridValue.naught):
        result = -1
      
      for i, pos in enumerate(availablePositions):
        if player == GridValue.cross:
          if grid[pos[1]][pos[0]] == GridValue.none:
            grid[pos[1]][pos[0]] = GridValue.cross
          currentScore = self.minimax(depth + 1, GridValue.naught, grid)
          if currentScore > result:
            result = currentScore
        elif player == GridValue.naught:
          if grid[pos[1]][pos[0]] == GridValue.none:
            grid[pos[1]][pos[0]] = GridValue.naught
          currentScore = self.minimax(depth + 1, GridValue.cross, grid)
          if currentScore > result:
            result = currentScore

        if depth == 0:
          self.successorEvaluations[i] = result
        
        grid[pos[0]][pos[1]] = GridValue.none


class pub Checkers:
  var
    gridBounds: seq[seq[Square]]
    gridSquare: Square
    board: Board = newBoard()
    offset = 16
    size = 32
    outOfBounds = false
    playedPosition = true
    gameOver = false
    gameResult = GridValue.none
    turn = GridValue.cross

  proc `new`: Checkers =
    var
      x, y, x1, y1: int = self.offset
      gridRow: seq[Square]
      gridColumns: seq[seq[Square]]
    for row in self.board.grid:
      x = self.offset
      x1 = self.offset
      gridRow = @[]
      y1 = y + self.size
      for column in row:
        x1 = x + self.size
        gridRow.add(newSquare(x, y, x1, y1))
        x = x1
      y = y1
      gridColumns.add(gridRow)
    self.gridBounds = gridColumns
    self.gridSquare = newSquare(self.offset, self.offset, y, y)

  proc isOutOfBounds*(pos: (int, int), square: Square): bool =
    if (pos[0] <= square.x or pos[0] >= square.x1) or (pos[1] <= square.y or pos[1] >= square.y1):
      result = true

  proc drawPiece*(val: GridValue, gridBound: Square, offset: int = 5) =
    let
      x = gridBound.x + offset
      y = gridBound.y + offset
      x1 = gridBound.x1 - offset
      y1 = gridBound.y1 - offset
    setColor(7)
    if val == GridValue.cross:
      line(x, y, x1, y1)
      line(x1, y, x, y1)
    elif val == GridValue.naught:
      let
        x2 = (x1 + x) div 2
        y2 = (y1 + y) div 2
        r = (x1 - x) div 2
      circ(x2, y2, r)

  proc gameOverMessage*(message: string, color: int) =
    let
      xCenter = screenWidth div 2
      yCenter = screenHeight div 2
      x = xCenter - 22
      x1 = xCenter + 20
      y = yCenter - 2
      y1 = yCenter + 6

    setColor(color)
    rrectfill(x, y, x1, y1)
    setColor(7)
    printc(message, xCenter, yCenter)

var c = newCheckers()


proc gameInit*() =
  loadFont(0, "font.png")

proc gameDraw*() =
  cls()
  setColor(7)
  printc("Tic Tac Toe", screenWidth div 2, 8)
    
  for y, row in enumerate(c.gridBounds):
    for x, square in enumerate(row):
      rect(square.x, square.y, square.x1, square.y1)
      c.drawPiece(c.board.grid[y][x], square)

  if c.outOfBounds:
    c.playedPosition = true
    setColor(4)
    printc("Please click within the grid!", screenWidth div 2, 120)
  
  if not c.playedPosition:
    setColor(4)
    printc("This position has been played!", screenWidth div 2, 120)
  
  if c.gameResult == GridValue.cross:
    c.gameOverMessage("You Win!", 3)
  elif c.gameResult == GridValue.naught:
    c.gameOverMessage("You Lose!", 4)
  elif c.gameResult == GridValue.none and c.gameOver == true:
    c.gameOverMessage("Game Over.", 4)

proc gameUpdate*(dt: float32) =
  setColor(7)
  (c.gameOver, c.gameResult) = c.board.isGameOver()
  if c.turn == GridValue.cross and c.gameOver == false:
    if mousebtnp(0):
      let pos = mouse()
      c.outOfBounds = c.isOutOfBounds(pos, c.gridSquare)
      if not c.outOfBounds:
        while c.turn == GridValue.cross:
          let
            x = (pos[0] - c.offset) div c.size
            y = (pos[1] - c.offset) div c.size
          c.playedPosition = c.board.placePiece((x, y), GridValue.cross)
          c.turn = GridValue.naught
        c.outOfBounds = false
      (c.gameOver, c.gameResult) = c.board.isGameOver()
  elif c.turn == GridValue.naught and c.gameOver == false:
    while c.turn == GridValue.naught:
      discard c.board.minimax(0, GridValue.naught, c.board.grid)
      c.board.availablePositions = c.board.getAvailablePositions(c.board.grid)
      c.playedPosition = c.board.placePiece(c.board.getBestMove(), GridValue.naught)
      c.turn = GridValue.cross
    (c.gameOver, c.gameResult) = c.board.isGameOver()


nico.init(orgName, appName)
fixedSize(true)
integerScale(true)
nico.createWindow(appName, 128, 128, 4, false)
nico.run(gameInit, gameUpdate, gameDraw)
