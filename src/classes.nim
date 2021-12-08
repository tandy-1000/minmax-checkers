import std/[options, enumerate]
import pkg/[nico, oolib]

when defined(emscripten):
  proc sleep(ms: int) {.header: "<emscripten.h>", importc: "emscripten_sleep", varargs.}
else:
  import std/os


type
  GridColor* = enum
    dark = "⬛", light = "⬜"
  PieceColor* = enum
    brown = "⚫", white = "🟤"
  Direction* = enum
    northEast, northWest, southEast, southWest
  Difficulty* = enum
    easy = 3, medium = 6, hard = 9, impossible = 100


class pub Piece:
  var
    color*: PieceColor
    king*, selected*: bool
    directions*: seq[Direction]

  proc `new`(
    color: PieceColor,
    directions = @[
      Direction.northEast,
      Direction.northWest,
      Direction.southEast,
      Direction.southWest
    ],
    king, selected: bool = false
  ) =

    self.color = color
    self.directions = directions
    self.king = king
    self.selected = selected

  proc makeKing* =
    self.king = true
    self.directions = @[Direction.northEast, Direction.northWest,
        Direction.southEast, Direction.southWest]


# func for checking equality between `Piece`s
func `==`*(a, b: Piece): bool =
  return system.`==`(a, b) or (a.color == b.color and a.king == b.king)


