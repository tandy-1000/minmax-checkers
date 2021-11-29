import std/unittest
import std/options
import pkg/oolib


type
  GridColor* = enum
    dark = "⬛", light = "⬜"
  PieceColor* = enum
    black = "⚫", white = "🟤"
  Direction* = enum
   northEast, northWest, southEast, southWest


class pub Piece:
  var
    color*: PieceColor
    king*, potential*, clue*: bool

  proc `new`(color: PieceColor, king, potential, clue: bool = false) =
    self.color = color
    self.king = king
    self.potential = potential
    self.clue = clue

  proc makeKing* =
    self.king = true


# func for checking equality between Pieces
func `==`*(a, b: Piece): bool =
  return system.`==`(a, b) or (a.color == b.color and a.king == b.king)


class pub GridSquare:
  var
    color*: GridColor
    piece*: Option[Piece]

  proc `new`(color: GridColor, piece: Option[Piece] = none(Piece)) =
    self.color = color
    self.piece = piece

# func for checking equality between GridSquares
func `==`*(a, b: GridSquare): bool =
  return system.`==`(a, b) or (a.color == b.color and a.piece == b.piece)


class pub Move:
  var
    x*, y*, x1*, y1*: int
    jump*: bool = false
    score*: BiggestInt = 0
    depth*: int = 0

  proc isLegal*(dimension: int = 8): bool =
    if (self.x1 >= 0 and self.x1 < dimension) and (self.y1 >= 0 and self.y1 <   dimension):
      return true
    else:
      return false


# func for checking equality between Moves
func `==`*(a, b: Move): bool =
  let assertion = (a.x == b.x and a.x1 == b.x1 and a.y == b.y and a.y1 == b.y1)
  return system.`==`(a, b) or assertion


class pub Board:
  var
    dimension*: int
    grid*: seq[seq[GridSquare]]
    ai*: PieceColor = PieceColor.white
    human*, turn*: PieceColor = PieceColor.black

  proc `new`(dimension: int = 8): Board =
    self.dimension = dimension
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
    ## Returns a Move object for a given direction and coordinate

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
    ## Returns a Move object if a capture is possible

    let
      x1 = move.x1 + (move.x1 - move.x)
      y1 = move.y1 + (move.y1 - move.y)
      capture = newMove(move.x, move.y, x1, y1, jump = true)

    if capture.isLegal(dimension = self.dimension):
      if self.grid[x1][y1].piece == none(Piece) and self.grid[move.x1][move.y1].piece.isSome():
        if self.grid[move.x1][move.y1].piece.get().color != self.grid[move.x][move.y].piece.get().color:
          return some capture

  proc getMoves*(x, y: int): seq[Move] =
    ## Returns a sequence of Move objects for a given coordinate, including captures

    if self.grid[x][y].piece.isSome():
      var move: Move
      if self.grid[x][y].piece.get().color == self.human and self.grid[x][y].piece.get().king == false:
        for direction in {Direction.northEast, Direction.northWest}:
          move = self.nextSquare(x, y, direction)
          if move.isLegal(dimension = self.dimension):
            if self.grid[move.x1][move.y1].piece.isSome():
              let capture = self.getCapture(move)
              if capture.isSome():
                result.add capture.get()
            else:
              result.add move
      elif self.grid[x][y].piece.get().color == self.ai and self.grid[x][y].piece.get().king == false:
        for direction in {Direction.southEast, Direction.southWest}:
          move = self.nextSquare(x, y, direction)
          if move.isLegal(dimension = self.dimension):
            if self.grid[move.x1][move.y1].piece.isSome():
              let capture = self.getCapture(move)
              if capture.isSome():
                result.add capture.get()
            else:
              result.add move
      else:
        for direction in {Direction.northEast, Direction.northWest, Direction.southEast, Direction.southWest}:
          move = self.nextSquare(x, y, direction)
          if move.isLegal(dimension = self.dimension):
            if self.grid[move.x1][move.y1].piece.isSome():
              let capture = self.getCapture(move)
              if capture.isSome():
                result.add capture.get()
            else:
              result.add move
    else:
      return @[]

  proc getPlayerPieces*(player: PieceColor): seq[(int, int)] =
    for x in 0 ..< self.dimension:
      for y in 0 ..< self.dimension:
        if self.grid[x][y].piece.isSome():
          if self.grid[x][y].piece.get().color == player:
            result.add (x, y)

  proc getPlayerMoves*(player: PieceColor): seq[Move] =
    let pieces = self.getPlayerPieces(player)
    for (x, y) in pieces:
      result &= self.getMoves(x, y)

  proc move*(move: Move) =
    self.grid[move.x1][move.y1].piece = self.grid[move.x][move.y].piece
    self.grid[move.x][move.y].piece = none(Piece)
    if self.grid[move.x1][move.y1].piece.isSome():
      if self.grid[move.x1][move.y1].piece.get().color == self.human and move.x1 == 0 or self.grid[move.x1][move.y1].piece.get().color == self.ai and move.x1 == self.dimension - 1:
        self.grid[move.x1][move.y1].piece.get().makeKing()
    if move.jump:
      let
        xMid = (move.x + move.x1) div 2
        yMid = (move.y + move.y1) div 2
      self.grid[xMid][yMid].piece = none(Piece)

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


suite "Board":
  let board = newBoard(dimension = 4)
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
    board.move board.nextSquare(3, 0, Direction.northEast)
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
    board.move board.nextSquare(0, 3, Direction.southWest)
    let capture = board.getCapture(newMove(2, 1, 1, 2)).get()
    board.move capture
    check board.grid == grid and capture == newMove(2, 1, 0, 3)

  test "Get moves (king)":
    check board.getMoves(0, 3) == @[newMove(0, 3, 1, 2)]

  test "Get moves (top, white)":
    check board.getMoves(0, 1) == @[newMove(0, 1, 1, 2), newMove(0, 1, 1, 0)]

  test "Get moves (bottom, black":
    check board.getMoves(3, 2) == @[newMove(3, 2, 2, 3), newMove(3, 2, 2, 1)]

  test "Get player pieces (ai & human)":
    let
      humanPieces = board.getPlayerPieces(board.human)
      aiPieces = board.getPlayerPieces(board.ai)
    check humanPieces == @[(0, 3), (3, 2)] and aiPieces == @[(0, 1)]

  test "Get player moves (ai)":
    check board.getPlayerMoves(board.ai) == @[newMove(0, 1, 1, 2), newMove(0, 1, 1, 0)]

  # test "Get player moves (human)":
  #   let assertion = board.getPlayerMoves(board.human) == @[newMove(0, 3, 1, 2), newMove(3, 2, 2, 3), newMove(3, 2, 2, 1)]
  #   check assertion

  test "Get player moves (human)":
    check board.getPlayerMoves(board.human) == @[newMove(0, 3, 1, 2), newMove(3, 2, 2, 3), newMove(3, 2, 2, 1)]