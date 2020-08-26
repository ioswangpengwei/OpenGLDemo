//
//  MyRender.m
//  002-BasicTextureSelf
//
//  Created by MacW on 2020/8/25.
//  Copyright © 2020 MacW. All rights reserved.
//

#import "MyRender.h"
#import "BasicTeture.h"
@implementation MyRender
{
    MTKView *mkView;
    id <MTLDevice>_device;
    id <MTLRenderPipelineState>_pipelineState;
    id <MTLCommandQueue>_commandQueue;
    vector_uint2 _viewportSize;
    id<MTLBuffer> _vertices;
    NSUInteger _numVertices;
    id <MTLTexture> _texture;

}
-(instancetype)initWithView:(MTKView *)view {
    if (self = [super init]) {
        _device = view.device;
        mkView = view;
        [self setupVertex];
        [self setupPipeLine];
        [self setupTexturePNG];
        _commandQueue = [_device newCommandQueue];
    }
    return self;
}
-(void)setupVertex {
    static const CCVertex quadVertices[] = {
          //像素坐标,纹理坐标
          { {  250,  -250 },  { 1.f, 0.f } },
          { { -250,  -250 },  { 0.f, 0.f } },
          { { -250,   250 },  { 0.f, 1.f } },
          
          { {  250,  -250 },  { 1.f, 0.f } },
          { { -250,   250 },  { 0.f, 1.f } },
          { {  250,   250 },  { 1.f, 1.f } },
          
      };
    
    _vertices = [_device newBufferWithBytes:quadVertices length:sizeof(quadVertices) options:MTLResourceStorageModeShared];
    _numVertices = sizeof(quadVertices)/sizeof(CCVertex);
    
}
-(void)setupPipeLine {
    
    id <MTLLibrary>_library = [_device newDefaultLibrary];
    id <MTLFunction>vertexFunction = [_library newFunctionWithName:@"vertexShader"];
    id <MTLFunction>fragmentFunction = [_library newFunctionWithName:@"fragmentShader"];
    
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.label = @"MTLRenderPipelineDescriptor";
    renderPipelineDescriptor.vertexFunction = vertexFunction;
    renderPipelineDescriptor.fragmentFunction = fragmentFunction;
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = mkView.colorPixelFormat;
    NSError *error;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error];
    
}
-(void)setupTexturePNG {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"2" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    NSUInteger widht = (NSUInteger) image.size.width;
    NSUInteger height = (NSUInteger)image.size.height;
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:widht height:height mipmapped:NO];
    if (textureDescriptor) {
        _texture = [_device newTextureWithDescriptor:textureDescriptor];
        Byte *imageBytes = [self loadImage:image];
           
           //6.UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
        MTLRegion region = {{ 0, 0, 0 }, {image.size.width, image.size.height, 1}};

           if (imageBytes) {
               [_texture replaceRegion:region
                               mipmapLevel:0
                                 withBytes:imageBytes
                               bytesPerRow:4 * image.size.width];
               free(imageBytes);
               imageBytes = NULL;
           }
    }
    
    
    
}

-(Byte *)loadImage:(UIImage *)image {
     CGImageRef spriteImage = image.CGImage;
     
     // 2.读取图片的大小
     size_t width = CGImageGetWidth(spriteImage);
     size_t height = CGImageGetHeight(spriteImage);
    
     //3.计算图片大小.rgba共4个byte
     Byte * spriteData = (Byte *) calloc(width * height * 4, sizeof(Byte));
     
     //4.创建画布
     CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
     
     //5.在CGContextRef上绘图
     CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
     
     //6.图片翻转过来
     CGRect rect = CGRectMake(0, 0, width, height);
     CGContextTranslateCTM(spriteContext, rect.origin.x, rect.origin.y);
     CGContextTranslateCTM(spriteContext, 0, rect.size.height);
     CGContextScaleCTM(spriteContext, 1.0, -1.0);
     CGContextTranslateCTM(spriteContext, -rect.origin.x, -rect.origin.y);
     CGContextDrawImage(spriteContext, rect, spriteImage);
     
     //7.释放spriteContext
     CGContextRelease(spriteContext);
     
     return spriteData;
}

-(void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
    
}

-(void)drawInMTKView:(MTKView *)view {
    //1.为当前渲染的每个渲染传递创建一个新的命令缓冲区
     id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
     //指定缓存区名称
     commandBuffer.label = @"MyCommand";
     
     //2.currentRenderPassDescriptor描述符包含currentDrawable's的纹理、视图的深度、模板和sample缓冲区和清晰的值。
     MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
     if(renderPassDescriptor != nil)
     {
         //3.创建渲染命令编码器,这样我们才可以渲染到something
         id<MTLRenderCommandEncoder> renderEncoder =
         [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
         //渲染器名称
         renderEncoder.label = @"MyRenderEncoder";
         
         //4.设置我们绘制的可绘制区域
         /*
          typedef struct {
          double originX, originY, width, height, znear, zfar;
          } MTLViewport;
          */
         [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];
         
         //5.设置渲染管道
         [renderEncoder setRenderPipelineState:_pipelineState];
         
         //6.加载数据
         //将数据加载到MTLBuffer --> 顶点函数
         [renderEncoder setVertexBuffer:_vertices
                                 offset:0
                                atIndex:CCVertexInputIndexVertices];
         //将数据加载到MTLBuffer --> 顶点函数
         [renderEncoder setVertexBytes:&_viewportSize
                                length:sizeof(_viewportSize)
                               atIndex:CCVertexInputIndexViewportSize];
         
         //7.设置纹理对象
         [renderEncoder setFragmentTexture:_texture atIndex:CCTextureIndexBaseColor];
         
         //8.绘制
         // @method drawPrimitives:vertexStart:vertexCount:
         //@brief 在不使用索引列表的情况下,绘制图元
         //@param 绘制图形组装的基元类型
         //@param 从哪个位置数据开始绘制,一般为0
         //@param 每个图元的顶点个数,绘制的图型顶点数量
         /*
          MTLPrimitiveTypePoint = 0, 点
          MTLPrimitiveTypeLine = 1, 线段
          MTLPrimitiveTypeLineStrip = 2, 线环
          MTLPrimitiveTypeTriangle = 3,  三角形
          MTLPrimitiveTypeTriangleStrip = 4, 三角型扇
          */
         [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                           vertexStart:0
                           vertexCount:_numVertices];
         
         //9.表示已该编码器生成的命令都已完成,并且从NTLCommandBuffer中分离
         [renderEncoder endEncoding];
         
         //10.一旦框架缓冲区完成，使用当前可绘制的进度表
         [commandBuffer presentDrawable:view.currentDrawable];
     }
     
     //11.最后,在这里完成渲染并将命令缓冲区推送到GPU
     [commandBuffer commit];
}
@end
