//
//  MetalSelf.h
//  001--MetalSelf
//
//  Created by MacW on 2020/8/25.
//  Copyright © 2020 MacW. All rights reserved.
//

#ifndef MetalSelf_h
#define MetalSelf_h
#include <simd/simd.h>

typedef enum CCVertexInputIndex
{
    //顶点
    CCVertexInputIndexVertices     = 0,
    //视图大小
    CCVertexInputIndexViewportSize = 1,
} CCVertexInputIndex;

//结构体: 顶点/颜色值
typedef struct
{
    // 像素空间的位置
    // 像素中心点(100,100)
    //float float
    vector_float2 position;
    // RGBA颜色
    //float float float float
    vector_float4 color;
} CCVertex;

#endif /* MetalSelf_h */
