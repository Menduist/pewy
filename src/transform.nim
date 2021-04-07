import glm

type Transform* = object
  position*: Vec2[float32]
  rotation*: float32
  scale*: float32

proc toMatrix*(self: Transform): Mat4[float32] =
  result = mat4f(1f)
  result = result.translate(vec3(self.position, 0))

  result = result.translate(vec3(0.5f * self.scale, 0.5f * self.scale, 0f))
  result = result.rotate(radians(self.rotation), vec3(0f, 0f, 1f))
  result = result.translate(vec3(-0.5f * self.scale, -0.5f * self.scale, 0f))

  result = result.scale(self.scale)
