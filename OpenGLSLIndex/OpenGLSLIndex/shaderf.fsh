varying lowp vec4 varyColor;
varying lowp vec2 varyTextCoord;
uniform sampler2D colorMap;

void main()
{
    gl_FragColor = varyColor *texture2D(colorMap, varyTextCoord);
}
