import std/options
import pkg/[nico, oolib]


type
  GridColor* = enum
    dark = "⬛", light = "⬜"
  PieceColor* = enum
    black = "⚫", white = "🟤"
  Direction* = enum
    northEast, northWest, southEast, southWest
  Difficulty* = enum
    easy = 6, medium = 7, hard = 8, impossible = 9


class pub Square:
  var
    x*, y*, x1*, y1*: int


class pub Piece:
  var
    color*: PieceColor
    king*, selected*, potential*, clue*: bool

  proc `new`(color: PieceColor, king, potential, clue: bool = false) =
    self.color = color
    self.king = king
    self.potential = potential
    self.clue = clue

  proc makeKing* =
    self.king = true

  proc draw*(gridBound: Square, offset = 5) =
    let
      x = gridBound.x + offset
      y = gridBound.y + offset
      x1 = gridBound.x1 - offset
      y1 = gridBound.y1 - offset
      x2 = (x1 + x) div 2
      y2 = (y1 + y) div 2
      rx = (gridBound.x1 - gridBound.x - offset) div 2
      ry = (gridBound.y1 - gridBound.y - (offset div 2)) div 4

    setColor(7)
    if self.selected:
      setColor(4):
    elif self.potential:
      setColor(5)
    elif self.clue:
      setColor(3)

    if self.color == PieceColor.black:
      setColor(4)
      ellipsefill(x2, y2, rx, ry)
      setColor(15)
      ellipsefill(x2, y2 - 1, rx, ry - 1)

    elif self.color == PieceColor.white:
      setColor(6)
      ellipsefill(x2, y2, rx, ry)
      setColor(7)
      ellipsefill(x2, y2 - (offset div 4), rx, ry - (offset div 4))

    if self.king:
      setColor(9)
      printc("K", x2+1, y2-3)


# func for checking equality between `Piece`s
func `==`*(a, b: Piece): bool =
  return system.`==`(a, b) or (a.color == b.color and a.king == b.king)


class pub GridSquare:
  var
    color*: GridColor
    piece*: Option[Piece]

  proc `new`(color: GridColor, piece: Option[Piece] = none(Piece)) =
    self.color = color
    self.piece = piece


# func for checking equality between `GridSquare`s
func `==`*(a, b: GridSquare): bool =
  return system.`==`(a, b) or (a.color == b.color and a.piece == b.piece)


class pub Move:
  var
    x*, y*, x1*, y1*: int
    jump*: bool = false
    score*: BiggestInt = 0
    depth*: int = 0

  proc isPossible*(dimension: int = 8): bool =
    ## Returns true if the `Move` is possible in the grid's dimensions.

    if self.x > -1 and self.x < dimension and self.y > -1 and self.y < dimension and self.x1 > -1 and self.x1 < dimension and self.y1 > -1 and self.y1 < dimension:
      return true

  proc midpoint*: tuple[x: int, y: int] =
    ## Returns the midpoint of a jump move.

    if self.jump:
      let
        x = (self.x + self.x1) div 2
        y = (self.y + self.y1) div 2
      return (x, y)


# func for checking equality between `Move`s
func `==`*(a, b: Move): bool =
  let assertion = (a.x == b.x and a.x1 == b.x1 and a.y == b.y and a.y1 == b.y1)
  return system.`==`(a, b) or assertion

## convenience funcs for comparing `Move`s, `<` enables min/max comparisons
func `>`*(a, b: Move): bool = system.`>`(a.score, b.score)
func `<`*(a, b: Move): bool = system.`<`(a.score, b.score)


proc debugPiece*(piece: Piece): string =
  let str = "color: " & $piece.color
  return str

proc debugPieces*(pieces: seq[Piece]): string =
  for piece in pieces:
    result.add "\n" & debugPiece piece

proc debugMove*(move: Move): string =
  let str = "x: " & $move.x & " y: " & $move.y & "\nx1: " & $move.x1 & " y1: " & $move.y1 & "\njump: " & $move.jump
  return str

proc debugMoves*(moves: seq[Move]): string =
  for move in moves:
    echo debugMove move

