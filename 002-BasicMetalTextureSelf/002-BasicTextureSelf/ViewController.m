//
//  ViewController.m
//  002-BasicTextureSelf
//
//  Created by MacW on 2020/8/25.
//  Copyright © 2020 MacW. All rights reserved.
//

#import "ViewController.h"
@import MetalKit;
#import "MyRender.h"
@interface ViewController ()
{
    MyRender *_render;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    MTKView *mtkView = [[MTKView alloc] initWithFrame:self.view.bounds];
    mtkView.device = MTLCreateSystemDefaultDevice();
    [self.view addSubview:mtkView];
//    mtkView.colorPixelFormat = MTLPixelFormatRGBA8Snorm;
    _render = [[MyRender alloc] initWithView:mtkView];
    mtkView.delegate = _render;
    [_render mtkView:mtkView drawableSizeWillChange:mtkView.drawableSize];
    
}



@end
