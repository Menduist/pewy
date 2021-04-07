import nimgl/opengl

type
  PShader* = object
    glId*: GLuint

proc statusShader(shader: uint32) =
  var status: int32
  glGetShaderiv(shader, GL_COMPILE_STATUS, status.addr);
  if status != GL_TRUE.ord:
    var
      logLength: int32
      message = newSeq[char](1024)
    glGetShaderInfoLog(shader, 1024, logLength.addr, message[0].addr);
    echo cast[string](message)

proc createPixelShader*(): PShader =
  var src: cstring = """
#version 100
precision mediump float;

varying vec2 TexCoords;
//out vec4 color;

uniform sampler2D image;
uniform vec4 spriteColor;

void main()
{    
  gl_FragColor = spriteColor * texture2D(image, TexCoords);
  if (texture2D(image, TexCoords).a < 0.5)
    discard;
} 
"""
  result.glId = glCreateShader(GL_FRAGMENT_SHADER)
  glShaderSource(result.glId, 1'i32, src.addr, nil)
  glCompileShader(result.glId)
  statusShader(result.glId)

proc createVertexShader*(): PShader =
  var src: cstring = """
#version 100
attribute vec4 vertex; // <vec2 position, vec2 texCoords>

varying vec2 TexCoords;

uniform mat4 model;
uniform mat4 projection;

uniform vec4 tiler;

void main()
{
    TexCoords = (vertex.zw + tiler.zw) * tiler.xy;
    gl_Position = projection * model * vec4(vertex.xy, 0.0, 1.0);
}
"""
  result.glId = glCreateShader(GL_VERTEX_SHADER)
  glShaderSource(result.glId, 1'i32, src.addr, nil)
  glCompileShader(result.glId)
  statusShader(result.glId)