proc debugGrid*(grid: seq[seq[GridSquare]]): string =
  for x in 0 ..< grid.len:
    for y in 0 ..< grid[x].len:
      if grid[x][y].piece.isSome():
        if grid[x][y].piece.get().color == PieceColor.white:
          result.add $PieceColor.white
        elif grid[x][y].piece.get().color == PieceColor.black:
          result.add $PieceColor.black
      else:
        if grid[x][y].color == GridColor.light:
          result.add $GridColor.light
        else:
          result.add $GridColor.dark
    result.add "\n"


class pub Board:
  var
    dimension*: int
    grid*: seq[seq[GridSquare]]
    gameOver* = false
    gameResult*: Option[PieceColor] = none PieceColor
    ai*: PieceColor = PieceColor.white
    human*, turn*: PieceColor = PieceColor.black
    difficulty*: Difficulty

  proc `new`(difficulty: Difficulty, dimension: int = 8): Board =
    ## Initialises a `Board` object.
    ## Populates the board with dark and light squares, and black and white players.

    self.dimension = dimension
    self.difficulty = difficulty
    let populate = (self.dimension div 2) - 1
    for x in 0 ..< self.dimension:
      self.grid.add @[]
      for y in 0 ..< self.dimension:
        if (x mod 2 == 0 and y mod 2 == 0) or (x mod 2 != 0 and y mod 2 != 0):
          self.grid[x].add newGridSquare(GridColor.light)
        else:
          if x >= 0 and x < populate:
            self.grid[x].add newGridSquare(GridColor.dark, some newPiece(color = self.ai))
          elif x >= self.dimension - populate and x < self.dimension:
            self.grid[x].add newGridSquare(GridColor.dark, some newPiece(color = self.human))
          else:
            self.grid[x].add newGridSquare(GridColor.dark)

  proc nextSquare*(x, y: int, direction: Direction): Move =
    ## Returns a `Move` object for a given direction and coordinate.

    var
      x1 = x
      y1 = y

    case direction:
    of Direction.northEast:
      x1 -= 1
      y1 += 1
    of Direction.northWest:
      x1 -= 1
      y1 -= 1
    of Direction.southEast:
      x1 += 1
      y1 += 1
    of Direction.southWest:
      x1 += 1
      y1 -= 1

    return newMove(x, y, x1, y1)

  proc getJump*(move: Move): Move =
    ## Returns a jump move, one grid square ahead of the current move.
    let
      x1 = move.x1 + (move.x1 - move.x)
      y1 = move.y1 + (move.y1 - move.y)

    return newMove(move.x, move.y, x1, y1, jump = true)

  proc isMoveLegal*(move: Move, grid: seq[seq[GridSquare]]): bool =
    if move.isPossible(dimension = self.dimension):
      if move.jump:
        if grid[move.x][move.y].piece.isSome() and grid[move.x1][move.y1].piece.isNone():
          let (xMid, yMid) = move.midpoint()
          if grid[xMid][yMid].piece.get().color != grid[move.x][move.y].piece.get().color:
            return true
      else:
        if grid[move.x1][move.y1].piece.isNone():
          return true

  proc getCapture*(move: Move, grid: seq[seq[GridSquare]]): Option[Move] =
    ## Returns a `Move` object if a capture is possible.

    let capture = self.getJump(move)
    if self.isMoveLegal(capture, grid):
      return some capture

  proc getMove*(x, y: int, direction: Direction, grid: seq[seq[GridSquare]]): seq[Move] =
    ## Returns a sequence of `Move` object given a coordinate and a `Direction`

    let move = self.nextSquare(x, y, direction)
    if self.isMoveLegal(move, grid):
      result.add move
    elif move.isPossible(dimension = self.dimension):
      if grid[move.x1][move.y1].piece.isSome():
        let capture = self.getCapture(move, grid)
        if capture.isSome():
          result.add capture.get()

  proc getMoves*(x, y: int, grid: seq[seq[GridSquare]]): seq[Move] =
    ## Returns a sequence of `Move` objects for a given coordinate, including captures

    if grid[x][y].piece.isSome():
      if grid[x][y].piece.get().color == self.human and grid[x][y].piece.get().king == false:
        for direction in {Direction.northEast, Direction.northWest}:
          result &= self.getMove(x, y, direction, grid)
      elif grid[x][y].piece.get().color == self.ai and grid[x][y].piece.get().king == false:
        for direction in {Direction.southEast, Direction.southWest}:
          result &= self.getMove(x, y, direction, grid)
      else:
        for direction in {Direction.northEast, Direction.northWest, Direction.southEast, Direction.southWest}:
          result &= self.getMove(x, y, direction, grid)

  proc getPlayerPieces*(player: PieceColor, grid: seq[seq[GridSquare]]): seq[tuple[x: int, y: int]] =
    ## Returns a sequence of coordinates for each piece a given player has on the grid

    for x in 0 ..< self.dimension:
      for y in 0 ..< self.dimension:
        if grid[x][y].piece.isSome():
          if grid[x][y].piece.get().color == player:
            result.add (x, y)

  proc getPlayerMoves*(player: PieceColor, grid: seq[seq[GridSquare]]): seq[Move] =
    ## Returns a sequence of `Move`s for each move a given player can make on the grid

    let pieces = self.getPlayerPieces(player, grid)
    for (x, y) in pieces:
      result &= self.getMoves(x, y, grid)

  proc cleanGrid* =
    ## Removes "potential" pieces from the grid, which are placed when a mouse hovers on the grid when a piece is selected.

    for x in 0 ..< self.dimension:
      for y in 0 ..< self.dimension:
        if self.grid[x][y].piece.isSome():
          if self.grid[x][y].piece.get().potential:
            self.grid[x][y] = newGridSquare(GridColor.dark)

  proc opposingPlayer*(player: PieceColor): PieceColor =
    if player == PieceColor.black:
      return PieceColor.white
    elif player == PieceColor.white:
      return PieceColor.black

  proc move*(move: Move, grid: seq[seq[GridSquare]]) =
    ## Moves a piece on the grid, given a `Move` object. Can account for kings and jumps.

    if grid[move.x][move.y].piece.isSome():
      grid[move.x1][move.y1].piece = grid[move.x][move.y].piece
      grid[move.x][move.y].piece = none(Piece)

      if grid[move.x1][move.y1].piece.get().color == self.human and move.x1 == 0 or grid[move.x1][move.y1].piece.get().color == self.ai and move.x1 == self.dimension - 1:
        grid[move.x1][move.y1].piece.get().makeKing()

      if move.jump:
        let
          xMid = (move.x + move.x1) div 2
          yMid = (move.y + move.y1) div 2
        if grid[xMid][yMid].piece.get().king == true:
          grid[move.x1][move.y1].piece.get().king = true
        grid[xMid][yMid].piece = none(Piece)
      else:
        self.turn = self.opposingPlayer(self.turn)

  proc hasPlayerLost*(pieces: seq[tuple[x: int, y: int]]): bool =
    ## Returns true if a player has no pieces or moves left, otherwise false.

    if pieces.len > 0:
      var moves: seq[Move]

      for (x, y) in pieces:
        moves &= self.getMoves(x, y, self.grid)

      if moves.len > 0:
        return false
      else:
        return true
    else:
      return true

  proc isGameOver*(grid: seq[seq[GridSquare]]): (bool, Option[PieceColor]) =
    ## Returns `(gameOver, Option[PieceColor])`.
    ## `gameOver` if a player has no pieces or moves left.
    ## `PieceColor` is returned if there is a winner.

    var
      gameOver = false
      winner = none PieceColor

    let
      humanLoss = self.hasPlayerLost(self.getPlayerPieces(self.human, grid))
      aiLoss = self.hasPlayerLost(self.getPlayerPieces(self.ai, grid))

    if humanLoss and aiLoss:
      gameOver = true
    elif not humanLoss and aiLoss:
      gameOver = true
      winner = some self.human
    elif humanLoss and not aiLoss:
      gameOver = true
      winner = some self.ai

    return (gameOver, winner)