class pub GridSquare:
  var
    color*: GridColor
    piece*: Option[Piece]
    potential*, clue*: bool

  proc `new`(
    color: GridColor,
    piece: Option[Piece] = none(Piece),
    potential, clue: bool = false
  ) =
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
    nextLeg*: seq[Move] = @[]
    jump*: bool = false
    score*: BiggestInt = 0
    depth*: int = 0

  proc isPossible*(dimension: int = 8): bool =
    ## Returns true if the `Move` is possible in the grid's dimensions.

    if self.x > -1 and self.x < dimension and self.y > -1 and self.y <
        dimension and self.x1 > -1 and self.x1 < dimension and self.y1 > -1 and
        self.y1 < dimension:
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

  proc copy*(score: BiggestInt): Move =
    new(result)
    result.x = self.x
    result.y = self.y
    result.x1 = self.x1
    result.y1 = self.y1
    result.jump = self.jump
    result.score = score
    result.nextLeg = self.nextLeg

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
  var str = "x: " & $move.x & " y: " & $move.y & "\nx1: " & $move.x1 & " y1: " &
      $move.y1 & "\njump: " & $move.jump & "\nscore: " & $move.score & "\nnextLegs: \n"
  for leg in move.nextLeg:
    str &= debugMove leg
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
        elif grid[x][y].piece.get().color == PieceColor.brown:
          result.add $PieceColor.brown
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
    gameResult* = none PieceColor
    ai* = PieceColor.white
    human*, turn* = PieceColor.brown
    humanPieces*, aiPieces*: seq[tuple[x: int, y: int]] = @[]
    humanMen*, humanKings*, aiMen*, aiKings * = 0
    difficulty*: Difficulty

  proc `new`(
    difficulty: Difficulty,
    dimension: int = 8
  ): Board =
    ## Initialises a `Board` object.
    ## Populates the board with dark and light squares, and brown and white
    ##  players.

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
            self.grid[x].add newGridSquare(GridColor.dark, some newPiece(
                color = self.ai, @[Direction.southEast, Direction.southWest]))
          elif x >= self.dimension - populate and x < self.dimension:
            self.grid[x].add newGridSquare(GridColor.dark, some newPiece(
                color = self.human, @[Direction.northEast,
                Direction.northWest]))
          else:
            self.grid[x].add newGridSquare(GridColor.dark)

  proc update*(board: Board) =
    ## Stores a data on each piece on the grid in Board object.
    ## Must be called before calling `getPlayerPieces`, `getPlayerMoves`,
    ##  `hasPlayerLost`, `isGameOver`, `evaluate`.

    var
      humanMen, humanKings, aiMen, aiKings = 0
      humanPieces, aiPieces: seq[tuple[x: int, y: int]]

    for x in 0 ..< self.dimension:
      for y in 0 ..< self.dimension:
        if board.grid[x][y].piece.isSome():
          if board.grid[x][y].piece.get().color == board.human:
            if board.grid[x][y].piece.get().king:
              inc humanKings
            else:
              inc humanMen
            humanPieces.add (x, y)
          elif board.grid[x][y].piece.get().color == board.ai:
            if board.grid[x][y].piece.get().king:
              inc aiKings
            else:
              inc aiMen
            aiPieces.add (x, y)

    board.humanPieces = humanPieces
    board.humanMen = humanMen
    board.humanKings = humanKings
    board.aiPieces = aiPieces
    board.aiMen = aiMen
    board.aiKings = aiKings

  proc nextSquare*(
    x, y: int,
    direction: Direction
  ): Move =
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

  proc getJump*(
    move: Move,
    direction: Direction
  ): Move =
    ## Returns a jump move, one grid square ahead of the current move.

    var newMove = self.nextSquare(move.x1, move.y1, direction)
    newMove.x = move.x
    newMove.y = move.y
    newMove.jump = true

    return newMove

  proc isMoveLegal*(
    move: Move,
    grid: seq[seq[GridSquare]]
  ): bool =
    ## Returns true if a move is possible.

    if move.isPossible(dimension = self.dimension):
      if move.jump:
        if grid[move.x][move.y].piece.isSome() and
            grid[move.x1][move.y1].piece.isNone():
          let (xMid, yMid) = move.midpoint()
          if grid[xMid][yMid].piece.isSome():
            if grid[xMid][yMid].piece.get().color !=
                grid[move.x][move.y].piece.get().color:
              return true
      else:
        if grid[move.x1][move.y1].piece.isNone():
          let dir = move.getDir()
          if dir.isSome():
            if dir.get() in grid[move.x][move.y].piece.get().directions:
              return true

  proc getCapture*(
    move: Move,
    direction: Direction,
    grid: seq[seq[GridSquare]]
  ): Option[Move] =
    ## Returns a `Move` object if a capture is possible.

    let capture = self.getJump(move, direction)

    if self.isMoveLegal(capture, grid):
      return some capture

  proc move*(
    move: Move,
    grid: seq[seq[GridSquare]],
    simulation = false
  ) =
    ## Moves a piece on the grid, given a `Move` object and a grid.
    ## Also changes the current turn, and can account for kings, multi-leg
    ##  captures.

    ## if move is possible...
    if grid[move.x][move.y].piece.isSome():
      ## make move
      grid[move.x1][move.y1].piece = grid[move.x][move.y].piece
      grid[move.x][move.y].piece = none(Piece)

      ## king at baseline
      if grid[move.x1][move.y1].piece.get().color == self.human and move.x1 ==
          0 or grid[move.x1][move.y1].piece.get().color == self.ai and
          move.x1 == self.dimension - 1:
        grid[move.x1][move.y1].piece.get().makeKing()

      if move.jump:
        let midpoint = move.midpoint()

        ## regicide
        if grid[midpoint.x][midpoint.y].piece.get().king == true:
          grid[move.x1][move.y1].piece.get().makeKing()

        ## capture piece
        grid[midpoint.x][midpoint.y].piece = none(Piece)

  proc getNextLeg*(
    capture: Move,
    grid: seq[seq[GridSquare]]
  ) =
    ## Returns a `Move` object if another capture is possible

    ## make grid copy
    let gridCopy = deepcopy(grid)
    ## simulate capture on grid copy
    self.move(capture, gridCopy, simulation = true)
    ## get next leg of captures on simulation
    for direction in gridCopy[capture.x1][capture.y1].piece.get().directions:
      ## get next move
      let nextMove = self.nextSquare(capture.x1, capture.y1, direction)
      if nextMove.isPossible(dimension = self.dimension):
        ## if there is a piece in move end position
        if gridCopy[nextMove.x1][nextMove.y1].piece.isSome():
          ## if there is a capture, add it to the next leg
          let nextCapture = self.getCapture(nextMove, direction, gridCopy)
          if nextCapture.isSome():
            self.getNextLeg(nextCapture.get(), gridCopy)
            capture.nextLeg &= nextCapture.get()

  proc followNextLeg*(
    move: Move,
    grid: seq[seq[GridSquare]],
    simulation: bool
  ) =
    ## Follows the next capture leg if there is only one next leg.
    var nextLeg = move.nextLeg
    while nextLeg != @[]:
      if nextLeg.len == 1:
        if not simulation:
          sleep(600)
        self.move(move.nextLeg[0], grid, simulation = simulation)
        if nextLeg[0].nextLeg != @[]:
          nextLeg = nextLeg[0].nextLeg
        else:
          nextLeg = @[]
      else:
        nextLeg = @[]

  proc getMove*(
    x, y: int,
    direction: Direction,
    grid: seq[seq[GridSquare]]
  ): seq[Move] =
    ## Returns a sequence of `Move` object given a coordinate and a `Direction`

    let move = self.nextSquare(x, y, direction)

    if self.isMoveLegal(move, grid):
      return @[move]
    elif move.isPossible(dimension = self.dimension):
      if grid[move.x1][move.y1].piece.isSome():
        let capture = self.getCapture(move, direction, grid)
        if capture.isSome():
          self.getNextLeg(capture.get(), grid)
          return @[capture.get()]

  proc getMoves*(
    x, y: int,
    grid: seq[seq[GridSquare]]
  ): seq[Move] =
    ## Returns a sequence of `Move` objects for a given coordinate.
    ## If captures are available, only they are returned.

    var moves, captures: seq[Move]

    if grid[x][y].piece.isSome():
      for direction in grid[x][y].piece.get().directions:
        for move in self.getMove(x, y, direction, grid):
          if move.jump == true:
            captures &= move
          else:
            moves &= move

    if captures != @[]:
      return captures
    else:
      return moves

  proc getPlayerPieces*(player: PieceColor): seq[tuple[x: int, y: int]] =
    ## Returns a given players pieces on the grid.
    ## Must call `update` first.

    if player == self.human:
      return self.humanPieces
    elif player == self.ai:
      return self.aiPieces

  proc getPlayerMoves*(
    player: PieceColor,
    grid: seq[seq[GridSquare]]
  ): seq[Move] =
    ## Returns a sequence of `Move`s for each move a given player can make on
    ## the grid.
    ## Must call `update` first.

    var moves, captures: seq[Move]

    for (x, y) in self.getPlayerPieces(player):
      for move in self.getMoves(x, y, grid):
        if move.jump == true:
          captures &= move
        else:
          moves &= move

    if captures != @[]:
      return captures
    else:
      return moves

  proc opposingPlayer*(player: PieceColor): PieceColor =
    ## Returns the opposing player given a player.

    if player == PieceColor.brown:
      return PieceColor.white
    elif player == PieceColor.white:
      return PieceColor.brown

  proc changeTurn* =
    ## Changes the current turn to the opposing player

    self.turn = self.opposingPlayer(self.turn)

  proc hasPlayerLost*(
    player: PieceColor,
    grid: seq[seq[GridSquare]]
  ): bool =
    ## Returns true if a player has no pieces or moves left, otherwise false.
    ## Must call `update` first.

    if self.getPlayerMoves(player, grid) == @[]:
      return true
    else:
      return false

  proc isGameOver*(board: Board): (bool, Option[PieceColor]) =
    ## Returns `(gameOver, Option[PieceColor])`.
    ## `gameOver` if a player has no pieces or moves left.
    ## `PieceColor` is returned if there is a winner.
    ## Must call `update` first.

    var
      gameOver = false
      winner = none PieceColor

    let
      humanLoss = self.hasPlayerLost(self.human, board.grid)
      aiLoss = self.hasPlayerLost(self.ai, board.grid)

    if humanLoss or aiLoss:
      gameOver = true
      if humanLoss:
        winner = some self.ai
      elif aiLoss:
        winner = some self.human

    return (gameOver, winner)

  proc evaluate*(
    maxPlayer: PieceColor,
    board: Board
  ): BiggestInt =
    ## Evaluates the board for a given `maxPlayer`.

    if maxPlayer == board.human:
      return (board.humanMen - board.aiMen) + ((board.humanKings -
          board.aiKings) * 2)
    elif maxPlayer == board.ai:
      return (board.aiMen - board.humanMen) + ((board.aiKings -
          board.humanKings) * 2)

  proc minimax*(
    player: PieceColor,
    board: Board,
    depth: int,
    maximising = true,
    alpha = low(BiggestInt),
    beta = high(BiggestInt)
  ): Move =
    var
      maxPlayer, minPlayer: PieceColor
      boardCopy: Board
      minMove = newMove(-1, -1, -1, -1, score = beta, depth = depth)
      maxMove = newMove(-1, -1, -1, -1, score = alpha, depth = depth)
      currentMove = newMove(-1, -1, -1, -1, score = 0, depth = depth)
      alpha = alpha
      beta = beta

    if maximising:
      maxPlayer = player
      minPlayer = self.opposingPlayer(player)
    else:
      maxPlayer = self.opposingPlayer(player)
      minPlayer = player

    self.update(board)
    let (gameOver, winner) = self.isGameOver(board)

    if depth == 0 or gameOver:
      if winner.isSome():
        if winner.get() == player and maximising:
          return newMove(-1, -1, -1, -1, score = 10 * self.evaluate(maxPlayer, board))
        else:
          return newMove(-1, -1, -1, -1, score = -10 * self.evaluate(minPlayer, board))
      elif gameOver:
        return newMove(-1, -1, -1, -1, score = 0, depth = depth)
      else:
        if maximising:
          return newMove(-1, -1, -1, -1, score = self.evaluate(maxPlayer,
              board), depth = depth)
        else:
          return newMove(-1, -1, -1, -1, score = -1 * self.evaluate(minPlayer,
              board), depth = depth)

    if maximising:
      for move in self.getPlayerMoves(maxPlayer, board.grid):
        boardCopy = deepcopy(board)
        self.move(move, boardCopy.grid, simulation = true)
        self.followNextLeg(move, boardCopy.grid, simulation = true)
        currentMove = self.minimax(minPlayer, boardCopy, depth - 1,
            not maximising, alpha, beta)
        currentMove = move.copy(currentMove.score)
        if maxMove.x == -1 or currentMove.score > maxMove.score:
          maxMove = currentMove
          alpha = max(currentMove.score, alpha)

        if alpha >= beta:
          break

      return maxMove
    else:
      for move in self.getPlayerMoves(minPlayer, board.grid):
        boardCopy = deepcopy(board)
        self.move(move, boardCopy.grid, simulation = true)
        self.followNextLeg(move, boardCopy.grid, simulation = true)
        currentMove = self.minimax(maxPlayer, boardCopy, depth - 1,
            not maximising, alpha, beta)
        currentMove = move.copy(currentMove.score)
        if minMove.x == -1 or currentMove.score < minMove.score:
          minMove = currentMove
          beta = min(currentMove.score, beta)

        if alpha >= beta:
          break

      return minMove

  proc moveHuman*(move: Move) =
    ## Makes human move

    self.move(move, self.grid)
    self.followNextLeg(move, self.grid, simulation = false)
    if move.nextLeg.len <= 1:
      self.changeTurn()

  proc moveAI*(
    maxPlayer: PieceColor,
    depth = ord self.difficulty
  ) =
    ## Makes best move

    let move = self.minimax(maxPlayer, self, depth = depth)
    self.move(move, self.grid)
    self.followNextLeg(move, self.grid, simulation = false)
    self.changeTurn()


