import
  nimgl/[glfw, opengl],
  glm,
  transform,
  gamemap,
  renderer


# TODO Moving this to input.nim is causing some circular issues
# Try to do better
type PInput* = object
  blockSelection*: int
  orientation*: int
  startBlock*: int
  endBlock*: int

type Pewy* = object
  window*: GLFWWindow
  render*: PRenderer
  pinput*: PInput
  map*: GameMap

var
  gPewy*: Pewy

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
proc updateWindowSize(window: GLFWWindow, width: int32, height: int32): void {.cdecl.} =
  gPewy.render.setWindowSize(width, height)

import input

## MAIN
proc main() =
  gPewy.window = createWindow()
  if gPewy.window == nil:
    quit(-1)

  discard gPewy.window.setFramebufferSizeCallback(updateWindowSize)

  gPewy.render = createRenderer()
  gPewy.render.setWindowSize(800, 600)
  gPewy.map = createGameMap(100, 50)
  gPewy.pinput = createInput(gPewy.window)

  mainLoop gPewy.window.windowShouldClose:
    glfwPollEvents()

    gPewy.map.update()
    gPewy.updateInput()

    gPewy.render.renderGameMap(gPewy.map)

    if gPewy.pinput.endBlock >= 0:
      gPewy.render.setColor(vec4(1f, 1f, 1f, 0.5f))
      glEnable(GL_BLEND)
      for b in blocksInSelection(gPewy):
        let transf = Transform(position: vec2((float32)b.x, (float32)b.y),
                               scale: 1, rotation: float(gPewy.pinput.orientation * 90))
        gPewy.render.renderTile(transf, gPewy.pinput.blockSelection)
      glDisable(GL_BLEND)
      gPewy.render.setColor()

    gPewy.window.swapBuffers()

  gPewy.window.destroyWindow()
  glfwTerminate()

when isMainModule:
  main()
