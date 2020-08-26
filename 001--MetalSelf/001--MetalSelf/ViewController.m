//
//  ViewController.m
//  001--MetalSelf
//
//  Created by MacW on 2020/8/25.
//  Copyright © 2020 MacW. All rights reserved.
//

#import "ViewController.h"
#import <MetalKit/MetalKit.h>
#import "MyRender.h"
@interface ViewController ()
{
    MTKView *_mtkView;
    MyRender *_render;
    
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _mtkView = [[MTKView alloc] initWithFrame:self.view.bounds device:MTLCreateSystemDefaultDevice()];
    _render = [[MyRender alloc] initWithMetalView:_mtkView];
    _mtkView.delegate = _render;
    [self.view addSubview:_mtkView];
    [_render mtkView:_mtkView drawableSizeWillChange:_mtkView.drawableSize];
}


@end
