import
  nimgl/[glfw, opengl],
  glm,
  transform,
  gamemap,
  renderer,
  math

type Pewy* = object
  window: GLFWWindow
  render*: PRenderer
  map: GameMap

var
  pewy: Pewy
  blockSelection = 1

when defined(emscripten):
  import jsbind/emscripten

  template mainLoop*(statement, actions: untyped): untyped =
    proc emscLoop{.cdecl.} =
      if statement:
        emscripten_cancel_main_loop()
        system.quit()
      else:
        actions
  
    emscripten_set_main_loop(emscLoop, 0 ,1)
else:
  template mainLoop*(statement, actions: untyped): untyped =
    while not statement:
      actions


## HANDLERS
proc keyProc(window: GLFWWindow, key: int32, scancode: int32,
             action: int32, mods: int32): void {.cdecl.} =
  if action == GLFWPress:
    case key:
    of GLFWKey.ESCAPE:
      window.setWindowShouldClose(true)
    of GLFWKey.Period:
      blockSelection += 1
      if blockSelection > 5:
        blockSelection = 1
    else: discard


proc updateWindowSize(window: GLFWWindow, width: int32, height: int32): void {.cdecl.} =
  pewy.render.setWindowSize(width, height)

## MAIN
proc main() =
  pewy.window = createWindow()
  if pewy.window == nil:
    quit(-1)

  discard pewy.window.setKeyCallback(keyProc)
  discard pewy.window.setFramebufferSizeCallback(updateWindowSize)

  pewy.render = createRenderer()
  pewy.render.setWindowSize(800, 600)
  pewy.map = createGameMap(100, 50)

  mainLoop pewy.window.windowShouldClose:
    glfwPollEvents()
    pewy.render.renderGameMap(pewy.map)

    var posX, posY: float64
    pewy.window.getCursorPos(addr posX, addr posY)

    let worldCursorPosition = pewy.render.screenToWorld(vec2(posX, posY))
    let transf = Transform(position: vec2[float32](trunc(worldCursorPosition.x), trunc(worldCursorPosition.y)),
                           scale: 1, rotation: 0f)

    let cursorBlockPosition = pewy.map.getBlockIndex(int transf.position.x, int transf.position.y)
    if cursorBlockPosition >= 0 and cursorBlockPosition < pewy.map.data.len:
      if pewy.window.getMouseButton(GLFWMouseButton.Button1) > 0:
          pewy.map.data[cursorBlockPosition] = int16(blockSelection)
      if pewy.window.getMouseButton(GLFWMouseButton.Button2) > 0:
        pewy.map.data[cursorBlockPosition] = 0

      pewy.render.setColor(vec4(1f, 1f, 1f, 0.5f))
      glEnable(GL_BLEND)
      pewy.render.renderTile(transf, blockSelection)
      glDisable(GL_BLEND)
      pewy.render.setColor()

    pewy.window.swapBuffers()

  pewy.window.destroyWindow()
  glfwTerminate()

when isMainModule:
  main()
