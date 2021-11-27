import std/options
import pkg/[nico, oolib]

when defined(emscripten):
  proc sleep(ms: int) {.header: "<emscripten.h>", importc: "emscripten_sleep", varargs.}
else:
  import std/os


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
    king*, selected*: bool
    directions*: seq[Direction]

  proc `new`(color: PieceColor, directions: seq[Direction] = @[Direction.northEast, Direction.northWest, Direction.southEast, Direction.southWest], king, selected: bool = false) =
    self.color = color
    self.directions = directions
    self.king = king
    self.selected = selected

  proc makeKing* =
    self.king = true
    self.directions = @[Direction.northEast, Direction.northWest, Direction.southEast, Direction.southWest]


# func for checking equality between `Piece`s
func `==`*(a, b: Piece): bool =
  return system.`==`(a, b) or (a.color == b.color and a.king == b.king)


class pub GridSquare:
  var
    color*: GridColor
    piece*: Option[Piece]
    potential*, clue*: bool

  proc `new`(color: GridColor, piece: Option[Piece] = none(Piece), potential, clue: bool = false) =
    self.color = color
    self.piece = piece
    self.potential = potential
    self.clue = clue


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

  proc getDir*: Option[Direction] =
    ## Returns a Direction for a given `Move` object.

    let
      xDiff = self.x1 - self.x
      yDiff = self.y1 - self.y

    if xDiff == -1 and yDiff == 1:
      return some Direction.northEast
    elif xDiff == -1 and yDiff == -1:
      return some Direction.northWest
    elif xDiff == 1 and yDiff == 1:
      return some Direction.southEast
    elif xDiff == 1 and yDiff == -1:
      return some Direction.southWest

  proc midpoint*: tuple[x: int, y: int] =
    ## Returns the midpoint of a jump move.

    if self.jump:
      let
        x = (self.x + self.x1) div 2
        y = (self.y + self.y1) div 2

      return (x, y)

  proc isCapture* =
    ## Updates `jump` according to whether the move is a capture or not.

    if abs(self.x - self.x1) <= 1 and abs(self.y - self.y1) <= 1:
      self.jump = false
    else:
      self.jump = true

  proc copy*: Move =
    result = newMove(0,0,0,0)
    result.x = self.x
    result.y = self.y
    result.x1 = self.x1
    result.y1 = self.y1


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
    echo ""

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
            self.grid[x].add newGridSquare(GridColor.dark, some newPiece(color = self.ai, @[Direction.southEast, Direction.southWest]))
          elif x >= self.dimension - populate and x < self.dimension:
            self.grid[x].add newGridSquare(GridColor.dark, some newPiece(color = self.human, @[Direction.northEast, Direction.northWest]))
          else:
            self.grid[x].add newGridSquare(GridColor.dark)

  proc getPlayerPieces*(player: PieceColor, grid: seq[seq[GridSquare]]): seq[tuple[x: int, y: int]] =
    ## Returns a sequence of coordinates for each piece a given player has on the grid

    for x in 0 ..< self.dimension:
      for y in 0 ..< self.dimension:
        if grid[x][y].piece.isSome():
          if grid[x][y].piece.get().color == player:
            result.add (x, y)

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

  proc getJump*(move: Move, direction: Direction): Move =
    ## Returns a jump move, one grid square ahead of the current move.

    var newMove = self.nextSquare(move.x1, move.y1, direction)
    newMove.x = move.x
    newMove.y = move.y
    newMove.jump = true

    return newMove

  proc isMoveLegal*(move: Move, grid: seq[seq[GridSquare]]): bool =
    ## Returns true if a move is possible.

    if move.isPossible(dimension = self.dimension):
      if move.jump:
        if grid[move.x][move.y].piece.isSome() and grid[move.x1][move.y1].piece.isNone():
          let (xMid, yMid) = move.midpoint()
          if grid[xMid][yMid].piece.isSome():
            if grid[xMid][yMid].piece.get().color != grid[move.x][move.y].piece.get().color:
              return true
      else:
        if grid[move.x1][move.y1].piece.isNone():
          let dir = move.getDir()
          if dir.isSome():
            if dir.get() in grid[move.x][move.y].piece.get().directions:
              return true

  proc getCapture*(move: Move, direction: Direction, grid: seq[seq[GridSquare]]): Option[Move] =
    ## Returns a `Move` object if a capture is possible.

    let capture = self.getJump(move, direction)
    if self.isMoveLegal(capture, grid):
      return some capture

  proc getMove*(x, y: int, direction: Direction, grid: seq[seq[GridSquare]]): seq[Move] =
    ## Returns a sequence of `Move` object given a coordinate and a `Direction`

    let move = self.nextSquare(x, y, direction)
    if self.isMoveLegal(move, grid):
      return @[move]
    elif move.isPossible(dimension = self.dimension):
      if grid[move.x1][move.y1].piece.isSome():
        let capture = self.getCapture(move, direction, grid)

        if capture.isSome():
          return @[capture.get()]

  proc getMoves*(x, y: int, grid: seq[seq[GridSquare]]): seq[Move] =
    ## Returns a sequence of `Move` objects for a given coordinate.
    ## If captures are available, only they are returned.

    var
      moves, captures: seq[Move]

    if grid[x][y].piece.isSome():
      for direction in grid[x][y].piece.get().directions:
        for move in self.getMove(x, y, direction, grid):
          if move.jump == true:
            captures &= move
          else:
            moves &= move

    if captures.len > 0:
      return captures
    else:
      return moves

  proc getPlayerMoves*(player: PieceColor, grid: seq[seq[GridSquare]]): seq[Move] =
    ## Returns a sequence of `Move`s for each move a given player can make on the grid.

    var
      moves, captures: seq[Move]

    for (x, y) in self.getPlayerPieces(player, grid):
      for move in self.getMoves(x, y, grid):
        if move.jump == true:
          captures &= move
        else:
          moves &= move

    if captures.len > 0:
      return captures
    else:
      return moves

  proc cleanGrid* =
    ## Removes "potential" pieces from the grid, which are placed when a mouse hovers on the grid when a piece is selected.

    for x in 0 ..< self.dimension:
      for y in 0 ..< self.dimension:
        if self.grid[x][y].potential:
          self.grid[x][y].potential = false

  proc opposingPlayer*(player: PieceColor): PieceColor =
    if player == PieceColor.black:
      return PieceColor.white
    elif player == PieceColor.white:
      return PieceColor.black

  proc changeTurn* =
    self.turn = self.opposingPlayer(self.turn)

  proc move*(move: Move, grid: seq[seq[GridSquare]]) =
    ## Moves a piece on the grid, given a `Move` object and a grid.
    ## Also changes the current turn, and can account for kings, multi-leg captures.

    if grid[move.x][move.y].piece.isSome():
      grid[move.x1][move.y1].piece = grid[move.x][move.y].piece
      grid[move.x][move.y].piece = none(Piece)

      if grid[move.x1][move.y1].piece.get().color == self.human and move.x1 == 0 or grid[move.x1][move.y1].piece.get().color == self.ai and move.x1 == self.dimension - 1:
        grid[move.x1][move.y1].piece.get().makeKing()

      if move.jump:
        let midpoint = move.midpoint()
        if grid[midpoint.x][midpoint.y].piece.get().king == true:
          grid[move.x1][move.y1].piece.get().king = true
        grid[midpoint.x][midpoint.y].piece = none(Piece)
        let moves = self.getMoves(move.x1, move.y1, grid)
        if moves != @[]:
          if moves[0].jump:
            if moves.len == 1:
              sleep(600)
              self.move(moves[0], grid)

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

  # proc evaluatePieces*(
  #   coords: seq[tuple[x: int, y: int]],
  #   grid: seq[seq[GridSquare]]
  # ): tuple[pieces: int, kings: int] =
  #   var
  #     pieces, kings = 0
  #   for (x, y) in coords:
  #     if grid[x][y].piece.get().king:
  #       inc pieces
  #     else:
  #       inc kings
  #   return (pieces, kings)

  # proc evaluate*(
  #   maximisingPieces, minimisingPieces: seq[tuple[x: int, y: int]],
  #   grid: seq[seq[GridSquare]]
  # ): int =

  #   let
  #     (maxPieces, maxKings) = self.evaluatePieces(maximisingPieces, grid)
  #     (minPieces, minKings) = self.evaluatePieces(minimisingPieces, grid)

  #   return (maxPieces - minPieces) + ((maxKings - minKings) div 2)

  proc minimax*(
    player: PieceColor,
    grid: seq[seq[GridSquare]],
    depth: int,
    maximising: bool,
    alpha, beta: BiggestInt
  ): Move =
    var
      gridCopy: seq[seq[GridSquare]]
      minMove = newMove(-1, -1, -1, -1, score = beta)
      maxMove = newMove(-1, -1, -1, -1, score = alpha)
      currentMove: Move
      alpha = alpha
      beta = beta

    let (gameOver, winner) = self.isGameOver(grid)

    if gameOver:
      if winner.isSome():
        if winner.get() == player and maximising:
          return newMove(-1, -1, -1, -1, score = 1, depth = depth)
        else:
          return newMove(-1, -1, -1, -1, score = -1, depth = depth)
      else:
        return newMove(-1, -1, -1, -1, score = 0, depth = depth)

    if maximising:
      for move in self.getPlayerMoves(player, grid):
        gridCopy = deepcopy(grid)
        self.move(move, gridCopy)

        # if depth == ord self.difficulty:
        #   break
        currentMove = self.minimax(self.opposingPlayer(player), gridCopy, depth + 1, false, alpha, beta)
        currentMove = move.copy()
        if maxMove.x == -1 or currentMove.score > maxMove.score:
          maxMove = currentMove.copy()
          maxMove.score = currentMove.score
          maxMove.depth = depth
          alpha = max(currentMove.score, alpha)

        if alpha >= beta:
          break
    else:
      for move in self.getPlayerMoves(player, grid):
        gridCopy = deepcopy(grid)
        self.move(move, gridCopy)

        # if depth == ord self.difficulty:
        #   break
        currentMove = self.minimax(self.opposingPlayer(player), gridCopy, depth + 1, true, alpha, beta)
        currentMove = move.copy()
        if minMove.x == -1 or currentMove.score < minMove.score:
          minMove = currentMove.copy()
          minMove.score = currentMove.score
          minMove.depth = depth
          beta = min(currentMove.score, beta)

        if alpha >= beta:
          break

    if depth == 0:
      return currentMove

  proc moveAI* =
    ## Makes best move
    let move = self.minimax(self.ai, self.grid, depth = 0, true, alpha = low(BiggestInt), beta = high(BiggestInt))
    sleep(600)
    self.move(move, self.grid)

  # proc randMoveAI* =
  #   ## Makes random moves.

  #   let
  #     moves = self.getPlayerMoves(self.ai, self.grid)
  #     randMove = sample moves
  #   os.sleep(600)
  #   self.move(randMove, self.grid)


