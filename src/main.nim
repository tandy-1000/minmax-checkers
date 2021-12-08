import std/[options, coro]
import pkg/nico
import classes

const
  orgName* = "org"
  appName* = "Checkers"

var c = newCheckers(difficulty = Difficulty.medium)

proc gameInit*() =
  loadFont(0, "font.png")

proc gameUpdate*(dt: float32) =
  var
    pos: (int, int)
    pressed = false

  ## checks if the game has started
  if not c.started:
    pressed = mousebtnp(0)
    if pressed:
      pos = mouse()

      ## checks whether the click is within the bounds of the various buttons
      if c.isInBounds(pos, newSquare(55, 63, 101, 87)):
        c.board.difficulty = Difficulty.easy
      elif c.isInBounds(pos, newSquare(102, 63, 154, 87)):
        c.board.difficulty = Difficulty.medium
      elif c.isInBounds(pos, newSquare(155, 63, 201, 87)):
        c.board.difficulty = Difficulty.hard
      elif c.isInBounds(pos, newSquare(80, 108, 128, 132)):
        c.board = newBoard(human = PieceColor.white, ai = PieceColor.brown,
            difficulty = c.board.difficulty)
      elif c.isInBounds(pos, newSquare(128, 108, 176, 132)):
        c.board = newBoard(human = PieceColor.brown, ai = PieceColor.white,
            difficulty = c.board.difficulty)
      elif c.isInBounds(pos, newSquare(104, 204, 152, 228)):
        c.started = true
      elif c.isInBounds(pos, newSquare(246, 246, 252, 252)):
        c.showRules = not c.showRules
      elif c.isInBounds(pos, newSquare(104, 160, 128, 184)):
        c.showHints = true
      elif c.isInBounds(pos, newSquare(128, 160, 152, 184)):
        c.showHints = false
  else:
    c.cleanGrid()
    c.board.update(c.board)
    (c.board.gameOver, c.board.gameResult) = c.board.isGameOver(c.board)

    ## Human turn
    if c.board.turn == c.board.human and c.board.gameOver == false:
      pos = mouse()

      ## Shows hint on hover
      if c.showHints:
        if not c.isOutOfBounds(pos, c.gridSquare) and c.selected.isSome():
          let (x, y) = c.xyToGrid(pos)
          if c.board.grid[x][y].color == GridColor.dark and
            c.board.grid[x][y].piece.isNone():
            let potentialMoves = c.board.getMoves(c.selected.get().x,
                c.selected.get().y, c.board.grid)
            if newMove(c.selected.get().x, c.selected.get().y, x, y) in potentialMoves:
              c.board.grid[x][y].potential = true

      pressed = mousebtnp(0)
      if pressed:
        pos = mouse()

        ## checks whether the mouse click is within the game grid
        ## or within the clue button
        if c.isOutOfBounds(pos, c.gridSquare):
          if c.isInBounds(pos, newSquare(246, 246, 252, 252)):
            c.showClues = not c.showClues
            c.displayClues()
            c.showClues = not c.showClues
            c.outOfBounds = false
          else:
            c.outOfBounds = true
        else:
          c.outOfBounds = false
          c.select c.xyToGrid(pos)
          c.cleanGrid(clue = true)
    elif c.board.turn == c.board.ai and c.board.gameOver == false:
      c.board.moveAI(c.board.ai)

proc gameDraw*() =
  # c.started = true
  if not c.started:
    c.drawStartPage()
    c.drawHelpButton()
    c.displayRules()
  else:
    cls()
    setColor(7)
    printc("CHECKERS", screenWidth div 2, 8)

    c.drawBoard()
    c.drawHelpButton()

    if c.outOfBounds:
      setColor(4)
      printc("Please click within the grid!", screenWidth div 2, 246)

    if not c.successfulMove:
      setColor(4)
      printc("Try another position!", screenWidth div 2, 246)

    if c.board.turn == c.board.human:
      setColor(8)
      printc("Your turn.", screenWidth div 2, 20)
    elif c.board.turn == c.board.ai:
      setColor(9)
      printc("AI's turn.", screenWidth div 2, 20)

    if c.board.gameOver:
      if c.board.gameResult.isSome():
        if c.board.gameResult.get() == c.board.human:
          c.gameOverMessage("You Win!", 3)
        elif c.board.gameResult.get() == c.board.ai:
          c.gameOverMessage("You Lose!", 4)
      else:
        c.gameOverMessage("Game Over.", 4)

nico.init(orgName, appName)
nico.createWindow(appName, 256, 256, 4, false)
nico.run(gameInit, gameUpdate, gameDraw)
