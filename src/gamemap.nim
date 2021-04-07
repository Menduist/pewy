import sequtils

type GameMap* = object
  width*, height*: int
  data*: seq[int16]

proc createGameMap*(width: int, height: int): GameMap =
  result.width = width
  result.height = height
  result.data = newSeqWith[int16](width * height, 0i16)

func getBlockIndex*(self: GameMap, x: int, y: int): int {.inline.} =
  x + y * self.width
