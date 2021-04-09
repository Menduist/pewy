import
  nimgl/[glfw],
  glm, math,
  pewy, gamemap, renderer

proc keyProc(window: GLFWWindow, key: int32, scancode: int32,
             action: int32, mods: int32): void {.cdecl.} =
  var self = addr gPewy.pinput
  if action == GLFWPress:
    case key:
    of GLFWKey.ESCAPE:
      window.setWindowShouldClose(true)
    of GLFWKey.Period:
      self.blockSelection += 1
      if self.blockSelection > 5:
        self.blockSelection = 1
    of GLFWKey.Comma:
      self.orientation += 1
      if self.orientation > 3:
        self.orientation = 0
    else: discard

func getMouseBlockLocation(p: var Pewy): int =
  var posX, posY: float64
  p.window.getCursorPos(addr posX, addr posY)

  let worldCursorPosition = p.render.screenToWorld(vec2(posX, posY))
  let truncedCursorPosition = vec2[float32](trunc(worldCursorPosition.x), trunc(worldCursorPosition.y))

  p.map.getBlockIndex(int truncedCursorPosition.x, int truncedCursorPosition.y)

iterator blocksInSelection*(p: var Pewy): Vec2[int] =
  let startPosIndex = if gPewy.pinput.startBlock >= 0: gPewy.pinput.startBlock else: gPewy.pinput.endBlock
  var
    endPos = p.map.getBlockLocation(p.pinput.endBlock)
    startPos = p.map.getBlockLocation(startPosIndex)
    minPos = min(endPos, startPos)
    maxPos = max(endPos, startPos)

  for x in int(minPos.x)..int(maxPos.x):
    for y in int(minPos.y)..int(maxPos.y):
      yield vec2(x, y)


proc buildBlocks(p: var Pewy) =
  for b in blocksInSelection(p):
    let blockId = p.map.getBlockIndex(b.x, b.y)
    if p.map.data[blockId].blockType == bEngine:
      p.map.createShip(blockId)
    else:
      p.map.setBlockValue(blockId, int16(p.pinput.blockSelection), p.pinput.orientation)

proc updateInput*(p: var Pewy) =
  let cursorBlockPosition = p.getMouseBlockLocation()

  p.pinput.endBlock = cursorBlockPosition

  if cursorBlockPosition < 0 or cursorBlockPosition >= gPewy.map.data.len:
    p.pinput.endBlock = -1
    return

  if gPewy.window.getMouseButton(GLFWMouseButton.Button1) > 0:
    if p.pinput.startBlock < 0:
      p.pinput.startBlock = cursorBlockPosition
  elif p.pinput.startBlock >= 0:
    p.buildBlocks
    p.pinput.startBlock = -1

  if gPewy.window.getMouseButton(GLFWMouseButton.Button2) > 0:
    p.map.setBlockValue(cursorBlockPosition, 0)


proc createInput*(window: GLFWWindow): PInput =
  discard window.setKeyCallback(keyProc)
  result.blockSelection = 1
  result.startBlock = -1