class pub Square:
  var
    x*, y*, x1*, y1*: int


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

  proc drawPiece*(
    piece: Piece,
    gridBound: Square,
    clue = false,
    offset = 5
  ) =
    ## Draws a piece on the board.

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
    elif clue:
      setColor(6)
      ellipsefill(x2, y2, rx + 1, ry + 1)

    if piece.color == PieceColor.brown:
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

  proc drawBoard* =
    # Draws the Checkers board.

    var square: Square

    for x in 0 ..< self.board.dimension:
      for y in 0 ..< self.board.dimension:
        square = self.gridBounds[x][y]
        if self.board.grid[x][y].color == GridColor.light:
          setColor(7)
          rectfill(square.x, square.y, square.x1, square.y1)
        else:
          setColor(3)
          rectfill(square.x, square.y, square.x1, square.y1)

        if self.board.grid[x][y].potential:
          if self.board.grid[x][y].piece.isNone():
            self.drawPiece(newPiece(self.board.turn), square)
          elif self.selected.isSome():
            self.drawPiece(newPiece(self.board.turn, king = self.board.grid[
                self.selected.get().x][self.selected.get().y].piece.get().king), square)
        elif self.board.grid[x][y].clue:
          self.drawPiece(newPiece(self.board.turn), square, clue = true)
        else:
          if self.board.grid[x][y].piece.isSome():
            self.drawPiece(self.board.grid[x][y].piece.get(), square)

  proc cleanGrid*(clue = false) =
    ## Removes "potential" pieces from the grid, which are placed when a mouse
    ## hovers on the grid when a piece is selected.

    for x in 0 ..< self.board.dimension:
      for y in 0 ..< self.board.dimension:
        if self.board.grid[x][y].potential:
          self.board.grid[x][y].potential = false
        elif clue and self.board.grid[x][y].clue and not self.showClues:
          self.board.grid[x][y].clue = false

  ## Returns a grid index from a mouse position
  proc xyToGrid*(pos: tuple[y: int, x: int]): (int, int) = ((pos.x -
    self.offset) div self.size, (pos.y - self.offset) div self.size)

  proc find*(mov: Move, moves: seq[Move]): int =
    ## Find a `Move` object in a sequence of `Move`s
    var ind = -1
    for i, move in enumerate(moves):
      if move == mov:
        ind = i
    return ind

  proc deselect*(selection: tuple[x: int, y: int]) =
    ## Deselects a piece on the board.

    self.board.grid[selection.x][selection.y].piece.get().selected = false
    self.selected = none tuple[x: int, y: int]

  proc select*(selection: tuple[x: int, y: int]) =
    ## Selects a piece on the board.

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
        let
          playerMoves = self.board.getPlayerMoves(self.board.human,
              self.board.grid)
          ind = self.find(move, playerMoves)
        if ind != -1:
          move = playerMoves[ind]
          self.deselect (move.x, move.y)
          self.board.moveHuman(move)
          self.successfulMove = true
        else:
          self.successfulMove = false

  proc drawStartPage* =
    ## Draws the start page.

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
    rect(hCenter - d, (screenHeight - 2*padding) - r, hCenter + d, (
        screenHeight - 2*padding) + r)

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
    if self.board.human == PieceColor.brown:
      rectfill(hCenter, playerRowY - r, hCenter + 2*d, playerRowY + r)
      setColor(0)
    else:
      rect(hCenter, playerRowY - r, hCenter + 2*d, playerRowY + r)
    printc("brown", hCenter + d + 1, playerRowY - 2)

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

  proc isInBounds*(
    pos: (int, int),
    square: Square
  ): bool =
    ## Checks whether a mouse coordinate within a given `Square`'s bounds.

    if (pos[0] >= square.x and pos[0] <= square.x1) and (pos[1] >= square.y and
        pos[1] <= square.y1):
      result = true

  proc isOutOfBounds*(
    pos: (int, int),
    square: Square
  ): bool =
    ## Checks whether a mouse coordinate outside of a given `Square`'s bounds.

    if (pos[0] <= square.x or pos[0] >= square.x1) or (pos[1] <= square.y or
        pos[1] >= square.y1):
      result = true

  proc drawHelpButton* =
    ## Draws the help button.

    setColor(7)
    boxfill(246, 246, 7, 7)
    setColor(0)
    printc("?", 250, 247)

  proc displayClues* =
    ## Gets and displays a clue for the human player.

    if self.showClues:
      let move = self.board.minimax(self.board.human, self.board,
        depth = ord self.board.difficulty)
      self.board.grid[move.x1][move.y1].clue = true

  proc displayRules* =
    ## Draws the rules page.

    if self.showRules:
      let midpoint = screenHeight div 2
      setColor(0)
      rectfill(16, midpoint - 48, 240, midpoint + 48)
      setColor(7)
      rect(14, midpoint - 48, 240, midpoint + 48)
      printc("Rules:", screenWidth div 2, midpoint - 40)

      printc("To win, capture all of the opponent's pieces,", screenWidth div 2,
          midpoint - 28)
      printc("or leave them with no legal moves.", screenWidth div 2, midpoint - 20)

      printc("If a capture is possible, you must make it.", screenWidth div 2,
          midpoint - 8)
      printc("If there are multiple captures you", screenWidth div 2, midpoint)
      printc("may choose between them.", screenWidth div 2, midpoint + 8)

      printc("Your men will become kings if they reach the baseline,", (
          screenWidth div 2) + 2, midpoint + 20)
      printc("or capture another king.", screenWidth div 2, midpoint + 28)

  proc gameOverMessage*(
    message: string,
    color: int
  ) =
    ## Draws a game over message.

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
