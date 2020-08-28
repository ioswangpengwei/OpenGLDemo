//
//  ViewController.m
//  MetalCamera
//
//  Created by MacW on 2020/8/28.
//  Copyright © 2020 MacW. All rights reserved.
//

#import "ViewController.h"
@import AVFoundation;
@import MetalKit;
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
@interface ViewController ()<MTKViewDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) MTKView *mMTKView;


@property (nonatomic, strong) id<MTLCommandQueue>  commandQueue;

//纹理缓存区
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;

@property (nonatomic, strong) id <MTLTexture>  texture;


@property (nonatomic, strong) AVCaptureSession *myCaptureSession;

@property (nonatomic, strong) AVCaptureDeviceInput *myCaptureDeviceInput;

@property (nonatomic, strong)  dispatch_queue_t myProcessQueue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setUpMetal];
    
    [self setupCaptureSession];
    
}
-(void)setUpMetal {
    MTKView *view = [[MTKView alloc] initWithFrame:self.view.bounds device:MTLCreateSystemDefaultDevice()];
    [self.view insertSubview:view atIndex:0];
    self.mMTKView = view;
    view.delegate = self;
    self.mMTKView.framebufferOnly = NO;

    self.commandQueue = [self.mMTKView.device newCommandQueue];
    CVMetalTextureCacheCreate(NULL, NULL, self.mMTKView.device, NULL, &_textureCache);
    
}
-(void)setupCaptureSession {
    self.myCaptureSession = [[AVCaptureSession alloc] init];
    NSArray<AVCaptureDevice *> *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *inputCamera = nil;
    for (AVCaptureDevice *captureDevice in devices) {
        if (captureDevice.position == AVCaptureDevicePositionBack) {
            inputCamera = captureDevice;
        }
    }
    self.myCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:nil];
    if ([self.myCaptureSession canAddInput:self.myCaptureDeviceInput]) {
        [self.myCaptureSession addInput:self.myCaptureDeviceInput];
    }
    AVCaptureVideoDataOutput *videoDataOutPut = [[AVCaptureVideoDataOutput alloc] init];
    self.myProcessQueue = dispatch_queue_create("myProcessqueue", DISPATCH_QUEUE_SERIAL);
    [videoDataOutPut setSampleBufferDelegate:self queue:self.myProcessQueue];
    [videoDataOutPut setAlwaysDiscardsLateVideoFrames:NO];
    [videoDataOutPut setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    if ([self.myCaptureSession canAddOutput:videoDataOutPut]) {
        [self.myCaptureSession addOutput:videoDataOutPut];
    }
    AVCaptureConnection *connection = [videoDataOutPut connectionWithMediaType:AVMediaTypeVideo];
    
    //9.设置视频方向
    //注意: 一定要设置视频方向.否则视频会是朝向异常的.
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    //10.开始捕捉
    [self.myCaptureSession startRunning];
    
    
}
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef pixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    size_t width =  CVPixelBufferGetWidth(pixelBufferRef);
    size_t height = CVPixelBufferGetHeight(pixelBufferRef);
    CVMetalTextureRef tmpTexture = NULL;
 CVReturn status =   CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, pixelBufferRef, NULL, MTLPixelFormatRGBA8Unorm, width, height, 0, &tmpTexture);
    if(status == kCVReturnSuccess)
      {
          //5.设置可绘制纹理的当前大小。
          self.mMTKView.drawableSize = CGSizeMake(width, height);
          //6.返回纹理缓冲区的Metal纹理对象。
          self.texture = CVMetalTextureGetTexture(tmpTexture);
          //7.使用完毕,则释放tmpTexture
          CFRelease(tmpTexture);
      }
    
}
-(void)drawInMTKView:(MTKView *)view {
    //1.判断是否获取了AVFoundation 采集的纹理数据
       if (self.texture) {
           
           //2.创建指令缓冲
           id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
           
           //3.将MTKView 作为目标渲染纹理
           id<MTLTexture> drawingTexture = view.currentDrawable.texture;
           
           //4.设置滤镜
           /*
            MetalPerformanceShaders是Metal的一个集成库，有一些滤镜处理的Metal实现;
            MPSImageGaussianBlur 高斯模糊处理;
            */
          
           //创建高斯滤镜处理filter
           //注意:sigma值可以修改，sigma值越高图像越模糊;
           MPSImageGaussianBlur *filter = [[MPSImageGaussianBlur alloc] initWithDevice:self.mMTKView.device sigma:1];
           
           //5.MPSImageGaussianBlur以一个Metal纹理作为输入，以一个Metal纹理作为输出；
           //输入:摄像头采集的图像 self.texture
           //输出:创建的纹理 drawingTexture(其实就是view.currentDrawable.texture)
           [filter encodeToCommandBuffer:commandBuffer sourceTexture:self.texture destinationTexture:drawingTexture];
           
           //6.展示显示的内容
           [commandBuffer presentDrawable:view.currentDrawable];
           
           //7.提交命令
           [commandBuffer commit];
           
           //8.清空当前纹理,准备下一次的纹理数据读取.
           self.texture = NULL;
       }
}

-(void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}
@end
