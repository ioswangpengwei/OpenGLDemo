//
//  BasicTexture.metal
//  002-BasicTextureSelf
//
//  Created by MacW on 2020/8/25.
//  Copyright © 2020 MacW. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#import "BasicTeture.h"
typedef struct
{
    
    float4 clipSpacePosition [[position]];
    float2 textureCoordinate;
    
} RasterizerData;

vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
                                   constant CCVertex*vertexs [[buffer(CCVertexInputIndexVertices)]],
                                   constant vector_uint2 *viewportSizePointer [[buffer(CCVertexInputIndexViewportSize)]]
                                   )

{
    RasterizerData out;
    out.clipSpacePosition = vector_float4(0.0,0.0,1.0,1.0);
     float2 pixelSpacePosition = vertexs[vertexID].position.xy;
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);

    out.textureCoordinate = vertexs[vertexID].textureCoordinate;
    
    return out;
}
fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               texture2d<float> colorTexture [[texture(CCTextureIndexBaseColor)]]
                               ){
    constexpr sampler textureSampler(mag_filter::linear,
    min_filter::linear);
    const float4 colorSampler = colorTexture.sample(textureSampler, in.textureCoordinate);
    return colorSampler;
    
}
