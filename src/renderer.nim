import
  shader, texture,
  nimgl/[glfw, opengl],
  glm,
  transform,
  gamemap

## TYPES ----------------------------------

type PRenderer* = object
  glProgram: GLuint
  quadVAO: GLuint
  projectionUniform: GLint
  projectionMatrix*: Mat4[float32]
  modelUniform: GLint
  tilerUniform: GLint
  globalScale: float32
  spriteColorUniform: GLint
  tileTexture: PTexture

  windowHeight*: int

## SETTERS --------------------------------

proc setColor*(self: PRenderer, color = vec4(1f)) =
  var trueColor = color
  glUniform4fv(self.spriteColorUniform, 1, trueColor.caddr)

proc setWindowSize*(self: var PRenderer, width: int, height: int) =
  self.projectionMatrix = ortho(0.0f, float(width) / self.globalScale, 0.0f, float(height) / self.globalScale, -1.0f, 1.0f)
  glViewport(0, 0, GLsizei(width), GLsizei(height))
  glUniformMatrix4fv(self.projectionUniform, 1, false, self.projectionMatrix.caddr)

  let projScale = 1f / self.globalScale
  self.projectionMatrix = ortho(-projScale, projScale, -projScale, projScale, -1.0f, 1.0f)
  self.windowHeight = height

## RENDERERS ------------------------------

proc renderTile*(self: PRenderer, trans: Transform, tile: int = 0) =
  glUseProgram(self.glProgram)
  var model = trans.toMatrix()

  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, self.tileTexture.glId)

  glUniformMatrix4fv(self.modelUniform, 1, false, model.caddr)

  var tilerVec = vec4(0f)
  tilerVec.x = 1f / 8f
  tilerVec.y = -1f / 8f
  tilerVec.z = float(tile %% 8)
  tilerVec.w = float(tile div 8)

  glUniform4fv(self.tilerUniform, 1, tilerVec.caddr)

  glBindVertexArray(self.quadVAO)
  glDrawArrays(GL_TRIANGLES, 0, 6)

func screenToWorld*[T](self: PRenderer, screenPos: Vec2[T]): Vec2[T] =
  let matt = self.projectionMatrix.inverse
  let posV = vec4(float32(screenPos.x), float32(self.windowHeight - int(screenPos.y)), 0f, 0f) * matt
  return vec2(T(posV.x), T(posV.y))

proc renderGameMap*(self: PRenderer, map: GameMap) =
  glClear(GL_COLOR_BUFFER_BIT)

  var transf = Transform(scale: 1, rotation: 0f)
  for y in 0..<map.height:
    for x in 0..<map.width:
      let blockType = map.data[x + y * map.width]
      transf.position.x = float(x)
      transf.position.y = float(y)
      transf.rotation = float(blockType.blockOrientation) * 90f
      self.renderTile(transf, int(blockType.blockTile))

## INIT -----------------------------------

proc createWindow*(): GLFWWindow =
  assert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)

  result = glfwCreateWindow(800, 600, "Pewy")
  result.makeContextCurrent()

proc createProgram(self: var PRenderer) =
  let
    fgShader = createPixelShader()
    vxShader = createVertexShader()

  self.glProgram = glCreateProgram()
  glAttachShader(self.glProgram, vxShader.glId)
  glAttachShader(self.glProgram, fgShader.glId)
  glLinkProgram(self.glProgram)

  glUseProgram(self.glProgram)

proc createVbo(self: var PRenderer) =
  var vert = @[
    0.0f, 1.0f, 0.0f, 1.0f,
    1.0f, 0.0f, 1.0f, 0.0f,
    0.0f, 0.0f, 0.0f, 0.0f,

    0.0f, 1.0f, 0.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 0.0f, 1.0f, 0.0f
  ]
  glGenVertexArrays(1, addr self.quadVAO)
  var VBO: GLuint
  glGenBuffers(GLsizei(1), addr VBO)

  glBindBuffer(GL_ARRAY_BUFFER, VBO)
  glBufferData(GL_ARRAY_BUFFER, cint(cfloat.sizeof * vert.len), vert[0].addr, GL_STATIC_DRAW)

  glBindVertexArray(self.quadVAO)
  glEnableVertexAttribArray(0)
  glVertexAttribPointer(0, 4, EGL_FLOAT, false, GLsizei(4 * cfloat.sizeof), nil)
  glBindBuffer(GL_ARRAY_BUFFER, 0)
  glBindVertexArray(0)

proc createRenderer*(): PRenderer =
  assert glInit()
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

  result.createProgram()
  result.createVbo()

  result.spriteColorUniform = glGetUniformLocation(result.glProgram, "spriteColor")
  result.modelUniform = glGetUniformLocation(result.glProgram, "model")
  result.projectionUniform = glGetUniformLocation(result.glProgram, "projection")
  result.tilerUniform = glGetUniformLocation(result.glProgram, "tiler")

  let uImage = glGetUniformLocation(result.glProgram, "image")
  glUniform1i(uImage, 0)

  result.globalScale = 20
  result.tileTexture = loadTextureFromPng("")
  result.setColor()
  glClearColor(1f, 1f, 1f, 1f)
