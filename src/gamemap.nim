import
  sequtils,
  glm, sets, algorithm, math

type Ship* = object
  origin: Vec2[int16]
  blocks: seq[Vec2[int16]]

type BlockType* = enum
  bNone, bHull, bDrill, bEngine, bThruster, bTurret

type GameBlock* {.packed.} = object
  blockTile *{.bitsize: 6.}: uint8
  blockOrientation *{.bitsize: 2.}: uint8
  blockType *{.bitsize: 4.}: BlockType

type GameMap* = object
  width*, height*: int
  data*: seq[GameBlock]
  ships*: seq[Ship]

iterator countupordown*[T](a, b: T, step: Positive = 1): T {.inline.} =
  var
    avalue: int = int(a)
    bvalue: int = int(b)
    yieldedValue = addr avalue
    stepvalue: int = int(step)

  if a > b:
    swap(avalue, bvalue)
    yieldedValue = addr bvalue
    stepvalue = -stepvalue

  while avalue <= bvalue:
    yield yieldedValue[]
    inc(yieldedValue[], stepvalue)

proc createGameMap*(width: int, height: int): GameMap =
  result.width = width
  result.height = height
  result.data = newSeqWith[GameBlock](width * height, GameBlock())

func getBlockIndex*(self: GameMap, x: int, y: int): int {.inline.} =
  x + y * self.width

proc setBlockValue*(self: var GameMap, blockId: int, newType: int16, orientation = 0) =
  self.data[blockId].blockTile = uint8(newType)
  self.data[blockId].blockType = BlockType(newType)
  self.data[blockId].blockOrientation = uint8(orientation)

proc setBlockValue*(self: var GameMap, x: int, y: int, newType: int16, orientation = 0) =
  let blockId = self.getBlockIndex(x, y)
  self.setBlockValue(blockId, newType, orientation)

func getBlockLocation*(self: GameMap, blockId: int): Vec2[int16] =
  vec2(int16(blockId %% self.width), int16(blockId div self.width))

iterator neighbors(self: var GameMap, blockId: int, filter: proc): int =
  #TODO use only ID in this function instead of Vec2s
  const offsets = [vec2(int16 1, int16 0), vec2(int16 0, int16 1), vec2(int16 -1, int16 0), vec2(int16 0, int16 -1)]
  var
    open = newSeq[int]()
    closed: HashSet[int]

  open.add(blockId)

  while open.len() > 0:
    let currentBlock = open.pop()
    yield currentBlock
    closed.incl(currentBlock)
    let blockLocation = self.getBlockLocation(currentBlock)
    for offset in offsets:
      let
        newBlockLock = blockLocation + offset
        newBlockId = self.getBlockIndex(newBlockLock.x, newBlockLock.y)

      if newBlockId < 0 or newBlockId >= self.data.len:
        continue
      
      if newBlockId in closed or newBlockId in open:
        continue

      if filter(self, newBlockId) == false:
        continue

      open.add(newBlockId)

func getShipVelocity(self: var GameMap, ship: ptr Ship): Vec2[int16] =
  const velocities = [vec2(int16 0, int16 1), vec2(int16 -1, int16 0), vec2(int16 0, int16 -1), vec2(int16 1, int16 0)]
  for b in ship.blocks:
    let
      blockPosition = ship.origin + b
      blockId = self.getBlockIndex(blockPosition.x, blockPosition.y)

    if self.data[blockId].blockType == bThruster:
      result += velocities[self.data[blockId].blockOrientation]

func isBlockInShip(self: var GameMap, ship: ptr Ship, b: Vec2[int16]): bool =
  let relPos = b - ship.origin
  relPos in ship.blocks

proc updateShip(self: var GameMap, ship: ptr Ship) =
  var velocity = self.getShipVelocity(ship)

  var blocksIds = 0..ship.blocks.len()-1
  if velocity.x != 0:
    ship.blocks = ship.blocks.sortedByIt(it.x)
    if velocity.x > 0:
      blocksIds = ship.blocks.len()-1..0
  elif velocity.y != 0:
    ship.blocks = ship.blocks.sortedByIt(it.y)
    if velocity.y > 0:
      blocksIds = ship.blocks.len()-1..0
  else: return #No movement

  for index in countupordown(blocksIds.a, blocksIds.b):
    let
      b = ship.blocks[index]
      currentPos = b + ship.origin
    var
      newPos = currentPos + velocity
      newPosId = self.getBlockIndex(newPos.x, newPos.y)

    while self.isBlockInShip(ship, newPos) == false and self.data[newPosId].blockType != bNone:
      velocity.x -= int16(sgn(velocity.x))
      velocity.y -= int16(sgn(velocity.y))
      newPos = currentPos + velocity
      newPosId = self.getBlockIndex(newPos.x, newPos.y)

  for index in countupordown(blocksIds.a, blocksIds.b):
    let
      b = ship.blocks[index]
      currentPos = b + ship.origin
      newPos = currentPos + velocity
      newPosId = self.getBlockIndex(newPos.x, newPos.y)

    if self.data[newPosId].blockType == bNone:
      let oldPosId = self.getBlockIndex(currentPos.x, currentPos.y)
      self.data[newPosId] = self.data[oldPosId]
      self.data[oldPosId] = GameBlock()
  ship.origin += velocity

proc createShip*(self: var GameMap, blockId: int) =
  var ship = Ship(origin: self.getBlockLocation(blockId))
  for b in self.neighbors(blockId, proc (s: GameMap, x: int): bool = s.data[x].blockType != bNone):
    let
      newBlockLoc = self.getBlockLocation(b)
      relativeLoc = newBlockLoc - ship.origin
    ship.blocks.add(relativeLoc)
  self.ships.add(ship)

func updateBlock(self: var GameMap, x: int, y: int) =
  let blockIndex = self.getBlockIndex(x, y)
  var me = addr self.data[blockIndex]
  case me.blockType:
  of bTurret: discard
  else: discard

proc update*(self: var GameMap) =
  for y in 0..<self.height:
    for x in 0..<self.width:
      self.updateBlock(x, y)
  for i in 0..<self.ships.len():
    self.updateShip(addr self.ships[i])