class pub Checkers:
  var
    gridBounds*: seq[seq[Square]]
    gridSquare*: Square
    board*: Board
    offset* = 32
    size* = 24
    started* = false
    showRules* = false
    showClues* = false
    outOfBounds* = false
    successfulMove* = true

  proc `new`(difficulty: Difficulty): Checkers =
    self.board = newBoard(difficulty = difficulty)
    var
      x, y, x1, y1: int = self.offset
    for row in 0 ..< self.board.dimension:
      self.gridBounds.add @[]
      x = self.offset
      x1 = self.offset
      y1 = y + self.size
      for col in 0 ..< self.board.dimension:
        x1 = x + self.size
        self.gridBounds[row].add newSquare(x, y, x1, y1)
        x = x1
      y = y1
    self.gridSquare = newSquare(self.offset, self.offset, y, y)

  ## Returns a grid index from a mouse position
  proc xyToGrid*(pos: (int, int)): (int, int) =  ((pos[1] - self.offset) div self.size, (pos[0] - self.offset) div self.size)

  proc drawStartPage* =
    cls()
    let
      hCenter = screenWidth div 2
      padding = 20
      r = 6
      d = r * 2
      diffRowY = (padding * 2) + padding div 2
      playerRowY = (padding * 4)

    setColor(3)
    rect(hCenter - d, (screenHeight - padding) - r, hCenter + d, (screenHeight - padding) + r)

    setColor(1)
    if self.board.difficulty == Difficulty.easy:
      rectfill(hCenter - (3*d) - 1, diffRowY - r, hCenter - d - 3, diffRowY + r)
    else:
      rect(hCenter - (3*d) - 1, diffRowY - r, hCenter - d - 3, diffRowY + r)
    setColor(4)
    if self.board.difficulty == Difficulty.medium:
      rectfill(hCenter - d - 2, diffRowY - r, hCenter + d + 2, diffRowY + r)
    else:
      rect(hCenter - d - 2, diffRowY - r, hCenter + d + 2, diffRowY + r)
    setColor(8)
    if self.board.difficulty == Difficulty.hard:
      rectfill(hCenter + d + 3, diffRowY - r, hCenter + (3*d) + 1, diffRowY + r)
    else:
      rect(hCenter + d + 3, diffRowY - r, hCenter + (3*d) + 1, diffRowY + r)

    setColor(7)
    if self.board.human == PieceColor.white:
      rectfill(hCenter - d, playerRowY - r, hCenter, playerRowY + r)
      setColor(0)
    else:
      rect(hCenter - d, playerRowY - r, hCenter, playerRowY + r)
    printc("O", hCenter - r + 1, playerRowY - 2)

    setColor(7)
    if self.board.human == PieceColor.black:
      rectfill(hCenter, playerRowY - r, hCenter + d, playerRowY + r)
      setColor(0)
    else:
      rect(hCenter, playerRowY - r, hCenter + d, playerRowY + r)
    printc("X", hCenter + r + 1, playerRowY - 2)

    setColor(7)
    printc("CHECKERS", hCenter, padding)
    printc("easy", hCenter - (2*d) - 1, diffRowY - 3)
    printc("medium", hCenter + 1, diffRowY - 3)
    printc("hard", hCenter + (2*d) + 3, diffRowY - 3)
    printc("Start", hCenter + 1, (screenHeight - padding) - 3)

  proc isInBounds*(pos: (int, int), square: Square): bool =
    if (pos[0] >= square.x and pos[0] <= square.x1) and (pos[1] >= square.y and pos[1] <= square.y1):
      result = true

  proc isOutOfBounds*(pos: (int, int), square: Square): bool =
    if (pos[0] <= square.x or pos[0] >= square.x1) or (pos[1] <= square.y or pos[1] >= square.y1):
      result = true

  proc drawHelpButton* =
    setColor(7)
    boxfill(118, 118, 7, 7)
    setColor(0)
    printc("?", 122, 119)

  # proc displayClues* =
  #   if self.showClues:
  #     let pos = self.board.getBestMove(self.board.human)
  #     self.drawPiece(self.board.getClueValue(self.board.human), self.gridBounds[pos.i])

  proc displayRules* =
    if self.showRules:
      setColor(0)
      rectfill(16, 16, 112, 112)
      setColor(7)
      rect(14, 16, 114, 112)
      printc("Rules:", screenWidth div 2, 26)
      printc("You may make a move", screenWidth div 2, 40)
      printc("where white hasn't.", screenWidth div 2, 48)
      printc("You win if you can get", screenWidth div 2, 64)
      printc("three of your symbols", screenWidth div 2, 72)
      printc("in a row, horizontally,", (screenWidth div 2) + 2, 80)
      printc("vertically, or", screenWidth div 2, 88)
      printc("diagonally.", screenWidth div 2, 96)

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