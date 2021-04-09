import
  sequtils,
  glm, sets

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

proc updateShip(self: var GameMap, ship: ptr Ship) =
  let velocity = self.getShipVelocity(ship)
  if velocity.x == 0 and velocity.y == 0: return

  var
    movedBlocks: HashSet[int16]

  #TODO is algorithm is really dumb (not taking collision in account, bad perf, etc..)
  while movedBlocks.len() != ship.blocks.len():
    for index, b in ship.blocks:
      if int16(index) in movedBlocks: continue
      let
        currentPos = b + ship.origin
        newPos = currentPos + velocity
        newPosId = self.getBlockIndex(newPos.x, newPos.y)

      if self.data[newPosId].blockType == bNone:
        let oldPosId = self.getBlockIndex(currentPos.x, currentPos.y)
        self.data[newPosId] = self.data[oldPosId]
        self.data[oldPosId].blockType = bNone
        self.data[oldPosId].blockTile = 0
        movedBlocks.incl(int16(index))
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

func update*(self: var GameMap) =
  for y in 0..<self.height:
    for x in 0..<self.width:
      self.updateBlock(x, y)
  for i in 0..<self.ships.len():
    self.updateShip(addr self.ships[i])
