import
  sequtils,
  glm

type GameBlock* {.packed.} = object
  blockTile *{.bitsize: 6.}: uint8
  blockOrientation *{.bitsize: 2.}: uint8
  blockType *{.bitsize: 3.}: uint8

type GameMap* = object
  width*, height*: int
  data*: seq[GameBlock]

proc createGameMap*(width: int, height: int): GameMap =
  result.width = width
  result.height = height
  result.data = newSeqWith[GameBlock](width * height, GameBlock())

func getBlockIndex*(self: GameMap, x: int, y: int): int {.inline.} =
  x + y * self.width

proc setBlockValue*(self: var GameMap, blockId: int, newType: int16, orientation = 0) =
  self.data[blockId].blockTile = uint8(newType)
  self.data[blockId].blockOrientation = uint8(orientation)

proc setBlockValue*(self: var GameMap, x: int, y: int, newType: int16, orientation = 0) =
  let blockId = self.getBlockIndex(x, y)
  self.setBlockValue(blockId, newType, orientation)

func getBlockLocation*(self: GameMap, blockId: int): Vec2[float32] =
  vec2(float32(blockId %% self.width), float32(blockId div self.width))
