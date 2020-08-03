attribute vec4 position;
attribute vec4 positionColor;
attribute vec2 textCoordinate;
varying lowp vec4 varyColor;
varying lowp vec2 varyTextCoord;
uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

void main(){
    varyColor = positionColor;
    varyTextCoord = textCoordinate;
    gl_Position = projectionMatrix * modelViewMatrix * position;
}

