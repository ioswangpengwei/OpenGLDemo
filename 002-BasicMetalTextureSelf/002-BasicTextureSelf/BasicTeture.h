//
//  BasicTeture.h
//  002-BasicTextureSelf
//
//  Created by MacW on 2020/8/25.
//  Copyright © 2020 MacW. All rights reserved.
//

#ifndef BasicTeture_h
#define BasicTeture_h
#include <simd/simd.h>

typedef enum CCVertexInputIndex
{
    //顶点
    CCVertexInputIndexVertices     = 0,
    //视图大小
    CCVertexInputIndexViewportSize = 1,
} CCVertexInputIndex;

//纹理索引
typedef enum CCTextureIndex
{
    CCTextureIndexBaseColor = 0
}CCTextureIndex;

//结构体: 顶点/颜色值
typedef struct
{
    // 像素空间的位置
    // 像素中心点(100,100)
    vector_float2 position;
    // 2D 纹理
    vector_float2 textureCoordinate;
} CCVertex;


#endif /* BasicTeture_h */
