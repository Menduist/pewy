import
  nimgl/opengl, nimPNG

type
  PTexture* = object
    glId*: GLuint


proc loadTextureFromPng*(path: string): PTexture =
  result = PTexture()
  const pngData = staticRead"../assets/tileset.png"

  var pngImage = decodePNG32(pngData)

  glGenTextures(1, result.glId.addr)
  glBindTexture(GL_TEXTURE_2D, result.glId)

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8.ord, GLsizei(pngImage.width),
               GLsizei(pngImage.height), 0, GL_RGBA, GL_UNSIGNED_BYTE,
               cast[pointer](addr pngImage.data[0]))

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.ord)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.ord)
