import std/[random, enumerate]
import pkg/nico
import classes

const
  orgName* = "org"
  appName* = "Checkers"

var c = newCheckers(difficulty = Difficulty.medium)
randomize()

proc gameInit*() =
  loadFont(0, "font.png")

proc gameDraw*() =
  c.started = true
  if not c.started:
    c.drawStartPage()
    c.drawHelpButton()
    c.displayRules()
  else:
    cls()
    setColor(7)
    printc("CHECKERS", screenWidth div 2, 8)

    var color: int
    for i, square in enumerate(c.gridBounds):
      inc color
      if color == 15: color = 0
      setColor(color + 1)

      rect(square.x, square.y, square.x1, square.y1)
      c.drawPiece(c.board.grid[i], square)

    # c.drawHelpButton()
    # c.displayClues()

    if c.outOfBounds:
      setColor(4)
      printc("Please click within the grid!", screenWidth div 2, 120)

    if not c.successfulMove:
      setColor(4)
      printc("This position has been played!", screenWidth div 2, 120)

    if c.board.gameResult == c.board.human:
      c.gameOverMessage("You Win!", 3)
    elif c.board.gameResult == c.board.ai:
      c.gameOverMessage("You Lose!", 4)
    elif c.board.gameResult == GridValue.none and c.board.gameOver == true:
      c.gameOverMessage("Game Over.", 4)

proc gameUpdate*(dt: float32) =
  var
    pos: (int, int)
    pressed = false
  if not c.started:
    pressed = mousebtnp(0)
    if pressed:
      pos = mouse()
      if c.isInBounds(pos, newSquare(27, 44, 49, 56)):
        c.board.difficulty = Difficulty.easy
      elif c.isInBounds(pos, newSquare(50, 44, 78, 56)):
        c.board.difficulty = Difficulty.medium
      elif c.isInBounds(pos, newSquare(79, 44, 101, 56)):
        c.board.difficulty = Difficulty.hard
      elif c.isInBounds(pos, newSquare(52, 74, 64, 86)):
        c.board.human = GridValue.white
        c.board.humanPotential = GridValue.pWhite
        c.board.ai = GridValue.black
        c.board.turn = c.board.human
      elif c.isInBounds(pos, newSquare(64, 74, 76, 86)):
        c.board.human = GridValue.black
        c.board.humanPotential = GridValue.pBlack
        c.board.ai = GridValue.white
        c.board.turn = c.board.human
      elif c.isInBounds(pos, newSquare(52, 102, 76, 114)):
        c.started = true
      elif c.isInBounds(pos, newSquare(118, 118, 125, 125)):
        c.showRules = not c.showRules
  else:
    c.board.cleanGrid()
    c.board.availablePositions = c.board.getAvailablePositions(c.board.grid)
    (c.board.gameOver, c.board.gameResult) = c.board.isGameOver(c.board.grid, c.board.availablePositions)
    if c.board.turn == c.board.human and c.board.gameOver == false:
      pos = mouse()
      if not c.isOutOfBounds(pos, c.gridSquare):
        let
          x = (pos[0] - c.offset) div c.size
          y = (pos[1] - c.offset) div c.size
          i = c.board.xyIndex(x, y)
        if c.board.grid[i] == GridValue.none:
          c.board.grid[i] = c.board.humanPotential

      pressed = mousebtnp(0)
      if pressed:
        pos = mouse()
        if c.isOutOfBounds(pos, c.gridSquare):
          if c.isInBounds(pos, newSquare(118, 118, 125, 125)):
            # c.showClues = not c.showClues
            c.outOfBounds = false
          else:
            c.outOfBounds = true
        else:
          let
            x = (pos[0] - c.offset) div c.size
            y = (pos[1] - c.offset) div c.size
            i = c.board.xyIndex(x, y)
          c.successfulMove = c.board.placePiece(newPosition(i), c.board.human)
          if c.successfulMove:
            c.board.turn = c.board.ai
    elif c.board.turn == c.board.ai and c.board.gameOver == false:
      c.successfulMove = c.board.moveAI(c.board.ai, c.board.difficulty)
      if c.successfulMove:
        c.board.turn = c.board.human

nico.init(orgName, appName)
fixedSize(true)
integerScale(true)
nico.createWindow(appName, 256, 256, 4, false)
nico.run(gameInit, gameUpdate, gameDraw)
