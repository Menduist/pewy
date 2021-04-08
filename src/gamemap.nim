import
  sequtils,
  glm

type GameMap* = object
  width*, height*: int
  data*: seq[int16]

proc createGameMap*(width: int, height: int): GameMap =
  result.width = width
  result.height = height
  result.data = newSeqWith[int16](width * height, 0i16)

func getBlockIndex*(self: GameMap, x: int, y: int): int {.inline.} =
  x + y * self.width

proc setBlockValue*(self: var GameMap, blockId: int, newType: int16) =
  self.data[blockId] = newType

proc setBlockValue*(self: var GameMap, x: int, y: int, newType: int16) =
  let blockId = self.getBlockIndex(x, y)
  self.setBlockValue(blockId, newType)

func getBlockLocation*(self: GameMap, blockId: int): Vec2[float32] =
  vec2(float32(blockId %% self.width), float32(blockId div self.width))
