import std/[enumerate, options]
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
      r = (x1 - x) div 2

    setColor(7)
    if self.selected:
      setColor(4):
    elif self.potential:
      setColor(5)
    elif self.clue:
      setColor(3)

    if self.color == PieceColor.black:
      circfill(x2, y2, r)
      setColor(0)
      circfill(x2, y2, r-1)
    elif self.color == PieceColor.white:
      circfill(x2, y2, r)

    if self.king:
      setColor(0)
      printc("K", x2+1, y2-2)


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

  proc isLegal*(dimension: int = 8): bool =
    ## Returns true if the `Move` is possible in the grid's dimensions.

    if (self.x1 >= 0 and self.x1 < dimension) and (self.y1 >= 0 and self.y1 <   dimension):
      return true
    else:
      return false


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

  proc getCapture*(move: Move): Option[Move] =
    ## Returns a `Move` object if a capture is possible.

    let
      x1 = move.x1 + (move.x1 - move.x)
      y1 = move.y1 + (move.y1 - move.y)
      capture = newMove(move.x, move.y, x1, y1, jump = true)

    if capture.isLegal(dimension = self.dimension):
      if self.grid[x1][y1].piece == none(Piece) and self.grid[move.x1][move.y1].piece.isSome():
        if self.grid[move.x1][move.y1].piece.get().color != self.grid[move.x][move.y].piece.get().color:
          return some capture

  proc getMove*(x, y: int, direction: Direction): Option[Move] =
    ## Returns a `Move` object given a coordinate and a `Direction`

    let move = self.nextSquare(x, y, direction)
    if move.isLegal(dimension = self.dimension):
      if self.grid[move.x1][move.y1].piece.isSome():
        let capture = self.getCapture(move)
        if capture.isSome():
          return capture
      else:
        return some move
    else:
      return none Move

  proc getMoves*(x, y: int): seq[Move] =
    ## Returns a sequence of `Move` objects for a given coordinate, including captures

    if self.grid[x][y].piece.isSome():
      var move: Option[Move]
      if self.grid[x][y].piece.get().color == self.human and self.grid[x][y].piece.get().king == false:
        for direction in {Direction.northEast, Direction.northWest}:
          move = self.getMove(x, y, direction)
          if move.isSome():
            result.add move.get()
      elif self.grid[x][y].piece.get().color == self.ai and self.grid[x][y].piece.get().king == false:
        for direction in {Direction.southEast, Direction.southWest}:
          move = self.getMove(x, y, direction)
          if move.isSome():
            result.add move.get()
      else:
        for direction in {Direction.northEast, Direction.northWest, Direction.southEast, Direction.southWest}:
          move = self.getMove(x, y, direction)
          if move.isSome():
            result.add move.get()

  proc getPlayerPieces*(player: PieceColor): seq[tuple[x: int, y: int]] =
    ## Returns a sequence of coordinates for each piece a given player has on the grid

    for x in 0 ..< self.dimension:
      for y in 0 ..< self.dimension:
        if self.grid[x][y].piece.isSome():
          if self.grid[x][y].piece.get().color == player:
            result.add (x, y)

  proc getPlayerMoves*(player: PieceColor): seq[Move] =
    ## Returns a sequence of `Move`s for each move a given player can make on the grid

    let pieces = self.getPlayerPieces(player)
    for (x, y) in pieces:
      result &= self.getMoves(x, y)

  proc cleanGrid* =
    ## Removes "potential" pieces from the grid, which are placed when a mouse hovers on the grid when a piece is selected.

    for x in 0 ..< self.dimension:
      for y in 0 ..< self.dimension:
        if self.grid[x][y].piece.isSome():
          if self.grid[x][y].piece.get().potential:
            self.grid[x][y] = newGridSquare(GridColor.dark)

  proc move*(move: Move): bool =
    ## Moves a piece on the grid, given a `Move` object. Can account for kings and jumps.

    if self.grid[move.x][move.y].piece.isSome():
      self.grid[move.x1][move.y1].piece = self.grid[move.x][move.y].piece
      self.grid[move.x][move.y].piece = none(Piece)

      if self.grid[move.x1][move.y1].piece.get().color == self.human and move.x1 == 0 or self.grid[move.x1][move.y1].piece.get().color == self.ai and move.x1 == self.dimension - 1:
        self.grid[move.x1][move.y1].piece.get().makeKing()

      if move.jump:
        let
          xMid = (move.x + move.x1) div 2
          yMid = (move.y + move.y1) div 2
        self.grid[xMid][yMid].piece = none(Piece)
        return true
    else:
      return false

  # proc hasPlayerWon*(player: GridSquare, grid: seq[GridSquare]): bool =
  #   ## assertions for diagonal wins
  #   let
  #     diagonalWinLeft = grid[0] == player and grid[4] == player and grid[8] == player
  #     diagonalWinRight = grid[2] == player and grid[4] == player and grid[6] == player
  #   if diagonalWinLeft or diagonalWinRight:
  #     result = true

  #   var rowWin, columnWin: bool
  #   for i in 0 ..< self.dimension:
  #     ## assertions for each x / column win
  #     rowWin = grid[i][0] == player and grid[i][1] == player and grid[i][2] == player
  #     columnWin = grid[0][i] == player and grid[1][i] == player and grid[2][i] == player
  #     if rowWin or columnWin:
  #       result = true

  proc opposingPlayer*(player: PieceColor): PieceColor =
    if player == PieceColor.black:
      return PieceColor.white
    elif player == PieceColor.white:
      return PieceColor.black

  proc opposingPlayerGridSq*(gridSq: GridSquare): PieceColor =
    if gridSq.piece.isSome():
      return self.opposingPlayer(gridSq.piece.get().color)

  # proc isGameOver*(grid: seq[seq[GridSquare]]): (bool, Option[PieceColor]) =
  #   # checks whether the board is full
  #   var
  #     humanMoves, aiMoves: seq[Move]
  #     winner: Option[PieceColor]
  #     gameOver = false

  #   let
  #     humanPieces = self.getPlayerPieces(self.human)
  #     aiPieces = self.getPlayerPieces(self.ai)

  #   if
  #   for (x, y) in humanPieces:
  #     humanMoves &= self.getMoves(x, y)

  #   let
  #     humanMoves = self.getPlayerMoves(self.human)
  #     aiMoves = self.getPlayerMoves(self.ai)

  #   if humanMoves.len == 0 and aiMoves.len == 0:
  #     gameOver = true
  #   elif humanMoves.len != 0 and aiMoves.len == 0:


  #   result = (gameOver, winner)


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