class pub Checkers:
  var
    gridBounds*: seq[seq[Square]]
    gridSquare*: Square
    board*: Board
    offset* = 32
    size* = 24
    selected* = none tuple[x: int, y: int]
    started* = false
    showRules* = false
    showHints* = true
    showClues* = false
    outOfBounds* = false
    successfulMove* = false

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

  proc drawPiece*(piece: Piece, gridBound: Square, offset = 5) =
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
    if piece.selected:
      setColor(11)
      ellipsefill(x2, y2, rx + 1, ry + 1)

    if piece.color == PieceColor.black:
      setColor(4)
      ellipsefill(x2, y2, rx, ry)
      setColor(15)
      ellipsefill(x2, y2 - 1, rx, ry - 1)
    elif piece.color == PieceColor.white:
      setColor(6)
      ellipsefill(x2, y2, rx, ry)
      setColor(7)
      ellipsefill(x2, y2 - (offset div 4), rx, ry - (offset div 4))

    if piece.king:
      setColor(9)
      printc("K", x2 + 1, y2 - 3)


  ## Returns a grid index from a mouse position
  proc xyToGrid*(pos: tuple[y: int, x: int]): (int, int) =  ((pos.x - self.offset) div self.size, (pos.y - self.offset) div self.size)

  proc deselect*(selection: tuple[x: int, y: int]) =
    self.board.grid[selection.x][selection.y].piece.get().selected = false
    self.selected = none tuple[x: int, y: int]

  proc select*(selection: tuple[x: int, y: int]) =
    ## Selects a piece

    let (x, y) = selection

    if self.selected.isNone():
      if self.board.grid[x][y].piece.isSome():
        if self.board.grid[x][y].piece.get().color == self.board.turn:
          self.board.grid[x][y].piece.get().selected = true
          self.selected = some selection
    else:
      if self.board.grid[x][y].piece.isSome():
        if self.board.grid[x][y].piece.get().color == self.board.turn:
          self.deselect (self.selected.get().x, self.selected.get().y)
          self.select (x, y)
      else:
        var move = newMove(self.selected.get().x, self.selected.get().y, x, y)
        move.isCapture()
        if move in self.board.getPlayerMoves(self.board.human, self.board.grid):
          self.deselect (move.x, move.y)
          self.board.move(move, self.board.grid)
          self.successfulMove = true
        else:
          self.successfulMove = false

  proc drawStartPage* =
    cls()
    let
      hCenter = screenWidth div 2
      padding = 20
      r = 12
      d = r * 2
      diffRowY = padding * 4
      playerRowY = padding * 6
      hintRowY = padding * 8

    setColor(3)
    rect(hCenter - d, (screenHeight - 2*padding) - r, hCenter + d, (screenHeight - 2*padding) + r)

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
      rectfill(hCenter - 2*d, playerRowY - r, hCenter, playerRowY + r)
      setColor(0)
    else:
      rect(hCenter - 2*d, playerRowY - r, hCenter, playerRowY + r)
    printc("white", hCenter - d + 1, playerRowY - 2)

    setColor(7)
    if self.board.human == PieceColor.black:
      rectfill(hCenter, playerRowY - r, hCenter + 2*d, playerRowY + r)
      setColor(0)
    else:
      rect(hCenter, playerRowY - r, hCenter + 2*d, playerRowY + r)
    printc("black", hCenter + d + 1, playerRowY - 2)

    setColor(7)
    printc("Hints:", hCenter + 2, hintRowY - r)
    if self.showHints:
      rectfill(hCenter - d, hintRowY, hCenter, hintRowY + d)
      setColor(0)
    else:
      rect(hCenter - d, hintRowY, hCenter, hintRowY + d)
    printc("ON", hCenter - r + 1, hintRowY + r - 2)

    setColor(7)
    if not self.showHints:
      rectfill(hCenter, hintRowY, hCenter + d, hintRowY + d)
      setColor(0)
    else:
      rect(hCenter, hintRowY, hCenter + d, hintRowY + d)
    printc("OFF", hCenter + r + 1, hintRowY + r - 2)

    setColor(7)
    printc("CHECKERS", hCenter, padding * 2)
    printc("easy", hCenter - (2*d) - 1, diffRowY - 3)
    printc("medium", hCenter + 1, diffRowY - 3)
    printc("hard", hCenter + (2*d) + 3, diffRowY - 3)
    printc("Start", hCenter + 1, (screenHeight - padding*2) - 3)

  proc isInBounds*(pos: (int, int), square: Square): bool =
    if (pos[0] >= square.x and pos[0] <= square.x1) and (pos[1] >= square.y and pos[1] <= square.y1):
      result = true

  proc isOutOfBounds*(pos: (int, int), square: Square): bool =
    if (pos[0] <= square.x or pos[0] >= square.x1) or (pos[1] <= square.y or pos[1] >= square.y1):
      result = true

  proc drawHelpButton* =
    setColor(7)
    boxfill(246, 246, 7, 7)
    setColor(0)
    printc("?", 250, 247)

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