//
//  MyRender.m
//  001--MetalSelf
//
//  Created by MacW on 2020/8/25.
//  Copyright © 2020 MacW. All rights reserved.
//

#import "MyRender.h"
#import "MetalSelf.h"
@implementation MyRender
{
    id<MTLDevice>_device;
    vector_uint2 _viewSize;
    id<MTLRenderPipelineState> _renderPipelinesState;
    id <MTLBuffer> _vertexBuffer;
    //顶点个数
       NSInteger _numVertices;
    id<MTLCommandQueue>_commandQueue;
}

- (instancetype)initWithMetalView:(MTKView *)view {
    if (self = [super init]) {
        
        _device = view.device;
        
        [self loadMetal:view];
    }
    return self;
}
- (void)loadMetal:(nonnull MTKView *)mtkView {
    mtkView.colorPixelFormat =  MTLPixelFormatBGRA8Unorm_sRGB;
    
    id <MTLLibrary> library = [_device newDefaultLibrary];
    id<MTLFunction> vertexShaderFunction  = [library newFunctionWithName:@"vertexShader"];
    id <MTLFunction>fragmentShaderFunction = [library newFunctionWithName:@"fragmentShader"];
    
    
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    renderPipelineDescriptor.label = @"renderPipelineDescriptor";
    renderPipelineDescriptor.vertexFunction = vertexShaderFunction;
    renderPipelineDescriptor.fragmentFunction = fragmentShaderFunction;
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;

    NSError *error;
    _renderPipelinesState = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error];
    if (error) {
        NSAssert(NO, @"renderPipelinesState创建失败");
        return;
    }
    NSData *vertexData = [MyRender generateVertexData];
    _vertexBuffer = [_device newBufferWithLength:vertexData.length options:MTLResourceStorageModeShared];
    memcpy(_vertexBuffer.contents, vertexData.bytes, vertexData.length);
    //计算顶点个数 = 顶点数据长度 / 单个顶点大小
      _numVertices = vertexData.length / sizeof(CCVertex);
    _commandQueue = [_device newCommandQueue];
    
}
//顶点数据
+ (nonnull NSData *)generateVertexData
{
    //1.正方形 = 三角形+三角形
    const CCVertex quadVertices[] =
    {
        // Pixel 位置, RGBA 颜色
        { { -20,   20 },    { 1, 0, 0, 1 } },
        { {  20,   20 },    { 1, 0, 0, 1 } },
        { { -20,  -20 },    { 1, 0, 0, 1 } },
        
        { {  20,  -20 },    { 0, 0, 1, 1 } },
        { { -20,  -20 },    { 0, 0, 1, 1 } },
        { {  20,   20 },    { 0, 0, 1, 1 } },
    };
    //行/列 数量
    const NSUInteger NUM_COLUMNS = 25;
    const NSUInteger NUM_ROWS = 15;
    //顶点个数
    const NSUInteger NUM_VERTICES_PER_QUAD = sizeof(quadVertices) / sizeof(CCVertex);
    //四边形间距
    const float QUAD_SPACING = 50.0;
    //数据大小 = 单个四边形大小 * 行 * 列
    NSUInteger dataSize = sizeof(quadVertices) * NUM_COLUMNS * NUM_ROWS;
    
    //2. 开辟空间
    NSMutableData *vertexData = [[NSMutableData alloc] initWithLength:dataSize];
    //当前四边形
    CCVertex * currentQuad = vertexData.mutableBytes;
    
    
    //3.获取顶点坐标(循环计算)
    //行
    for(NSUInteger row = 0; row < NUM_ROWS; row++)
    {
        //列
        for(NSUInteger column = 0; column < NUM_COLUMNS; column++)
        {
            //A.左上角的位置
            vector_float2 upperLeftPosition;
            
            //B.计算X,Y 位置.注意坐标系基于2D笛卡尔坐标系,中心点(0,0),所以会出现负数位置
            upperLeftPosition.x = ((-((float)NUM_COLUMNS) / 2.0) + column) * QUAD_SPACING + QUAD_SPACING/2.0;
            
            upperLeftPosition.y = ((-((float)NUM_ROWS) / 2.0) + row) * QUAD_SPACING + QUAD_SPACING/2.0;
            
            //C.将quadVertices数据复制到currentQuad
            memcpy(currentQuad, &quadVertices, sizeof(quadVertices));
            
            //D.遍历currentQuad中的数据
            for (NSUInteger vertexInQuad = 0; vertexInQuad < NUM_VERTICES_PER_QUAD; vertexInQuad++)
            {
                //修改vertexInQuad中的position
                currentQuad[vertexInQuad].position += upperLeftPosition;
            }
            
            //E.更新索引
            currentQuad += 6;
        }
    }
    
    return vertexData;
    
}

-(void)drawInMTKView:(MTKView *)view {
    id<MTLCommandBuffer>commandBuffer = [_commandQueue commandBuffer];

    id<MTLRenderCommandEncoder> renderCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:view.currentRenderPassDescriptor];
    if (renderCommandEncoder) {
        [renderCommandEncoder setViewport:(MTLViewport){0,0,_viewSize.x,_viewSize.y,-1.0,1.0}];
        [renderCommandEncoder setRenderPipelineState:_renderPipelinesState];
        [renderCommandEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:CCVertexInputIndexVertices];
        [renderCommandEncoder setVertexBytes:&_viewSize length:sizeof(_viewSize) atIndex:CCVertexInputIndexViewportSize];
        [renderCommandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
        
        [renderCommandEncoder endEncoding];
        [commandBuffer presentDrawable:view.currentDrawable ];
    }
    [commandBuffer commit];
}

-(void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    _viewSize.x = size.width;
    _viewSize.y = size.height;
    
}
@end
